---
name: in
description: "Lock this session to existing __llm_ git worktrees until the user sends /wt:out (one turn) or /wt:off. Usage: /wt:in [-b <branch> | -s <smart branch> | -p <path> | -r | [<repo> <branch>, ...]] [task]."
disable-model-invocation: true
---

# wt:in

`hooks/wt-guard.js` added its result to the prompt as a `wt-guard:` line.

`/wt:in` replaces the list. `/wt:add` adds to it, `/wt:off -p <path>` removes one, `/wt:list` shows
it. Only `/wt:new` creates worktrees.

## Arguments

| Option                     | Worktree                                                       |
| -------------------------- | -------------------------------------------------------------- |
| `-b`, `--branch <branch>`  | on exactly `__llm/<branch>`, in the cwd's repository           |
| `-s`, `--smart <name>`     | the `__llm/` branch that matches `<name>`, in the cwd's repository |
| `-p`, `--path <path>`      | at `<path>`, in any repository                                 |
| `-r`, `--reply`            | each `wt-suggest:` item of your last reply                     |
| `[<repo> <branch>, ...]`   | on `__llm/<branch>` in each `<repo>` (any checkout of it)      |
| none                       | the current worktree, if it is an `__llm_` one                 |

- Add the `__llm/` prefix to `<branch>` if it does not have it.
- The hook reads `-p`, `-r` and lists. A list starts the arguments and takes no option. Quote a
  path with spaces.
- All other text is the task. Never take a worktree name or a path from it.

```
/wt:in -b feat/wt    ->  __llm/feat/wt
/wt:in -s testing    ->  __llm/testing/main (testing/main has no __llm/ prefix)
/wt:in -s wt         ->  __llm/feat/wt and __llm/fix/llm-wt-reset match: ask the user
/wt:in [C:/work/api feat/x, C:/work/web feat/x] fix it  ->  __llm/feat/x in both, task "fix it"
/wt:in [C:/work/api feat/x] -r                          ->  refused: a list takes no option
```

## Steps

1. Read the `wt-guard:` line.
   - `no lock change`: tell the user the reason. Stop.
   - `locked to:`: if the cwd is not in a listed worktree, `EnterWorktree` the first listed one of
     the cwd's repository. If there is none, tell the user that shell commands are denied until
     the cwd is in a locked worktree.
   - `lock pending`: run `git worktree list` and pick the `__llm_` worktree. `-b`: the exact
     branch. `-s`: the one clear match (word order, separators and abbreviations can differ).
     None, or several matches: show the candidates and ask. `EnterWorktree` it: the hook locks to
     it.
2. Check the branch of each new worktree (see "Check the branch").
3. Report what the option did, with its long name: `Entered __llm/feat/wt with --smart.`
4. Do the task. If there is no task, report the locked worktrees and stop.

## Check the branch

The `wt-guard:` line shows each worktree as `<path> (<branch>)`. Never check out a branch.

| `<branch>`                                    | Do                                                       |
| --------------------------------------------- | -------------------------------------------------------- |
| fits `<path>`: `__llm/feat/x`, `__llm_feat_x` | Report the branch.                                       |
| other `__llm/...`                             | Report both names.                                       |
| detached HEAD                                 | Ask the user before you commit there.                    |
| not `__llm/`                                  | It is a worktree of the user. Ask before you edit there. |

## Rules

- Stay in the locked worktrees. Do not call `ExitWorktree`. For a worktree in another repository,
  do not call `EnterWorktree`: use absolute paths and `git -C <worktree>`.
- Do not work around a denial. If the task needs another worktree, show it on its own line
  `wt-suggest: <repo> <branch>` (absolute `<repo>`). Ask the user to send `/wt:add -r` if it
  exists, or `/wt:new -r` to create it. For another directory, ask for `/wt:out` or `/wt:off`.
- Map paths. If the user names a file in another worktree of a locked repository, edit the same
  relative path in the locked worktree (ask if the repository has more than one). Do not map if
  the user asks for the other worktree, after `/wt:out`, or after `/wt:off`.

  ```
  locked:  C:/repo/.claude/worktrees/__llm_testing_main
  named:   C:\repo.worktrees\testing_main\lua\explorer.lua
  edit:    C:/repo/.claude/worktrees/__llm_testing_main/lua/explorer.lua
  ```

Arguments: $ARGUMENTS
