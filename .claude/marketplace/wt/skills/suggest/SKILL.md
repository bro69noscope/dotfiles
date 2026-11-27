---
name: suggest
description: "Suggest the __llm_ git worktrees that fit the current task, one per repository, and tell the user which /wt command enters, adds or creates them. Usage: /wt:suggest [hint]."
disable-model-invocation: true
---

# wt:suggest

Suggest the worktrees the current task needs. Change nothing. The user acts with a `/wt` command and
`-r`: the wt-guard hook then reads the `wt-suggest:` lines of this reply.

The hint is optional (repositories, branch). Without one, use the task of the conversation. If
there is no task, ask for it and stop.

## Steps

1. Repositories: the ones the task changes, from the conversation, the named paths and the cwd.
   Do not guess. If you are not sure about one, put it in `Notes:`.
2. Branch, without `__llm/`, the same in all repositories: the one the user named, else an
   `__llm/` branch the task continues, else the current branch or a short task name
   (`feat/auth`).
3. In each repository, run `git worktree list` for the `__llm/<branch>` worktree. If the shell is
   locked, use `git -C <locked worktree>`, or `git -C <main checkout>` for an unlocked repository.
4. For each worktree to create, find the start point: `__llm/<branch>`, else `<branch>`, else the
   HEAD of the main checkout. Get `git log -1 --format="%h %s" <start>`.

## Reply

No other prose. In this order:

1. One line that names the task.
2. `wt-suggest: <repo> <branch>` lines, with the absolute path of the main checkout. Nothing else
   on these lines.
3. A table: Repo (directory name), Worktree (relative path), Branch, Do (`create`, `exists`, or
   `exists (on <other branch>)`), From (`create` only: start point, short hash, subject).
4. `Notes:` only for facts that change the decision, one line each. Omit it if there are none.
5. A table of commands: `/wt:new -r` if one or more do not exist. Else `/wt:in -r` (replace the
   list) and `/wt:add -r` (add to it). Last row: `plain text`, to change the set.

If the user asks for changes, reply with the full new set: the hook reads only your last reply.

````
Worktrees for the auth change:

wt-suggest: C:/work/api feat/auth
wt-suggest: C:/work/web feat/auth

| Repo | Worktree                            | Branch            | Do     | From                        |
| ---- | ----------------------------------- | ----------------- | ------ | --------------------------- |
| api  | `.claude/worktrees/__llm_feat_auth` | `__llm/feat/auth` | exists |                             |
| web  | `.claude/worktrees/__llm_feat_auth` | `__llm/feat/auth` | create | `feat/auth` 3f2a91c add jwt |

Notes:
- web: the checkout is on `main`. The new worktree starts from `feat/auth`.
- shared: maybe also C:/work/shared. The task touches its types, but you did not name it.

| Send         | Does                                   |
| ------------ | -------------------------------------- |
| `/wt:new -r` | create 1, lock to 2                    |
| plain text   | change the set, I reply with a new one |
````

Arguments: $ARGUMENTS
