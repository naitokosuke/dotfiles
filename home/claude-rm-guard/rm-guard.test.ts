import { expect, test } from "bun:test";
import { review } from "./rm-guard.ts";

const allowed = [
  "ls -la",
  "gomi old.txt",
  "git rm file.txt",
  "git clean -n",
  "git clean --dry-run -fd",
  "git -C repo status",
  "echo rm",
  "echo 'rm -rf /'",
  "grep -r rm .",
  "command -v rm",
  "find . -name '*.tmp' -print0 | xargs -0 gomi",
  "find . -exec ls {} ;",
  "sh -c 'ls'",
  "bash script.sh",
  "env FOO=1 ls",
  "sudo -u someone ls",
  "timeout 5 ls",
  "eval 'ls -la'",
  "nu -c 'ls'",
  "FOO=bar",
];

const denied = [
  "rm file.txt",
  "rm -rf dir",
  "/bin/rm file.txt",
  "unlink file.txt",
  "rmdir dir",
  "shred file.txt",
  "srm file.txt",
  "ls && rm file.txt",
  "ls | xargs rm",
  "xargs -n 1 rm",
  "echo $(rm file.txt)",
  "echo `rm file.txt`",
  "sudo rm file.txt",
  "sudo -u someone rm file.txt",
  "doas rm file.txt",
  "env FOO=1 rm file.txt",
  "env -S 'rm file.txt'",
  "command rm file.txt",
  "exec rm file.txt",
  "nohup rm file.txt",
  "time rm file.txt",
  "nice -n 5 rm file.txt",
  "timeout -s KILL 5 rm file.txt",
  "'rm' file.txt",
  '"rm" file.txt',
  "\\rm file.txt",
  "find . -delete",
  "find . -name '*.tmp' -exec rm {} ;",
  "find . -execdir rm {} +",
  "git clean -fd",
  "git -C repo clean -f",
  "sh -c 'rm file.txt'",
  "bash -lc 'rm file.txt'",
  "zsh -c 'ls; rm file.txt'",
  'sh -c "$script"',
  "sh -c 'sh -c \"rm file.txt\"'",
  "sh",
  "bash -s",
  "curl example.com | sh",
  "eval 'rm file.txt'",
  'eval "$cmd"',
  "nu -c 'rm file.txt'",
  "fish -c 'rm file.txt'",
  'nu -c "$script"',
  "if true; then rm file.txt; fi",
  "f() { rm file.txt; }; f",
  "ls 'unterminated",
];

test.each(allowed)("allows %s", (command) => {
  expect(review(command)).toBeNull();
});

test.each(denied)("denies %s", (command) => {
  expect(review(command)).toBeString();
});

test("denies scripts nested too deeply to check", () => {
  let command = "rm file.txt";
  for (let depth = 0; depth < 10; depth++) command = `sh -c ${JSON.stringify(command).replaceAll("$", "\\$")}`;
  expect(review(command)).toBeString();
});
