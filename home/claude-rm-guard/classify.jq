# Walks a `shfmt --to-json` AST and emits one object per finding:
#   {"deny": reason}    the command deletes files irreversibly
#   {"script": body}    a nested shell script (`sh -c`, `eval`) to parse again
#   {"foreign": body}   a nested non-POSIX script (`nu -c`, `fish -c`)

def deny_rm:
  { deny: "Deleting files permanently is blocked. Use `gomi <paths>` instead: it moves them to the trash, and `gomi --restore` brings them back." };

# A word's literal text, or null when it depends on expansion ($var, $(...), globs are fine).
def word:
  if all(.Parts[];
    .Type == "Lit" or .Type == "SglQuoted"
    or (.Type == "DblQuoted" and all(.Parts[]?; .Type == "Lit")))
  then
    [.Parts[]
      | if .Type == "Lit" then .Value | gsub("\\\\(?<c>.)"; .c)
        elif .Type == "SglQuoted" then .Value
        else [.Parts[]?.Value] | join("")
        end]
    | join("")
  else null
  end;

def base: if . == null then null else split("/") | last end;

def is_opt: . != null and startswith("-") and . != "-";

# Drops leading options; options listed in $valued also drop their value.
def skip_opts($valued):
  if length == 0 then .
  elif .[0] == "--" then .[1:]
  elif .[0] | is_opt then
    .[0] as $o
    | (if any($valued[]; . == $o) then .[2:] else .[1:] end)
    | skip_opts($valued)
  else .
  end;

def skip_env:
  if length == 0 then .
  elif .[0] == "--" then .[1:]
  elif .[0] == "-u" or .[0] == "-C" then .[2:] | skip_env
  elif (.[0] | is_opt) or (.[0] != null and (.[0] | test("^[A-Za-z_][A-Za-z0-9_]*="))) then .[1:] | skip_env
  else .
  end;

def git_subcommand:
  if length == 0 then .
  elif .[0] == "-C" or .[0] == "-c" or .[0] == "--git-dir" or .[0] == "--work-tree" or .[0] == "--namespace" then .[2:] | git_subcommand
  elif .[0] | is_opt then .[1:] | git_subcommand
  else .
  end;

def shell_args($c; $stdin):
  if length == 0 then
    if $c then empty
    else { deny: "Running a shell that reads its script from stdin is blocked, since the script cannot be checked. Pass it with `-c` instead." }
    end
  elif .[0] == null then
    if $c then { deny: "A dynamically built `sh -c` script is blocked, since it cannot be checked." } else empty end
  elif .[0] == "--" then .[1:] | if length == 0 then shell_args($c; true) else shell_args($c; $stdin) end
  elif .[0] == "-o" or .[0] == "+o" or .[0] == "-O" or .[0] == "+O" then .[2:] | shell_args($c; $stdin)
  elif .[0] | startswith("--") then .[1:] | shell_args($c; $stdin)
  elif .[0] | test("^[-+][A-Za-z]+$") then
    .[0] as $o
    | .[1:]
    | shell_args($c or ($o | test("^-[A-Za-z]*c")); $stdin or ($o | test("^-[A-Za-z]*s")))
  elif $c then { script: .[0] }
  elif $stdin then { deny: "Running a shell that reads its script from stdin is blocked, since the script cannot be checked. Pass it with `-c` instead." }
  else empty
  end;

def check:
  if length == 0 or .[0] == null then empty
  else
    (.[0] | base) as $cmd
    | .[1:] as $args
    | if $cmd == "sudo" or $cmd == "doas" then
        $args | skip_opts(["-u", "-g", "-h", "-p", "-C", "-D", "-r", "-t", "-U", "-T"]) | check
      elif $cmd == "env" then
        if any($args[]; . != null and (startswith("-S") or startswith("--split-string"))) then
          { deny: "`env -S` is blocked, since the command it runs cannot be checked." }
        else $args | skip_env | check
        end
      elif $cmd == "command" then
        if any($args[]; . == "-v" or . == "-V") then empty else $args | skip_opts([]) | check end
      elif $cmd == "builtin" or $cmd == "exec" or $cmd == "nohup" or $cmd == "time" or $cmd == "noglob" or $cmd == "nocorrect" then
        $args | skip_opts([]) | check
      elif $cmd == "nice" then
        $args | skip_opts(["-n"]) | check
      elif $cmd == "timeout" then
        $args | skip_opts(["-s", "-k"]) | .[1:] | check
      elif $cmd == "xargs" then
        $args | skip_opts(["-I", "-J", "-L", "-P", "-R", "-S", "-a", "-d", "-E", "-n", "-s"]) | check
      elif $cmd == "rm" or $cmd == "unlink" or $cmd == "rmdir" or $cmd == "shred" or $cmd == "srm" then
        deny_rm
      elif $cmd == "find" then
        (if any($args[]; . == "-delete") then
          { deny: "`find -delete` is blocked. Use `find ... -print0 | xargs -0 gomi` instead." }
        else empty
        end),
        ($args
          | to_entries[]
          | select(.value == "-exec" or .value == "-execdir" or .value == "-ok" or .value == "-okdir")
          | .key as $i
          | $args[$i + 1:]
          | ((to_entries | map(select(.value == ";" or .value == "+")) | first | .key) // length) as $end
          | .[:$end]
          | check)
      elif $cmd == "git" then
        ($args | git_subcommand) as $sub
        | if ($sub[0] == "clean") and (any($sub[1:][]; . == "--dry-run" or (. != null and test("^-[A-Za-z]*n"))) | not) then
            { deny: "`git clean` is blocked. List the files with `git clean -n`, then `gomi` them." }
          else empty
          end
      elif $cmd == "sh" or $cmd == "bash" or $cmd == "zsh" or $cmd == "dash" or $cmd == "ksh" or $cmd == "mksh" then
        $args | shell_args(false; false)
      elif $cmd == "nu" or $cmd == "fish" then
        $args
        | to_entries[]
        | select(.value == "-c" or .value == "--commands" or .value == "--command")
        | $args[.key + 1]
        | if . == null then { deny: "A dynamically built `-c` script is blocked, since it cannot be checked." } else { foreign: . } end
      elif $cmd == "eval" then
        if any($args[]; . == null) then
          { deny: "A dynamically built `eval` is blocked, since it cannot be checked." }
        else { script: ($args | join(" ")) }
        end
      else empty
      end
  end;

.. | objects | select(.Type == "CallExpr") | [.Args[]? | word] | check
