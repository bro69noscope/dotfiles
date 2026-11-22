---
name: wtnew
description: Create a new git worktree and llm/-prefixed branch, enter it, and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtnew (-b <branch> | -a) [task].
disable-model-invocation: true
---

# wtnew

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) owns the lock. It read this
command and set the lock to pending. The session locks to the next linked worktree it enters. Until
then, the hook denies file writes outside the session scratchpad. After the lock, it also denies:

- shell commands whose cwd is outside the worktree, or that name a path in the main checkout,
- `ExitWorktree`, and `EnterWorktree` to any other worktree.

## Arguments

`/wtnew (-b <branch> | -a) [task]`. `--branch <branch>` is the same as `-b <branch>`, and `--auto`
is the same as `-a`. The option can come anywhere in the arguments. All other text is the task.
Never read a branch name from the task text.

Every branch gets the `llm/` prefix.

- `-b <branch>`: the branch is `llm/<branch>`.
- `-a`: the branch is `llm/<current branch>`. Get the current branch with
  `git branch --show-current` in the session cwd. If it is empty (detached HEAD), ask the user.
- Neither: ask the user for `-b <branch>` or `-a`, and stop.

```
/wtnew -b feat/wt add the pull command   ->  branch llm/feat/wt, task "add the pull command"
/wtnew -b llm/feat/wt                    ->  branch llm/feat/wt
/wtnew -a fix the parser                 ->  on feat/wt: branch llm/feat/wt
/wtnew fix the parser                    ->  ask the user
```

If the branch does not exist, create it at the commit the session is on now (step 2).

The worktree directory is the branch name with each `/` replaced by `_`. Each `-` stays as it is.
Thus every worktree directory starts with `llm_`, and all worktrees stay flat in one directory:

| Branch                    | Worktree directory                            |
| ------------------------- | --------------------------------------------- |
| `llm/feat/wt`             | `.claude/worktrees/llm_feat_wt`               |
| `llm/fix-typo`            | `.claude/worktrees/llm_fix-typo`              |
| `llm/fix/llm-wt-reset`    | `.claude/worktrees/llm_fix_llm-wt-reset`      |

## Steps

1. Find the main checkout: the first `worktree` line of `git worktree list --porcelain`.
2. Create the worktree. Do not use `EnterWorktree` with `name`: it chooses its own branch name.
   Run git in the session cwd, so a new branch starts from the HEAD the session is on.
   - If the branch does not exist (`git rev-parse --verify --quiet refs/heads/<branch>` fails),
     create it:

     ```
     git worktree add <main>/.claude/worktrees/<directory> -b <branch>
     ```

   - If the branch exists, check it out:

     ```
     git worktree add <main>/.claude/worktrees/<directory> <branch>
     ```

   - If `.claude/worktrees/<directory>` exists, or the branch is checked out in another worktree,
     stop and ask the user.
3. Call `EnterWorktree` with `path: "<main>/.claude/worktrees/<directory>"`. The session locks to it.
4. Do the task inside the new worktree. If there is no task, report the branch and the worktree path
   and stop.

## Rules

- Stay in the worktree. Do not call `ExitWorktree`.
- Do not work around a denial (relative paths, `cd ..`, other tools). If the task needs the main
  checkout or another directory, ask the user to send `/wtout` or `/wtoff`.
- Map paths to the locked worktree. If the user names a path in another worktree of the same
  repository (the main checkout or any entry of `git worktree list`), read and edit the same
  relative path in the locked worktree. Do not map the path if the user explicitly asks for the
  other worktree, if the prompt starts with `/wtout`, or after the user sent `/wtoff`.

  ```
  locked worktree:  C:/Users/ville/myfiles/dotfiles/nvim-config3.0/.claude/worktrees/llm_testing_main
  user names:       C:\Users\ville\myfiles\dotfiles\nvim-config3.0.worktrees\testing_main\lua\modules\snacks\picker\explorer\explorer-config.lua
  edit:             C:/Users/ville/myfiles/dotfiles/nvim-config3.0/.claude/worktrees/llm_testing_main/lua/modules/snacks/picker/explorer/explorer-config.lua
  ```

Arguments: $ARGUMENTS
