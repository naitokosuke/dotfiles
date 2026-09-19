# Claude Code sandbox
#
# Every `claude` session runs under a Seatbelt profile that denies file
# writes outside an allowlist, so a deletion that slips past the Bash hooks
# (e.g. `fs.rmSync` from a script) still cannot touch anything outside the
# working directory (issue #460). The profile is loaded straight into
# /usr/bin/sandbox-exec; the approach follows https://github.com/Warashi/cage.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.home.homeDirectory;

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

    # Toolchain caches — losing them is harmless
    "${home}/.cache"
    "${home}/Library/Caches"
    "${home}/.npm"
    "${home}/Library/pnpm"
    "${home}/.bun"
    "${home}/.cargo"
    "${home}/.rustup"
  ];

  # CWD, GIT_COMMON_DIR and MAIN_CHECKOUT_RE are only known at launch, so
  # they come in as parameters (`sandbox-exec -D`) instead of being spliced
  # into the profile. The regex rule admits gwq's sibling worktrees
  # (`<main checkout>---<branch>`) but not the main checkout itself.
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
in
{
  programs.claude-code.package = pkgs.writeShellApplication {
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
        ${lib.getExe pkgs.llm-agents.claude-code} "$@"
    '';
  };
}
