---
name: wtnew
description: Create a new git worktree for the task, enter it, and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtnew [task].
disable-model-invocation: true
---

# wtnew

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) owns the lock. It read this
command and set the lock to pending. The session locks to the next linked worktree it enters. Until
then, the hook denies file writes outside the session scratchpad. After the lock, it also denies:

- shell commands whose cwd is outside the worktree, or that name a path in the main checkout,
- `ExitWorktree`, and `EnterWorktree` to any other worktree.

## Steps

1. Make a short kebab-case name from the task: letters, digits, `.`, `_`, `-`, 64 characters max.
   If there is no task, do not give a name.
2. Create and enter the worktree:
   - If the session is not in an `EnterWorktree` session, call `EnterWorktree` with that `name`.
   - If it is, `EnterWorktree` with `name` fails. Run
     `git -C <main checkout> worktree add .claude/worktrees/<name> -b <name>`, then call
     `EnterWorktree` with that `path`.
3. Do the task inside the new worktree. If there is no task, report the worktree path and stop.

## Rules

- Stay in the worktree. Do not call `ExitWorktree`.
- Do not work around a denial (relative paths, `cd ..`, other tools). If the task needs the main
  checkout or another directory, ask the user to send `/wtout` or `/wtoff`.

Task: $ARGUMENTS
