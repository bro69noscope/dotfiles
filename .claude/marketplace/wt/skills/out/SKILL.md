---
name: out
description: "Lift the worktree lock set by /wt:in, /wt:new or /wt:add for this turn only. The lock returns at the next user prompt. Usage: /wt:out [task]."
disable-model-invocation: true
---

# wt:out

The plugin hook `hooks/wt-guard.js` lifted the lock for this turn. Its `wt-guard:` line in the
prompt lists the locked worktrees.

1. Do the task. You can write and run commands outside the worktrees.
2. Before you end the turn, `EnterWorktree` a locked worktree again if you left it. At the next
   prompt, the hook denies a shell cwd outside the locked worktrees.

Task: $ARGUMENTS
