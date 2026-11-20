---
name: wtnew
description: Create a new git worktree and branch, enter it, and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtnew (-b <branch> | -a) [task].
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

- `-b <branch>`: use that branch name as given.
- `-a`: the branch is `cc/<current branch>`. Get the current branch with
  `git branch --show-current` in the session cwd. If it is empty (detached HEAD), ask the user.
- Neither: ask the user for `-b <branch>` or `-a`, and stop.

```
/wtnew -b feat/llm-wt add the pull command   ->  branch feat/llm-wt, task "add the pull command"
/wtnew -a fix the parser                     ->  on feat/llm-wt: branch cc/feat/llm-wt
/wtnew fix the parser                        ->  ask the user
```

If the branch does not exist, create it at the commit the session is on now (step 2).

The worktree directory is the branch name with each `/` replaced by `-`, so all worktrees stay flat
in one directory:

| Branch          | Worktree directory                  |
| --------------- | ----------------------------------- |
| `feat/llm-wt`   | `.claude/worktrees/feat-llm-wt`     |
| `cc/feat/x`     | `.claude/worktrees/cc-feat-x`       |
| `fix-typo`      | `.claude/worktrees/fix-typo`        |

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

Arguments: $ARGUMENTS
