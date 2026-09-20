# Commands are parsed with shfmt rather than matched with regexes, so
# `$(...)`, pipelines, wrappers such as `sudo` / `xargs` and nested `sh -c`
# scripts are all seen (issue #463). Anything that cannot be checked is
# blocked. The Seatbelt sandbox in ../claude-sandbox.nix covers what slips
# past (e.g. `fs.rmSync` inside a script).
{
  lib,
  pkgs,
  ...
}:

let
  rm-guard = pkgs.writeShellApplication {
    name = "claude-rm-guard";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.jq
      pkgs.shfmt
    ];
    text = ''
      # A JSON "deny" decision is shown as a blocked call rather than a hook
      # error. Exit code 2 is the fallback if that JSON cannot be produced.
      deny() {
        trap - ERR
        jq -n --arg reason "$1" '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
          }
        }' || {
          printf '%s\n' "$1" >&2
          exit 2
        }
        exit 0
      }

      # Any other non-zero exit is a non-blocking error, which would let the
      # command through
      set -E
      trap 'deny "The hook failed while checking the command, so it was blocked."' ERR

      check() {
        local script=$1 depth=$2 ast findings finding kind value
        if ((depth > 8)); then
          deny "Nested shell scripts are too deep to check."
        fi
        ast=$(shfmt -ln zsh --to-json <<<"$script" 2>/dev/null) ||
          ast=$(shfmt -ln bash --to-json <<<"$script" 2>/dev/null) ||
          deny "The command could not be parsed, so it cannot be checked for deletions."
        findings=$(jq -c -f ${./classify.jq} <<<"$ast") ||
          deny "The command could not be checked for deletions."
        while IFS= read -r finding; do
          [[ -n $finding ]] || continue
          kind=$(jq -r 'keys[0]' <<<"$finding")
          value=$(jq -r '.[]' <<<"$finding")
          case $kind in
            deny) deny "$value" ;;
            script) check "$value" $((depth + 1)) ;;
            foreign)
              if grep -Eq '(^|[^[:alnum:]_-])(rm|unlink|rmdir|shred)([^[:alnum:]_-]|$)' <<<"$value"; then
                deny "Deleting files permanently is blocked. Use \`gomi <paths>\` instead."
              fi
              ;;
          esac
        done <<<"$findings"
      }

      command=$(jq -r '.tool_input.command // empty') ||
        deny "The hook input could not be read."
      if [[ -n $command ]]; then
        check "$command" 0
      fi
    '';
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash|Monitor";
      hooks = [
        {
          type = "command";
          command = lib.getExe rm-guard;
          timeout = 10;
        }
      ];
    }
  ];
}
