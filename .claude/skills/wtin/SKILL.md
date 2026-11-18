---
name: wtin
description: Lock this session to an existing git worktree and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtin [worktree path, directory name, or branch] [task].
disable-model-invocation: true
---

# wtin

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) owns the lock. It read this
command and added a `wt-guard:` line to the prompt. While the lock is on, the hook denies:

- file writes outside the worktree (the session scratchpad is allowed),
- shell commands whose cwd is outside the worktree, or that name a path in the main checkout,
- `ExitWorktree`, and `EnterWorktree` to any other worktree.

## Steps

1. Read the `wt-guard:` line.
   - `locked to <root>`: if the cwd is not in `<root>`, call `EnterWorktree` with `path: "<root>"`.
   - `lock pending`: no worktree matched the first argument and the cwd is not in a linked
     worktree. Run `git worktree list` and ask the user which worktree to use. Then call
     `EnterWorktree` with that `path`. The session locks to it.
2. Do the task in the arguments, inside the worktree. The first argument is the worktree target if
   it matched one. If there is no task, report the locked worktree and stop.

## Rules

- Stay in the worktree. Do not call `ExitWorktree`.
- Do not work around a denial (relative paths, `cd ..`, other tools). If the task needs the main
  checkout or another directory, ask the user to send `/wtout` or `/wtoff`.

Arguments: $ARGUMENTS
