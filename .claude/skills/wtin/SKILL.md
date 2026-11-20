---
name: wtin
description: Lock this session to an existing git worktree and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtin [-b <branch> | -l <loose branch>] [task].
disable-model-invocation: true
---

# wtin

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) owns the lock. It read this
command and added a `wt-guard:` line to the prompt. While the lock is on, the hook denies:

- file writes outside the worktree (the session scratchpad is allowed),
- shell commands whose cwd is outside the worktree, or that name a path in the main checkout,
- `ExitWorktree`, and `EnterWorktree` to any other worktree.

## Arguments

`/wtin [-b <branch> | -l <loose branch>] [task]`. `--branch` is the same as `-b`, and `--loose` is
the same as `-l`. All other text is the task. Never read a worktree name from the task text.

- `-b <branch>`: the worktree with exactly that branch checked out. The hook locks it itself.
- `-l <loose branch>`: the worktree whose branch name matches loosely (step 1). Compare only with
  branch names, not with directory names or paths.
- Neither: the current worktree, if the cwd is in a linked worktree.

```
/wtin -b feat/llm-wt   ->  hook locks the worktree on feat/llm-wt
/wtin -b llm/feat      ->  no worktree on branch llm/feat: tell the user, suggest -l
/wtin -l llm/feat      ->  feat/llm-wt is the only close branch: use it
/wtin -l llm           ->  feat/llm-wt and cc/feat/llm-wt both match: ask the user
```

## Steps

1. Read the `wt-guard:` line.
   - `locked to <root>`: if the cwd is not in `<root>`, call `EnterWorktree` with `path: "<root>"`.
   - `lock pending`, with `-b`: no worktree has that branch. Show `git worktree list`, tell the user,
     and stop.
   - `lock pending`, with `-l`: run `git worktree list` and compare `<loose branch>` with each
     worktree's branch name. Word order, separators and abbreviations can differ. If exactly one
     branch is a clear match, call `EnterWorktree` with its worktree `path`. If none or more than
     one match, show the candidates and ask the user.
   - `lock pending`, with neither: run `git worktree list` and ask the user which worktree to use.
     Then call `EnterWorktree` with its `path`.

   The hook locks the session to the worktree that `EnterWorktree` enters.
2. Do the task inside the worktree. If there is no task, report the locked worktree and stop.

## Rules

- Stay in the worktree. Do not call `ExitWorktree`.
- Do not work around a denial (relative paths, `cd ..`, other tools). If the task needs the main
  checkout or another directory, ask the user to send `/wtout` or `/wtoff`.

Arguments: $ARGUMENTS
