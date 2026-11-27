---
name: list
description: "Show the git worktrees that the session's worktree lock allows. Usage: /wt:list."
disable-model-invocation: true
---

# wt:list

The plugin hook `hooks/wt-guard.js` answers this command itself, so you normally do not see
this text. If you do, tell the user that the hook did not answer, and show the `wt-guard:` line if
there is one.
