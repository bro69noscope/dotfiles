---
name: new
description: "Create one new git worktree and __llm/-prefixed branch, or one for each item of a list or of Claude's wt-suggest lines, enter it, and stay in them until the user sends /wt:out (one turn) or /wt:off. Usage: /wt:new (-b <branch> | -a | -r | [<repo> <branch>, ...]) [task]."
disable-model-invocation: true
---

# wt:new

`hooks/wt-guard.js` added its result to the prompt as a `wt-guard:` line. With `-b` or `-a`, it
locks to the next worktree the session enters. With a list, it locks to the listed paths, and
denies writes until the `pending` ones exist.

## Arguments

| Option                     | Worktree to create                                                 |
| -------------------------- | ------------------------------------------------------------------ |
| `-b`, `--branch <branch>`  | on `__llm/<branch>`, in the cwd's repository                       |
| `-a`, `--auto`             | on `__llm/<current branch>` (`git branch --show-current`; empty: ask) |
| `-r`, `--reply`            | each `wt-suggest:` item of your last reply                         |
| `[<repo> <branch>, ...]`   | on `__llm/<branch>` in each `<repo>` (any checkout of it)          |
| none                       | ask the user for an option, and stop                               |

- Add the `__llm/` prefix to `<branch>` if it does not have it.
- A list starts the arguments and takes no option. Quote a path with spaces.
- All other text is the task. Never take a branch name from it.

```
/wt:new -b feat/wt add pull   ->  __llm/feat/wt, task "add pull"
/wt:new -a fix the parser     ->  on feat/wt: __llm/feat/wt
/wt:new [C:/work/api feat/x, C:/work/web feat/x] go  ->  __llm/feat/x in api and in web, task "go"
```

The path is `<main>/.claude/worktrees/` and the branch with each `/` replaced by `_`:

| Branch                    | Path below `<main>`                           |
| ------------------------- | --------------------------------------------- |
| `__llm/feat/wt`           | `.claude/worktrees/__llm_feat_wt`             |
| `__llm/fix/llm-wt-reset`  | `.claude/worktrees/__llm_fix_llm-wt-reset`    |

## Create

`<name>` is the branch without `__llm/`. `<repo>` is the item repository, or the session cwd for
`-b` and `-a`. Never use `EnterWorktree` with `name`: it chooses its own branch.

| Branch that exists  | Command                                                      | Starts at        |
| ------------------- | ------------------------------------------------------------ | ---------------- |
| `__llm/<name>`      | `git -C <repo> worktree add <path> __llm/<name>`             | its tip          |
| only `<name>`       | `git -C <repo> worktree add <path> -b __llm/<name> <name>`   | tip of `<name>`  |
| neither             | `git -C <repo> worktree add <path> -b __llm/<name>`          | HEAD of `<repo>` |

If `<path>` exists, or the branch is checked out in another worktree, stop and ask the user.

## Steps

1. Read the `wt-guard:` line. `no lock change`: tell the user the reason. Stop.
2. Create the worktrees (see "Create").
   - `-b`, `-a`: one worktree. `<main>` is the first `worktree` line of
     `git worktree list --porcelain`.
   - List, `-r`: each `pending` path of the `wt-guard:` line, in one shell command before any
     other. After the first one exists, the hook denies a shell cwd outside the locked worktrees.
3. `EnterWorktree` the first new path in the cwd's repository. With `-b` or `-a`, this locks the
   session. For a worktree in another repository, use absolute paths and `git -C <worktree>`.
4. Report what the option did, with its long name: `Created __llm/feat/wt from feat/wt with
   --auto.`
5. Do the task. If there is no task, report the branches and paths and stop.

## Rules

- Stay in the locked worktrees. Do not call `ExitWorktree`.
- Do not work around a denial. If the task needs another worktree, show it on its own line
  `wt-suggest: <repo> <branch>` (absolute `<repo>`). Ask the user to send `/wt:add -r` if it
  exists, or `/wt:new -r` to create it. For another directory, ask for `/wt:out` or `/wt:off`.
- Map paths. If the user names a file in another worktree of a locked repository, edit the same
  relative path in the locked worktree. Do not map if the user asks for the other worktree, after
  `/wt:out`, or after `/wt:off`.

  ```
  locked:  C:/repo/.claude/worktrees/__llm_testing_main
  named:   C:\repo.worktrees\testing_main\lua\explorer.lua
  edit:    C:/repo/.claude/worktrees/__llm_testing_main/lua/explorer.lua
  ```

Arguments: $ARGUMENTS
