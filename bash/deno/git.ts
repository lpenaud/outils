#!/usr/bin/env -S deno run --allow-run=git 
import * as io from "std/io/mod.ts";
import * as flags from "std/flags/mod.ts";
import { Prompt } from "./utils/prompt.ts";
import { unknownFlagArg } from "./utils/cli.ts";

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
  remoteUrl: URL;
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

async function getChangelog(prefix?: string): Promise<string> {
  const commits: string[] = [];
  for await (const commit of listCommits()) {
    commits.push(prefix + commit);
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

function getGitPathname(remoteUrl: URL): string {
  return remoteUrl.pathname.replace(/\.git\/?$/, "");
}

async function getGitlabUrl(
  options: Partial<GitlabUrlOptions> = {},
): Promise<URL> {
  // http://HOSTNAME[:PORT]/owner/repository[.git[/]]
  const remoteUrl = options.remoteUrl || await getRemoteUrl(options.remote);
  const branch = options.branch || await getCurrentBranch();
  return new URL(`${getGitPathname(remoteUrl)}/-/tree/${branch}`, remoteUrl);
}

async function getGithubUrl(options: Partial<GitlabUrlOptions>): Promise<URL> {
  const remoteUrl = options.remoteUrl || await getRemoteUrl(options.remote);
  const branch = options.branch || await getCurrentBranch();
  return new URL(`${getGitPathname(remoteUrl)}/tree/${branch}`, remoteUrl);
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
      "separator",
    ],
    alias: {
      separator: "s",
    },
    default: {
      separator: "\n",
    },
    unknown: unknownFlagArg,
  });
  console.log(COMMIT_TYPES.join(separator));
  return Promise.resolve(0);
}

function isCommitType(type?: string): type is CommitType {
  if (type === undefined) {
    return false;
  }
  if (COMMIT_TYPES.includes(type as CommitTypeUpperCase)) {
    return true;
  }
  return COMMIT_TYPES.find((v) => v.toLowerCase() === type) !== undefined;
}

function addFiles(files: string[]) {
  if (files.length === 0) {
    return null;
  }
  return runGitCommand({
    args: ["add"].concat(files),
  });
}

async function commit(args: string[]): Promise<number> {
  let { type, scope, description, edit, _: files } = flags.parse(args, {
    string: [
      "type",
      "scope",
      "description",
    ],
    boolean: [
      "edit",
    ],
    alias: {
      type: "t",
      scope: "s",
      description: "d",
      edit: "e",
    },
  });
  const prompt = Prompt.withDefaultString();
  const commitType: CommitType = isCommitType(type)
    ? type
    : await prompt.select(COMMIT_TYPES);
  if (scope === undefined) {
    prompt.printLn("Scope:");
    scope = await prompt.readString();
  }
  if (description === undefined) {
    prompt.printLn("Description (leave empty to open an editor):");
    description = (await prompt.readString()).trim();
  }
  const addProcess = await addFiles(files.map((v) => v.toString()));
  if (addProcess !== null && !addProcess.success) {
    return 1;
  }
  const status = await createCommit({
    edit: edit || description.length === 0,
    message: {
      type: commitType,
      scope,
      description,
    },
  });
  return status.code;
}

type GitWebUrlType = "gitlab" | "github";

interface GebWebUrlOptions extends GitlabUrlOptions {
  type: GitWebUrlType;
}

async function getWebUrl(options: Partial<GebWebUrlOptions> = {}) {
  const remoteUrl = await getRemoteUrl(options.remote);
  switch (options.type) {
    case "github":
      return getGithubUrl(options);
    case "gitlab":
      return getGitlabUrl(options);
  }
  if (remoteUrl.host === "github.com") {
    return getGithubUrl(options);
  }
  return getGitlabUrl(options);
}

function isGitWebUrlType(type: string): type is GitWebUrlType {
  return ["gitlab", "github"].includes(type);
}

function parseGitWebUrlType(type?: string): GitWebUrlType | undefined {
  if (type === undefined) {
    return undefined;
  }
  if (isGitWebUrlType(type)) {
    return type;
  }
  return undefined;
}

async function getUrl(args: string[]): Promise<number> {
  const { branch, remote, type } = flags.parse(args, {
    string: [
      "branch",
      "remote",
      "type",
    ],
    alias: {
      branch: "b",
      remote: "r",
      type: "t",
    },
    unknown: unknownFlagArg,
  });
  const webUrl = await getWebUrl({
    branch,
    remote,
    type: parseGitWebUrlType(type),
  });
  console.log(webUrl.href);
  return 0;
}

async function changelog(): Promise<number> {
  console.log(await getChangelog());
  return 0;
}

function main(args: string[]): Promise<number> {
  const commands: Record<string, (args: string[]) => Promise<number>> = {
    changelog,
    types,
    commit,
    "get-url": getUrl,
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
