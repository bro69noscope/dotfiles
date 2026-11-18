---
name: wtnew
description: Create a new git worktree on a given branch, enter it, and stay in it until the user sends /wtout (one turn) or /wtoff. Usage: /wtnew <branch> [task].
disable-model-invocation: true
---

# wtnew

The wt-guard hook (`~/myfiles/dotfiles/.claude/hooks/wt-guard.js`) owns the lock. It read this
command and set the lock to pending. The session locks to the next linked worktree it enters. Until
then, the hook denies file writes outside the session scratchpad. After the lock, it also denies:

- shell commands whose cwd is outside the worktree, or that name a path in the main checkout,
- `ExitWorktree`, and `EnterWorktree` to any other worktree.

## Arguments

The first argument is the branch name, for example `feat/llm-wt`. The rest is the task. If there is
no argument, ask the user for the branch name and stop.

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
