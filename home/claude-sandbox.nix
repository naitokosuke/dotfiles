# Every `claude` session runs under a Seatbelt profile that denies file
# writes outside an allowlist, so a deletion that slips past the Bash hooks
# (e.g. `fs.rmSync` from a script) still cannot touch anything outside the
# working directory (issue #460). Seatbelt cannot block deletion alone:
# denying unlink also blocks the rename gomi relies on, so this layer limits
# where writes land rather than what they are. The profile is loaded straight
# into /usr/bin/sandbox-exec; the approach follows
# https://github.com/Warashi/cage.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.home.homeDirectory;

  ## What stays writable
  # Everything is allowed except file writes, which are limited to the
  # per-user temp dirs, Claude Code's own state, the login keychain, gomi's
  # trash and log, and toolchain caches that are safe to lose.
  writable = [
    "/private/tmp"
    "${home}/.claude"
    "${home}/.claude.json"
    "${home}/.claude.json.backup"
    "${home}/.claude.json.lock"
    "${home}/.claude.lock"
    "${home}/Library/Keychains"

    # gomi moves files into its trash and writes its log here
    "${home}/.gomi"
    "${home}/.local/share/gomi"

    # cclens writes its analysis store here, also when run from a session
    "${home}/.local/state/cclens"

    # Toolchain caches — losing them is harmless
    "${home}/.cache"
    "${home}/Library/Caches"
    "${home}/.npm"
    "${home}/Library/pnpm"
    "${home}/.bun"
    "${home}/.cargo"
  ];

  ## The profile
  # CWD, GIT_COMMON_DIR and MAIN_CHECKOUT_RE are only known at launch, so
  # they come in as parameters (`sandbox-exec -D`) instead of being spliced
  # into the profile. The regex rule admits gwq's sibling worktrees
  # (`<main checkout>---<branch>`) but not the main checkout itself, so a
  # session can create and use worktrees while the main checkout and other
  # repositories stay read-only.
  profile = pkgs.writeText "claude-sandbox.sb" ''
    (version 1)
    (import "system.sb")
    (allow default)
    (deny file-write*)
    (allow file-write* (regex #"^/private/var/folders/[^/]+/[^/]+/(C|T|0)($|/)"))
    (allow file-write* (literal "/dev/tty"))
    (allow file-write* (subpath (param "CWD")))
    (allow file-write* (subpath (param "GIT_COMMON_DIR")))
    (allow file-write* (regex (string-append "^" (param "MAIN_CHECKOUT_RE") "---[^/]+(/|$)")))
    ${lib.concatMapStrings (path: "(allow file-write* (subpath \"${path}\"))\n") writable}
  '';

  inherit (pkgs.llm-agents) claude-code;

  ## Wrapping claude
  # Resolves the parameters at launch — the git common dir, so commits from a
  # worktree reach the main checkout's .git, and the main checkout path,
  # regex-escaped for the sibling rule — and execs the real binary through
  # sandbox-exec, so its Bash commands, hooks and MCP servers all run inside.
  sandboxed = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [
      pkgs.git
      pkgs.sd
    ];
    # `$1` in the sd replacement is a capture group, not a shell variable
    excludeShellChecks = [ "SC2016" ];
    text = ''
      cwd=$(pwd -P)
      # Commits from a worktree write to the main checkout's .git
      if git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
        git_common_dir=$(cd "$git_common_dir" && pwd -P)
        main_checkout=$(dirname "$git_common_dir")
      else
        git_common_dir=$cwd
        main_checkout=$cwd
      fi
      main_checkout_re=$(printf '%s' "$main_checkout" | sd '([.\\+*?()|\[\]{}^$])' '\\$1')

      exec /usr/bin/sandbox-exec \
        -f ${profile} \
        -D CWD="$cwd" \
        -D GIT_COMMON_DIR="$git_common_dir" \
        -D MAIN_CHECKOUT_RE="$main_checkout_re" \
        ${lib.getExe claude-code} "$@"
    '';
  };
in
{
  ## The package
  # The wrapped package with only bin/claude replaced, so anything that
  # inspects it sees the package it wraps: home-manager reads `version` to
  # pick its plugin mechanism (#558). Its own wrapper (plugin dir, MCP
  # servers) sits on top, so it ends up inside the sandbox too.
  programs.claude-code.package = pkgs.symlinkJoin {
    inherit (claude-code) pname version meta;
    paths = [ claude-code ];
    postBuild = ''
      rm $out/bin/claude
      ln -s ${lib.getExe sandboxed} $out/bin/claude
    '';
  };
}
