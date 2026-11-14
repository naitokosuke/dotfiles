// PreToolUse hook for Claude Code: blocks shell commands that delete files
// irreversibly and points to `gomi` instead.
//
// The command is parsed with `shfmt --to-json` rather than matched with
// regexes, so `$(...)`, pipelines, wrappers such as `sudo` / `xargs` and
// nested `sh -c` scripts are all seen (#463). Anything that cannot be checked
// is blocked. Standard library only, so there is no lockfile to keep in step.

import { writeSync } from "node:fs";

const shfmt = process.env.SHFMT ?? "shfmt";

type Finding =
  | { deny: string } // the command deletes files irreversibly
  | { script: string } // a nested shell script (`sh -c`, `eval`) to parse again
  | { foreign: string }; // a nested non-POSIX script (`nu -c`, `fish -c`)

// A word's literal text, or null when it depends on expansion.
type Word = string | null;

interface Node {
  Type?: string;
  Value?: string;
  Parts?: Node[];
  Args?: Node[];
}

const denyRm: Finding = {
  deny: "Deleting files permanently is blocked. Use `gomi <paths>` instead: it moves them to the trash, and `gomi --restore` brings them back.",
};
const denyStdin: Finding = {
  deny: "Running a shell that reads its script from stdin is blocked, since the script cannot be checked. Pass it with `-c` instead.",
};

function word(node: Node): Word {
  const parts = node.Parts ?? [];
  const literal = parts.every(
    (part) =>
      part.Type === "Lit" ||
      part.Type === "SglQuoted" ||
      (part.Type === "DblQuoted" && (part.Parts ?? []).every((inner) => inner.Type === "Lit")),
  );
  if (!literal) return null;
  return parts
    .map((part) => {
      if (part.Type === "Lit") return (part.Value ?? "").replace(/\\(.)/g, "$1");
      if (part.Type === "SglQuoted") return part.Value ?? "";
      return (part.Parts ?? []).map((inner) => inner.Value ?? "").join("");
    })
    .join("");
}

const isOpt = (w: Word): w is string => w !== null && w.startsWith("-") && w !== "-";

// Drops leading options; options listed in `valued` also drop their value.
function skipOpts(words: Word[], valued: string[]): Word[] {
  let rest = words;
  while (rest.length > 0) {
    const first = rest[0];
    if (first === "--") return rest.slice(1);
    if (!isOpt(first)) return rest;
    rest = rest.slice(valued.includes(first) ? 2 : 1);
  }
  return rest;
}

function skipEnv(words: Word[]): Word[] {
  let rest = words;
  while (rest.length > 0) {
    const first = rest[0];
    if (first === "--") return rest.slice(1);
    if (first === "-u" || first === "-C") rest = rest.slice(2);
    else if (isOpt(first) || (first !== null && /^[A-Za-z_][A-Za-z0-9_]*=/.test(first))) rest = rest.slice(1);
    else return rest;
  }
  return rest;
}

function gitSubcommand(words: Word[]): Word[] {
  let rest = words;
  while (rest.length > 0) {
    const first = rest[0];
    if (first !== null && ["-C", "-c", "--git-dir", "--work-tree", "--namespace"].includes(first)) rest = rest.slice(2);
    else if (isOpt(first)) rest = rest.slice(1);
    else return rest;
  }
  return rest;
}

function shellArgs(words: Word[], c: boolean, stdin: boolean): Finding[] {
  let rest = words;
  for (;;) {
    if (rest.length === 0) return c ? [] : [denyStdin];
    const first = rest[0];
    if (first === null) {
      return c ? [{ deny: "A dynamically built `sh -c` script is blocked, since it cannot be checked." }] : [];
    }
    if (first === "--") {
      rest = rest.slice(1);
      if (rest.length === 0) stdin = true;
    } else if (["-o", "+o", "-O", "+O"].includes(first)) {
      rest = rest.slice(2);
    } else if (first.startsWith("--")) {
      rest = rest.slice(1);
    } else if (/^[-+][A-Za-z]+$/.test(first)) {
      c ||= /^-[A-Za-z]*c/.test(first);
      stdin ||= /^-[A-Za-z]*s/.test(first);
      rest = rest.slice(1);
    } else if (c) {
      return [{ script: first }];
    } else {
      return stdin ? [denyStdin] : [];
    }
  }
}

function check(words: Word[]): Finding[] {
  const first = words[0];
  if (first === undefined || first === null) return [];
  const cmd = first.split("/").at(-1);
  const args = words.slice(1);
  switch (cmd) {
    case "sudo":
    case "doas":
      return check(skipOpts(args, ["-u", "-g", "-h", "-p", "-C", "-D", "-r", "-t", "-U", "-T"]));
    case "env":
      if (args.some((arg) => arg !== null && (arg.startsWith("-S") || arg.startsWith("--split-string")))) {
        return [{ deny: "`env -S` is blocked, since the command it runs cannot be checked." }];
      }
      return check(skipEnv(args));
    case "command":
      return args.some((arg) => arg === "-v" || arg === "-V") ? [] : check(skipOpts(args, []));
    case "builtin":
    case "exec":
    case "nohup":
    case "time":
    case "noglob":
    case "nocorrect":
      return check(skipOpts(args, []));
    case "nice":
      return check(skipOpts(args, ["-n"]));
    case "timeout":
      return check(skipOpts(args, ["-s", "-k"]).slice(1));
    case "xargs":
      return check(skipOpts(args, ["-I", "-J", "-L", "-P", "-R", "-S", "-a", "-d", "-E", "-n", "-s"]));
    case "rm":
    case "unlink":
    case "rmdir":
    case "shred":
    case "srm":
      return [denyRm];
    case "find": {
      const findings: Finding[] = [];
      if (args.includes("-delete")) {
        findings.push({ deny: "`find -delete` is blocked. Use `find ... -print0 | xargs -0 gomi` instead." });
      }
      args.forEach((arg, i) => {
        if (arg !== null && ["-exec", "-execdir", "-ok", "-okdir"].includes(arg)) {
          const rest = args.slice(i + 1);
          const end = rest.findIndex((w) => w === ";" || w === "+");
          findings.push(...check(end === -1 ? rest : rest.slice(0, end)));
        }
      });
      return findings;
    }
    case "git": {
      const sub = gitSubcommand(args);
      const dryRun = sub.slice(1).some((arg) => arg === "--dry-run" || (arg !== null && /^-[A-Za-z]*n/.test(arg)));
      return sub[0] === "clean" && !dryRun
        ? [{ deny: "`git clean` is blocked. List the files with `git clean -n`, then `gomi` them." }]
        : [];
    }
    case "sh":
    case "bash":
    case "zsh":
    case "dash":
    case "ksh":
    case "mksh":
      return shellArgs(args, false, false);
    case "nu":
    case "fish":
      return args.flatMap((arg, i): Finding[] => {
        if (arg === null || !["-c", "--commands", "--command"].includes(arg)) return [];
        const body = args[i + 1] ?? null;
        return [
          body === null
            ? { deny: "A dynamically built `-c` script is blocked, since it cannot be checked." }
            : { foreign: body },
        ];
      });
    case "eval":
      return args.includes(null)
        ? [{ deny: "A dynamically built `eval` is blocked, since it cannot be checked." }]
        : [{ script: args.join(" ") }];
    default:
      return [];
  }
}

// Every call expression anywhere in the AST.
function classify(ast: unknown): Finding[] {
  if (ast === null || typeof ast !== "object") return [];
  if (Array.isArray(ast)) return ast.flatMap(classify);
  const node = ast as Node;
  const own = node.Type === "CallExpr" ? check((node.Args ?? []).map(word)) : [];
  return [...own, ...Object.values(node).flatMap(classify)];
}

function parse(script: string): unknown | null {
  for (const dialect of ["zsh", "bash"]) {
    const result = Bun.spawnSync([shfmt, "-ln", dialect, "--to-json"], { stdin: Buffer.from(`${script}\n`) });
    if (result.exitCode === 0) return JSON.parse(result.stdout.toString());
  }
  return null;
}

const foreignDeletion = /(^|[^A-Za-z0-9_-])(rm|unlink|rmdir|shred)([^A-Za-z0-9_-]|$)/;

/** The reason the command is blocked, or null when it may run. */
export function review(script: string, depth = 0): string | null {
  if (depth > 8) return "Nested shell scripts are too deep to check.";
  const ast = parse(script);
  if (ast === null) return "The command could not be parsed, so it cannot be checked for deletions.";
  for (const finding of classify(ast)) {
    if ("deny" in finding) return finding.deny;
    if ("script" in finding) {
      const reason = review(finding.script, depth + 1);
      if (reason !== null) return reason;
    } else if (foreignDeletion.test(finding.foreign)) {
      return "Deleting files permanently is blocked. Use `gomi <paths>` instead.";
    }
  }
  return null;
}

// A JSON "deny" decision is shown as a blocked call rather than a hook error.
// Exit code 2 is the fallback if that JSON cannot be produced. Any other
// non-zero exit is a non-blocking error, which would let the command through.
function deny(reason: string): never {
  try {
    writeSync(
      1,
      `${JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: reason,
        },
      })}\n`,
    );
  } catch {
    console.error(reason);
    process.exit(2);
  }
  process.exit(0);
}

if (import.meta.main) {
  try {
    const command = JSON.parse(await Bun.stdin.text())?.tool_input?.command;
    if (typeof command === "string" && command !== "") {
      const reason = review(command);
      if (reason !== null) deny(reason);
    }
  } catch {
    deny("The hook failed while checking the command, so it was blocked.");
  }
}
