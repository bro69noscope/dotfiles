---
name: wtin
description: Lock this session to an existing __llm_ git worktree and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtin [-b <branch> | -l <loose branch>] [task].
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

`/wtin` always leads to an `__llm_` worktree: a directory `.claude/worktrees/__llm_<name>` on a
branch `__llm/<...>` (see `/wtnew`). The directory name is the branch name with each `/` replaced
by `_`. Each `-` stays as it is. Ignore all other worktrees as candidates.

- `-b <branch>`: the worktree with exactly the branch `__llm/<branch>` checked out. If `<branch>`
  already starts with `__llm/`, do not add the prefix again.
- `-l <loose branch>`: the `__llm_` worktree whose branch name matches loosely (step 1). Compare
  only with branch names, not with directory names or paths.
- Neither: the current worktree, if the cwd is in an `__llm_` worktree.

```
/wtin -b feat/wt         ->  worktree .claude/worktrees/__llm_feat_wt on __llm/feat/wt
/wtin -b __llm/feat/wt   ->  the same worktree
/wtin -b __llm/feat      ->  no worktree on branch __llm/feat: tell the user, suggest -l
/wtin -l testing         ->  __llm/testing/main matches, testing/main is not __llm_: use __llm/testing/main
/wtin -l wt              ->  __llm/feat/wt and __llm/fix/llm-wt-reset both match: ask the user
```

## Steps

1. Read the `wt-guard:` line.
   - `locked to <root>`: if the cwd is not in `<root>`, call `EnterWorktree` with `path: "<root>"`.
   - `lock pending`, with `-b`: run `git worktree list`. If an `__llm_` worktree has the branch
     `__llm/<branch>`, call `EnterWorktree` with its `path`. Otherwise show the list, tell the
     user, and stop.
   - `lock pending`, with `-l`: run `git worktree list` and compare `<loose branch>` with the
     branch name of each `__llm_` worktree. Word order, separators and abbreviations can differ.
     If exactly one branch is a clear match, call `EnterWorktree` with its worktree `path`. If none
     or more than one match, show the candidates and ask the user.
   - `lock pending`, with neither: run `git worktree list` and ask the user which `__llm_` worktree
     to use. Then call `EnterWorktree` with its `path`.

   The hook locks the session to the worktree that `EnterWorktree` enters.
2. Do the task inside the worktree. If there is no task, report the locked worktree and stop.

## Rules

- Stay in the worktree. Do not call `ExitWorktree`.
- Do not work around a denial (relative paths, `cd ..`, other tools). If the task needs the main
  checkout or another directory, ask the user to send `/wtout` or `/wtoff`.
- Map paths to the locked worktree. If the user names a path in another worktree of the same
  repository (the main checkout or any entry of `git worktree list`), read and edit the same
  relative path in the locked worktree. Do not map the path if the user explicitly asks for the
  other worktree, if the prompt starts with `/wtout`, or after the user sent `/wtoff`.

  ```
  locked worktree:  C:/Users/ville/myfiles/dotfiles/nvim-config3.0/.claude/worktrees/__llm_testing_main
  user names:       C:\Users\ville\myfiles\dotfiles\nvim-config3.0.worktrees\testing_main\lua\modules\snacks\picker\explorer\explorer-config.lua
  edit:             C:/Users/ville/myfiles/dotfiles/nvim-config3.0/.claude/worktrees/__llm_testing_main/lua/modules/snacks/picker/explorer/explorer-config.lua
  ```

Arguments: $ARGUMENTS
