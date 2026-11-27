---
name: off
description: "Remove the worktree lock set by /wt:in, /wt:new or /wt:add, or remove one worktree from the lock list. Usage: /wt:off [-p <path>] [task]."
disable-model-invocation: true
---

# wt:off

`/wt:off` removes the lock. `/wt:off -p <path>` (`--path`, quote spaces) removes one worktree from
the list; it stays on disk. All other text is the task. The plugin hook `hooks/wt-guard.js` added
its result to the prompt as a `wt-guard:` line: `off`, `removed <path>` and the list that stays
locked, or `is not in the list`.

Stay in the current directory. Do not call `ExitWorktree` unless the user asks. Do the task. If
there is no task, report the result and stop.

Task: $ARGUMENTS
