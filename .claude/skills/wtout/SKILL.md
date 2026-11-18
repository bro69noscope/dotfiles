---
name: wtout
description: Lift the worktree lock set by /wtin or /wtnew for this turn only. The lock returns at the next user prompt. Usage: /wtout [task].
disable-model-invocation: true
---

# wtout

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) read this command and lifted the
lock for this turn only. The `wt-guard:` line in the prompt names the locked worktree.

1. Do the task in the arguments. You can write files and run commands outside the worktree.
2. Before you end the turn, make sure the cwd is in the locked worktree again. If you left it, call
   `EnterWorktree` with `path: "<locked worktree>"`. At the next prompt, the hook denies shell
   commands with a cwd outside it.

Task: $ARGUMENTS
