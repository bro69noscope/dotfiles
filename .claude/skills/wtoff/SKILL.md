---
name: wtoff
description: Remove the worktree lock set by /wtin or /wtnew. The session can work outside the worktree again. Usage: /wtoff [task].
disable-model-invocation: true
---

# wtoff

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) read this command and removed the
lock. Nothing restricts the session to the worktree now.

Stay in the current directory. Do not call `ExitWorktree` unless the user asks. Do the task in the
arguments. If there is no task, report that the lock is off and stop.

Task: $ARGUMENTS
