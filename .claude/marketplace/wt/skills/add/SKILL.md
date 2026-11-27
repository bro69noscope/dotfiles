---
name: add
description: "Add existing git worktrees to the session's worktree lock list, by path, by branch, by [<repo> <branch>] list, or from the wt-suggest lines of Claude's last reply. Usage: /wt:add (-p <path> | -b <branch> | -r | [<repo> <branch>, ...]) [task]."
disable-model-invocation: true
---

# wt:add

The plugin hook `hooks/wt-guard.js` added the worktrees to the lock list. It added its result to the
prompt as a `wt-guard:` line. It adds only worktrees that exist: `/wt:new` creates them.

## Arguments

| Option                     | Worktree                                                    |
| -------------------------- | ----------------------------------------------------------- |
| `-p`, `--path <path>`      | at `<path>`, in any repository                              |
| `-b`, `--branch <branch>`  | on `__llm/<branch>`, in the cwd's repository only           |
| `-r`, `--reply`            | each `wt-suggest:` item of your last reply                  |
| `[<repo> <branch>, ...]`   | on `__llm/<branch>` in each `<repo>` (any checkout of it)   |

- Add the `__llm/` prefix to `<branch>` if it does not have it.
- A list starts the arguments and takes no option. Quote paths with spaces.
- All other text is the task. Never take a worktree name or a path from it.

```
/wt:add -b feat/x                                 ->  __llm/feat/x in the cwd's repository
/wt:add [C:/work/api feat/x, C:/work/web feat/x]  ->  __llm/feat/x in api and in web
/wt:add C:/work/api/.claude/worktrees/__llm_x     ->  refused: use -p
```

## Steps

1. Read the `wt-guard:` line. `no lock change` or `usage:`: tell the user the reason (a missing
   worktree: `/wt:new` creates it). Stop.
2. The `wt-guard:` line shows each worktree as `<path> (<branch>)`. Never check out a branch.

   | `<branch>`                                    | Do                                                       |
   | --------------------------------------------- | -------------------------------------------------------- |
   | fits `<path>`: `__llm/feat/x`, `__llm_feat_x` | Report the branch.                                       |
   | other `__llm/...`                             | Report both names.                                       |
   | detached HEAD                                 | Ask the user before you commit there.                    |
   | not `__llm/`                                  | It is a worktree of the user. Ask before you edit there. |

3. Report what the option did, with its long name: `Added 2 worktrees from my last --reply.`
4. Do the task in the locked worktrees. For one in another repository, use absolute paths and
   `git -C <worktree>`. If there is no task, report the list and stop.

Arguments: $ARGUMENTS
