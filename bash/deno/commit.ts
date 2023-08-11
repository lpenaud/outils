import * as io from "https://deno.land/std@0.197.0/io/mod.ts";
import * as flags from "https://deno.land/std@0.197.0/flags/mod.ts";

import { Prompt } from "./utils/prompt.ts";

type CommitTypeUpperCase =
  | "BUILD"
  | "CHORE"
  | "CI"
  | "DOCS"
  | "FEAT"
  | "FIX"
  | "PERF"
  | "REFACTOR"
  | "REVERT"
  | "STYLE";

type CommitTypeLowerCase =
  | "test"
  | "build"
  | "chore"
  | "ci"
  | "docs"
  | "feat"
  | "fix"
  | "perf"
  | "refactor"
  | "revert"
  | "style"
  | "test";


type CommitType = CommitTypeUpperCase | CommitTypeLowerCase;

type Commit = "${CommitType}*";

interface CommitMessage {
  type: CommitType;
  scope: string;
  description: string;
}

interface CommitOptions {
  message: Partial<CommitMessage>;
  edit: boolean;
}

interface GitlabUrlOptions {
  remote: string;
  branch: string;
}

const COMMIT_TYPES: readonly CommitTypeUpperCase[] = Object.freeze([
  "BUILD",
  "CHORE",
  "CI",
  "DOCS",
  "FEAT",
  "FIX",
  "PERF",
  "REFACTOR",
  "REVERT",
  "STYLE",
]);

const TICKET_BRANCH_REG_EXP = /[A-Z0-9]+-[0-9]+$/;

function runGitCommand(options?: Omit<Deno.CommandOptions, "stderr">) {
  return new Deno.Command("git", {
    ...options,
    stderr: "inherit",
  }).output();
}

function isCommit(message: string): message is Commit {
  return COMMIT_TYPES.some((v) =>
    message.substring(0, v.length).toUpperCase() === v
  );
}

async function* listCommits(): AsyncGenerator<Commit> {
  for await (const line of io.readLines(Deno.stdin)) {
    if (isCommit(line)) {
      yield line;
    }
  }
}

async function changelog(prefix?: string): Promise<string> {
  const commits: string[] = [];
  for await (const commit of listCommits()) {
    commits.push(prefix + commit)
  }
  return commits.join("\n");
}

async function getCurrentBranch() {
  const output = await runGitCommand({
    args: [
      "branch",
      "--show-current",
    ],
    stdout: "piped",
  });
  if (output.success) {
    return new TextDecoder().decode(output.stdout)
      .trim();
  }
  return "";
}

async function getRemoteUrl(remote = "origin"): Promise<URL> {
  const output = await runGitCommand({
    args: [
      "remote",
      "get-url",
      remote,
    ],
    stdout: "piped",
  });
  if (!output.success) {
    throw new Error(`Cannot get ${remote} url`);
  }
  return new URL(
    new TextDecoder()
      .decode(output.stdout)
      .trim(),
  );
}

async function getGitlabUrl(options: Partial<GitlabUrlOptions> = {}) {
  // http://HOSTNAME[:PORT]/owner/repository[.git[/]]
  const remoteUrl = await getRemoteUrl(options.remote);
  const branch = options.branch || await getCurrentBranch();
  const pathname = remoteUrl.pathname.replace(/\.git\/?$/, "");
  return new URL(`${pathname}/-/tree/${branch}`, remoteUrl);
}

function createMessage(
  { type, scope, description }: Partial<CommitMessage> = {},
): string {
  let message = "";
  if (type) {
    message = type;
    if (scope) {
      message += `(${scope})`;
    }
    message += ": ";
  }
  if (description) {
    message += description;
  }
  return message;
}

function createCommit(options: Partial<CommitOptions> = {}) {
  const args: string[] = ["commit"];
  if (options.message) {
    if (options.edit) {
      args.push("--edit");
    }
    args.push("--message", createMessage(options.message));
  } else {
    args.push("--edit");
  }
  return runGitCommand({
    args,
    stdin: "inherit",
    stdout: "inherit",
  });
}

function types(args: string[]) {
  const { separator } = flags.parse(args, {
    string: [
      "separator"
    ],
    alias: {
      separator: "s",
    },
    default: {
      separator: "\n",
    },
    unknown(arg) {
      console.error(`Ingore ${arg}`);
    }
  })
  console.log(COMMIT_TYPES.join(separator));
  return Promise.resolve(0);
}

async function commit() {
  const prompt = Prompt.withDefaultString();
  const commitType = await prompt.select(COMMIT_TYPES);
  prompt.print("Scope");
  prompt.printLn(":");
  const commitScope = await prompt.readString();
  prompt.printLn("Description (leave empty to open an editor):");
  const commitDescription = (await prompt.readString())
    .trim();
  const status = await createCommit({
    edit: commitDescription.length === 0,
    message: {
      type: commitType,
      scope: commitScope,
      description: commitDescription,
    },
  });
  return status.code;
}

async function gitlabUrl(args: string[]): Promise<number> {
  const options = flags.parse(args, {
    string: [
      "branch",
      "remote"
    ],
    alias: {
      branch: "b",
      remote: "r"
    },
  });
  const gitlabUrl = await getGitlabUrl({
    branch: options.branch ?? options.b,
    remote: options.remote ?? options.r,
  });
  console.log(gitlabUrl.href);
  return 0;
}

function main(args: string[]): Promise<number> {
  const commands: Record<string, (args: string[]) => Promise<number>> = {
    async changelog() {
      console.log(await changelog("* "));
      return 0;
    },
    types,
    commit,
    "gitlab-url": gitlabUrl,
  };
  const command = commands[args[0] ?? "types"];
  if (command === undefined) {
    console.error("Usage: git COMMAND");
    return Promise.resolve(1);
  }
  return command(args.slice(1));
}

if (import.meta.main) {
  Deno.exit(await main(Deno.args.slice()));
}
