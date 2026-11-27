// wt-guard: keep a Claude Code session inside a list of git worktrees.
//
// UserPromptSubmit: the user's /wt:in, /wt:new, /wt:add, /wt:out and /wt:off prompts set the per-session
// lock, and /wt:list shows it. Only a typed user prompt changes the lock, so Claude cannot unlock
// itself. /wt:in -r, /wt:add -r and /wt:new -r take the items that Claude showed on
// "wt-suggest: <repo> <branch>" lines in its last reply: the user saw each one before they
// approved it.
//
// PreToolUse: while locked, deny file writes and shell commands outside the locked worktrees, and
// deny ExitWorktree or EnterWorktree to a worktree that is not in the list.
//
// This is a guard against mistakes, not a sandbox. Shell commands are checked only for their cwd
// and for literal paths into the main checkout of a locked repository.

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const STATE_DIR = path.join(os.homedir(), ".claude", "wt-guard");
const WRITE_TOOLS = ["Edit", "Write", "NotebookEdit"];
const SHELL_TOOLS = ["Bash", "PowerShell"];

// "-r" or "--reply" anywhere in the arguments.
const REPLY = /(?:^|\s)(?:-r|--reply)(?=\s|$)/;
// A line "wt-suggest: <repo> <branch>" in Claude's reply. The item can be in backticks.
const SUGGEST = /^[\s>*-]*wt-suggest:\s*`?([^`\r\n]+?)`?\s*$/gm;

// "C:\Users\X\repo\" -> "c:/users/x/repo"
const norm = (p) => path.resolve(p).replace(/\\/g, "/").toLowerCase();
const inside = (p, root) => p === root || p.startsWith(root + "/");
const nameChar = (c) => /[\w.-]/.test(c || "");

// A path that the user or Claude typed, relative to cwd, with "~" for the home directory.
const resolveWord = (word, cwd) =>
  norm(path.resolve(cwd, word.replace(/^~(?=[\\/]|$)/, os.homedir())));

const stateFile = (id) => path.join(STATE_DIR, `${id}.json`);

// State: { mode: "lock" | "out", roots: [{ root, main, pending? }], wait?, from? }
// pending: the worktree does not exist yet. It becomes active when git sees it as a linked worktree.
// wait: the next linked worktree that the session enters joins the list (/wt:new, /wt:in without a
// match). from: the checkout the session was in when wait was set.
function load(id) {
  try {
    const state = JSON.parse(fs.readFileSync(stateFile(id), "utf8"));

    // State from before the list: { mode, root, main, from }. A null root was a pending lock.
    if (!state.roots) {
      state.roots = state.root ? [{ root: state.root, main: state.main }] : [];
      state.wait = !state.root;
    }
    return state;
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

// The value of option -<short> or --<long> in rest, or null. A value with spaces needs quotes.
// option('-p "C:/a b" go', "p", "path") -> "C:/a b"
function option(rest, short, long) {
  const m = rest.match(
    new RegExp(`(?:^|\\s)(?:-${short}|--${long})\\s+(?:"([^"]+)"|'([^']+)'|(\\S+))`),
  );
  return m && (m[1] ?? m[2] ?? m[3]);
}

// The "<repo> <branch>" items on "wt-suggest:" lines in Claude's last reply: the assistant
// messages after the last prompt that the user typed.
function suggested(transcript) {
  let lines;
  try {
    lines = fs.readFileSync(transcript, "utf8").split(/\r?\n/);
  } catch {
    return [];
  }

  const found = [];
  let reply = false;
  for (let i = lines.length - 1; i >= 0; i--) {
    let e;
    try {
      e = JSON.parse(lines[i]);
    } catch {
      continue;
    }
    if (e.isSidechain || !e.message) continue;

    // A typed prompt has string content. Tool results and skill text come back as user messages too.
    const content = e.message.content;
    if (e.type === "assistant" && Array.isArray(content)) {
      reply = true;
      const texts = content.filter((c) => c.type === "text").map((c) => c.text);
      found.unshift(...texts.flatMap((t) => [...t.matchAll(SUGGEST)].map((m) => m[1])));
    } else if (e.type === "user" && reply && !e.isMeta) {
      const toolResult =
        Array.isArray(content) && content.some((c) => c.type === "tool_result");
      if (!toolResult) break;
    }
  }
  return found;
}

// A lock entry { root, main } for the worktree at word, or a string that tells why not.
function pathEntry(word, cwd) {
  const abs = resolveWord(word, cwd);
  const g = fs.existsSync(abs) && gitInfo(abs);
  if (!g || !g.linked || g.top !== abs)
    return `${abs} is not the top directory of a linked worktree.`;
  return { root: abs, main: g.main };
}

// A lock entry for the existing worktree on __llm/<branch> in the repository at dir.
function branchEntry(dir, branch) {
  const b = llmBranch(branch);
  const root = findWorktree(dir, b);
  const g = root && gitInfo(root);
  if (!g || !g.linked) return `${norm(dir)} has no linked worktree on ${b}.`;
  return { root, main: g.main };
}

// "feat/wt" -> "__llm/feat/wt". A name that has the prefix stays as it is.
const llmBranch = (b) => (/^__llm\//i.test(b) ? b : `__llm/${b}`);

// Lock entries for "[<repo> <branch>, ...]" at the start of rest, or a string that tells why not.
// No options are allowed with a list.
function branchList(rest, cwd, create) {
  const list = rest.match(/^\s*\[([^\]]*)\]/);
  if (!list) return "The list has no closing ].";
  if (/(?:^|\s)(?:-[abprs]|--(?:auto|branch|path|reply|smart))(?=\s|$)/.test(rest))
    return "A [list] takes no -a, -b, -p, -r or -s option.";

  return resolveItems(list[1].split(","), cwd, create);
}

// Lock entries for "<repo> <branch>" items, or a string that tells why not.
// <repo> is any checkout of the repository. A path with spaces needs quotes.
// ['C:/a feat/x', '"C:/b c" fix'] -> worktrees on __llm/feat/x in C:/a and __llm/fix in "C:/b c"
// create false: each worktree must exist. create true (/wt:new): an existing worktree is used as
// it is. A missing one is pending at <main>/.claude/worktrees/<branch with each "/" replaced by "_">.
function resolveItems(raw, cwd, create) {
  const items = raw.map((s) => s.trim()).filter(Boolean);
  if (!items.length) return "The list is empty.";

  const out = [];
  const errors = [];
  for (const item of items) {
    const m = item.match(/^(?:"([^"]+)"|'([^']+)'|(\S+))\s+(\S+)$/);
    if (!m) {
      errors.push(`"${item}" is not "<repo> <branch>".`);
      continue;
    }

    const repo = resolveWord(m[1] ?? m[2] ?? m[3], cwd);
    const branch = llmBranch(m[4]);

    if (create) {
      const g = gitInfo(repo);
      const root = findWorktree(repo, branch);
      const dir = g && `${g.main}/.claude/worktrees/${branch.toLowerCase().replace(/\//g, "_")}`;
      if (!g) errors.push(`${repo} is not in a git repository.`);
      else if (root) out.push({ root, main: g.main });
      else if (fs.existsSync(dir)) errors.push(`${dir} exists, but not on ${branch}.`);
      else out.push({ root: dir, main: g.main, pending: true });
      continue;
    }

    const e = branchEntry(repo, branch);
    if (typeof e === "string") errors.push(e);
    else out.push(e);
  }
  return errors.length ? errors.join(" ") : out;
}

// Add e to state.roots, if the list does not have it.
function addRoot(state, e) {
  if (!state.roots.some((r) => r.root === e.root)) state.roots.push(e);
}

// Make each pending root active when git sees it as a linked worktree. True if one changed.
function activate(state) {
  let changed = false;
  for (const r of state.roots.filter((r) => r.pending)) {
    const g = gitInfo(r.root);
    if (g && g.linked && g.top === r.root) {
      delete r.pending;
      changed = true;
    }
  }
  return changed;
}

function listText(state) {
  const lines = state.roots.map((r) => {
    if (r.pending) return `  ${r.root} (pending: not created yet)`;
    const branch = (git(r.root, ["branch", "--show-current"]) || "").trim();
    return `  ${r.root}${branch ? ` (${branch})` : ""}`;
  });

  const parts = [];
  if (lines.length) parts.push(`locked to:\n${lines.join("\n")}`);
  if (state.wait)
    parts.push(
      lines.length
        ? "The next worktree that EnterWorktree enters joins the list."
        : "lock pending. The session locks to the worktree that EnterWorktree enters next. " +
            "Until then, file writes are denied outside the scratchpad.",
    );
  if (state.mode === "out")
    parts.push("Lifted for this turn only. The lock returns at the next prompt.");
  return parts.join("\n");
}

// True when cmd names a path in one of mains that is not in one of roots.
// Checks both "c:/x" and Git Bash "/c/x" spellings.
function escapes(cmd, mains, roots) {
  const text = cmd.replace(/\\+/g, "/").toLowerCase();
  const msys = (p) => p.replace(/^([a-z]):/, "/$1");

  for (const spell of [(p) => p, msys]) {
    const rs = roots.map(spell);
    for (const m of mains.map(spell)) {
      for (let i = text.indexOf(m); i !== -1; i = text.indexOf(m, i + 1)) {
        if (nameChar(text[i + m.length])) continue;
        if (rs.some((r) => text.startsWith(r, i) && !nameChar(text[i + r.length])))
          continue;
        return true;
      }
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

// Show text to the user and do not send the prompt to Claude.
function block(text) {
  emit({ decision: "block", reason: `wt-guard: ${text}` });
}

function deny(reason) {
  emit({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason:
        `wt-guard: ${reason} Do not work around this. ` +
        "If the task needs another worktree, show it on a line " +
        '"wt-suggest: <repo> <branch>" and ask the user to send /wt:add -r ' +
        "(it exists) or /wt:new -r (to create it). " +
        "For other directories, ask the user to send /wt:out (this turn only) or /wt:off.",
    },
  });
}

function onPrompt(input) {
  const id = input.session_id;
  const state = load(id);
  const m = input.prompt.match(
    /^\s*\/wt:(in|new|add|list|out|off)\b\s*([\s\S]*)$/,
  );

  if (!m) {
    // A /wt:out lasts one turn: any other prompt locks again.
    if (state && state.mode === "out") {
      state.mode = "lock";
      save(id, state);
      context(`one-off exit ended. ${listText(state)}`);
    }
    return;
  }

  const [, cmd, rest] = m;

  if (cmd === "list")
    return block(state ? listText(state) : "off. No worktree restriction.");

  // /wt:off -p <path>: remove that worktree from the list. /wt:off: remove the lock.
  if (cmd === "off") {
    const word = option(rest, "p", "path");
    if (state && word) {
      const abs = resolveWord(word, input.cwd);
      const left = state.roots.filter((r) => r.root !== abs);
      if (left.length === state.roots.length)
        return context(`${abs} is not in the list. Nothing removed.\n${listText(state)}`);
      if (left.length || state.wait) {
        state.roots = left;
        save(id, state);
        return context(`removed ${abs}.\n${listText(state)}`);
      }
    }
    fs.rmSync(stateFile(id), { force: true });
    return context("off. No worktree restriction.");
  }

  if (cmd === "out") {
    if (!state) return context("already off. Nothing to lift.");
    state.mode = "out";
    save(id, state);
    return context(listText(state));
  }

  // Entries from a [<repo> <branch>, ...] list, from -r (the same items on the wt-suggest: lines
  // of the last reply), from -p <path>, or from /wt:add -b <branch>. /wt:in replaces the list,
  // /wt:add adds to it, /wt:new replaces it with pending worktrees. Only /wt:new creates.
  const create = cmd === "new";
  const p = cmd !== "new" && option(rest, "p", "path");
  const b = cmd === "add" && option(rest, "b", "branch");
  let got = null;
  let how = "";

  if (["in", "add", "new"].includes(cmd) && /^\s*\[/.test(rest)) {
    how = "the [<repo> <branch>] list";
    got = branchList(rest, input.cwd, create);
  } else if (["in", "add", "new"].includes(cmd) && REPLY.test(rest)) {
    how = "--reply (the wt-suggest: items of the last reply)";
    const items = suggested(input.transcript_path);
    got = items.length
      ? resolveItems(items, input.cwd, create)
      : "No wt-suggest: lines in the last reply.";
  } else if (p) {
    how = "--path";
    got = pathEntry(p, input.cwd);
    if (typeof got !== "string") got = [got];
  } else if (b) {
    how = "--branch (in the cwd's repository)";
    got = branchEntry(input.cwd, b);
    if (typeof got !== "string") got = [got];
  } else if (cmd === "add") {
    return context(
      "usage: /wt:add (-p <path> | -b <branch> | -r | [<repo> <branch>, ...]). No lock change.",
    );
  }

  if (got) {
    if (typeof got === "string") return context(`no lock change from ${how}. ${got}`);

    const next =
      cmd === "add" && state ? state : { mode: "lock", roots: [] };
    got.forEach((e) => addRoot(next, e));
    save(id, next);
    const did = cmd === "add" ? "added" : "replaced the list with";
    const todo = got.some((e) => e.pending) ? " Create each pending worktree." : "";
    return context(`${did} ${how}.${todo}\n${listText(next)}`);
  }

  const here = gitInfo(input.cwd);
  if (!here)
    return context(`${input.cwd} is not in a git repository. No lock set.`);

  // /wt:in -b <x>: lock the worktree on branch x. /wt:in -s <x>: pending, the skill matches x smartly.
  // /wt:in with neither: lock the current linked worktree.
  // /wt:new, or /wt:in with no match: pending until the session enters a worktree.
  let root = null;
  if (cmd === "in") {
    const b = rest.match(/(?:^|\s)(?:-b|--branch)\s+(\S+)/);
    const smart = /(?:^|\s)(?:-s|--smart)\s+\S/.test(rest);
    root = b
      ? findWorktree(input.cwd, llmBranch(b[1]))
      : smart
        ? null
        : here.linked
          ? here.top
          : null;
  }

  const next = root
    ? { mode: "lock", roots: [{ root, main: here.main }] }
    : { mode: "lock", roots: [], wait: true, from: here.top };
  save(id, next);

  if (root)
    return context(`${listText(next)}\nCurrent cwd: ${norm(input.cwd)}.`);
  return context(listText(next));
}

function onTool(input) {
  const id = input.session_id;
  const state = load(id);
  if (!state || state.mode !== "lock") return;

  const tool = input.tool_name;
  const args = input.tool_input || {};

  let changed = activate(state);

  // wait: the worktree that EnterWorktree enters by path joins the list, even the current one.
  if (state.wait && tool === "EnterWorktree" && args.path) {
    const g = gitInfo(path.resolve(input.cwd, args.path));
    if (g && g.linked) {
      addRoot(state, { root: g.top, main: g.main });
      state.wait = false;
      save(id, state);
      return;
    }
  }

  if (state.wait) {
    const g = gitInfo(input.cwd);
    if (g && g.linked && g.top !== state.from) {
      addRoot(state, { root: g.top, main: g.main });
      state.wait = false;
      changed = true;
    }
  }

  if (changed) save(id, state);

  const active = state.roots.filter((r) => !r.pending);
  const roots = active.map((r) => r.root);
  const isIn = (p) => roots.some((r) => inside(p, r));
  const list = roots.join(", ");

  if (tool === "ExitWorktree") {
    if (roots.length) deny(`the session is locked to ${list}.`);
    return;
  }

  if (tool === "EnterWorktree") {
    const target = args.path && norm(path.resolve(input.cwd, args.path));
    if (!roots.length || roots.includes(target)) return;
    return deny(
      `the session is locked to ${list}. EnterWorktree is allowed only with one of these paths.`,
    );
  }

  if (WRITE_TOOLS.includes(tool)) {
    const file = args.file_path || args.notebook_path;
    if (!file) return;

    const target = norm(path.resolve(input.cwd, file));
    const scratch = norm(
      input.scratchpad_dir || path.join(os.tmpdir(), "claude"),
    );
    if (isIn(target) || inside(target, scratch)) return;

    return deny(
      roots.length
        ? `${target} is outside the locked worktrees ${list}.`
        : `lock pending: create or enter the worktree first, then write ${target} there.`,
    );
  }

  if (SHELL_TOOLS.includes(tool) && roots.length) {
    const cwd = norm(input.cwd);
    if (!isIn(cwd)) {
      return deny(
        `cwd ${cwd} is outside the locked worktrees. ` +
          `Call EnterWorktree with the path of one of ${list}, or use git -C <path>.`,
      );
    }

    // A pending root is not in mains, but a command can name it: `git worktree add` creates it.
    const mains = [...new Set(active.map((r) => r.main))];
    const named = state.roots.map((r) => r.root);
    if (escapes(args.command || "", mains, named)) {
      return deny(
        `the command names a path in the main checkout ${mains.join(", ")}, outside ${list}.`,
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
