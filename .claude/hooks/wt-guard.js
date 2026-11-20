// wt-guard: keep a Claude Code session inside one git worktree.
//
// UserPromptSubmit: the user's /wtin, /wtnew, /wtout and /wtoff prompts set the per-session lock.
// Only a typed user prompt changes the lock, so Claude cannot unlock itself.
//
// PreToolUse: while locked, deny file writes and shell commands outside the locked worktree, and
// deny ExitWorktree or EnterWorktree to another worktree.
//
// This is a guard against mistakes, not a sandbox. Shell commands are checked only for their cwd
// and for literal paths into the main checkout.

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const STATE_DIR = path.join(os.homedir(), ".claude", "wt-guard");
const WRITE_TOOLS = ["Edit", "Write", "NotebookEdit"];
const SHELL_TOOLS = ["Bash", "PowerShell"];

// "C:\Users\X\repo\" -> "c:/users/x/repo"
const norm = (p) => path.resolve(p).replace(/\\/g, "/").toLowerCase();
const inside = (p, root) => p === root || p.startsWith(root + "/");
const nameChar = (c) => /[\w.-]/.test(c || "");

const stateFile = (id) => path.join(STATE_DIR, `${id}.json`);

function load(id) {
  try {
    return JSON.parse(fs.readFileSync(stateFile(id), "utf8"));
  } catch {
    return null;
  }
}

function save(id, state) {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(stateFile(id), JSON.stringify(state));
}

function git(dir, args) {
  try {
    return execFileSync("git", ["-C", dir, ...args], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
  } catch {
    return null;
  }
}

// { top, main, linked } for the repository at dir, or null outside a repository.
// linked is true in a worktree made by `git worktree add`.
function gitInfo(dir) {
  const out = git(dir, [
    "rev-parse",
    "--path-format=absolute",
    "--show-toplevel",
    "--git-dir",
    "--git-common-dir",
  ]);
  if (!out) return null;

  const [top, gitDir, common] = out.trim().split(/\r?\n/).map(norm);
  return { top, main: path.posix.dirname(common), linked: gitDir !== common };
}

// The root of the worktree on branch arg, or null.
function findWorktree(dir, arg) {
  const out = git(dir, ["worktree", "list", "--porcelain"]);
  if (!out) return null;

  const want = arg.toLowerCase();
  const hits = out
    .split(/\r?\n\r?\n/)
    .map((block) => {
      const wt = block.match(/^worktree (.+)$/m);
      const branch = block.match(/^branch refs\/heads\/(.+)$/m);
      return (
        wt && {
          root: norm(wt[1]),
          branch: branch ? branch[1].toLowerCase() : "",
        }
      );
    })
    .filter(Boolean)
    .filter((w) => w.branch === want);

  return hits.length === 1 ? hits[0].root : null;
}

// True when cmd names a path in the main checkout that is not in root.
// Checks both "c:/x" and Git Bash "/c/x" spellings.
function escapes(cmd, main, root) {
  const text = cmd.replace(/\\+/g, "/").toLowerCase();
  const msys = (p) => p.replace(/^([a-z]):/, "/$1");

  for (const [m, r] of [
    [main, root],
    [msys(main), msys(root)],
  ]) {
    for (let i = text.indexOf(m); i !== -1; i = text.indexOf(m, i + 1)) {
      if (nameChar(text[i + m.length])) continue;
      if (text.startsWith(r, i) && !nameChar(text[i + r.length])) continue;
      return true;
    }
  }
  return false;
}

function emit(obj) {
  process.stdout.write(JSON.stringify(obj));
}

function context(text) {
  emit({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: `wt-guard: ${text}`,
    },
  });
}

function deny(reason) {
  emit({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason:
        `wt-guard: ${reason} Do not work around this. ` +
        "If the task needs it, ask the user to send /wtout (this turn only) or /wtoff.",
    },
  });
}

function onPrompt(input) {
  const id = input.session_id;
  const state = load(id);
  const m = input.prompt.match(/^\s*\/(wtin|wtnew|wtout|wtoff)\b\s*([\s\S]*)$/);

  if (!m) {
    // A /wtout lasts one turn: any other prompt locks again.
    if (state && state.mode === "out") {
      state.mode = "lock";
      save(id, state);
      context(
        `one-off exit ended. Locked again to ${state.root || "the next worktree entered"}.`,
      );
    }
    return;
  }

  const [, cmd, rest] = m;

  if (cmd === "wtoff") {
    fs.rmSync(stateFile(id), { force: true });
    return context("off. No worktree restriction.");
  }

  if (cmd === "wtout") {
    if (!state) return context("already off. Nothing to lift.");
    state.mode = "out";
    save(id, state);
    return context(
      `lifted for this turn only. The lock to ${state.root} returns at the next prompt.`,
    );
  }

  const here = gitInfo(input.cwd);
  if (!here)
    return context(`${input.cwd} is not in a git repository. No lock set.`);

  // wtin -b <x>: lock the worktree on branch x. wtin -l <x>: pending, the skill matches x loosely.
  // wtin with neither: lock the current linked worktree.
  // wtnew, or wtin with no match: pending until the session enters a worktree.
  let root = null;
  if (cmd === "wtin") {
    const b = rest.match(/(?:^|\s)(?:-b|--branch)\s+(\S+)/);
    const loose = /(?:^|\s)(?:-l|--loose)\s+\S/.test(rest);
    root = b
      ? findWorktree(input.cwd, b[1])
      : loose
        ? null
        : here.linked
          ? here.top
          : null;
  }

  save(id, { mode: "lock", root, main: here.main, from: here.top });

  if (root)
    return context(`locked to ${root}. Current cwd: ${norm(input.cwd)}.`);
  return context(
    "lock pending. The session locks to the worktree that EnterWorktree enters next. " +
      "Until then, file writes are denied outside the scratchpad.",
  );
}

function onTool(input) {
  const id = input.session_id;
  const state = load(id);
  if (!state || state.mode !== "lock") return;

  const tool = input.tool_name;
  const args = input.tool_input || {};

  // A pending lock takes the worktree that EnterWorktree enters by path, even the current one.
  if (!state.root && tool === "EnterWorktree" && args.path) {
    const g = gitInfo(path.resolve(input.cwd, args.path));
    if (g && g.linked) {
      state.root = g.top;
      state.main = g.main;
      save(id, state);
      return;
    }
  }

  if (!state.root) {
    const g = gitInfo(input.cwd);
    if (g && g.linked && g.top !== state.from) {
      state.root = g.top;
      state.main = g.main;
      save(id, state);
    }
  }

  const { root, main } = state;

  if (tool === "ExitWorktree") {
    if (root) deny(`the session is locked to ${root}.`);
    return;
  }

  if (tool === "EnterWorktree") {
    if (
      !root ||
      (args.path && norm(path.resolve(input.cwd, args.path)) === root)
    )
      return;
    return deny(
      `the session is locked to ${root}. Only EnterWorktree with path "${root}" is allowed.`,
    );
  }

  if (WRITE_TOOLS.includes(tool)) {
    const file = args.file_path || args.notebook_path;
    if (!file) return;

    const target = norm(path.resolve(input.cwd, file));
    const scratch = norm(
      input.scratchpad_dir || path.join(os.tmpdir(), "claude"),
    );
    if ((root && inside(target, root)) || inside(target, scratch)) return;

    return deny(
      root
        ? `${target} is outside the locked worktree ${root}.`
        : `lock pending: enter the worktree first (EnterWorktree), then write ${target} there.`,
    );
  }

  if (SHELL_TOOLS.includes(tool) && root) {
    const cwd = norm(input.cwd);
    if (!inside(cwd, root)) {
      return deny(
        `cwd ${cwd} is outside the locked worktree. Call EnterWorktree with path "${root}".`,
      );
    }
    if (escapes(args.command || "", main, root)) {
      return deny(
        `the command names a path in the main checkout ${main}, outside ${root}.`,
      );
    }
  }
}

let raw = "";
process.stdin.on("data", (chunk) => (raw += chunk));
process.stdin.on("end", () => {
  try {
    const input = JSON.parse(raw);
    if (input.hook_event_name === "UserPromptSubmit") onPrompt(input);
    else if (input.hook_event_name === "PreToolUse") onTool(input);
  } catch (err) {
    // Fail open: a broken guard must not block the session.
    process.stderr.write(`wt-guard: ${err.message}\n`);
  }
});
