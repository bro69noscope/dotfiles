---
name: refactor-first
description: Reorder a feat commit and the refactor commit after it so the refactor comes first, on a new branch, so the user can show the feat as unstaged changes on top of the refactored code. Use when the user wants to review new logic with a refactor already applied, or asks to refactor code that the newest feat commit added and wants to review the feat after.
---

# refactor-first

History before: `base ─ F ─ R`. F is the feat commit, R is the refactor commit.
History after, on a new branch `rf/<R short sha>`: `base ─ R' ─ F'`. A second new branch,
`rf/before/<R short sha>`, points to R: a 1:1 backup of the history before the reorder.

- R' is R applied to base only: the refactor without the feat.
- F' has the same tree as R. Only R' needs work. F' never needs conflict resolution.

The skill never changes the user's checkout. The user may edit files while it runs. Because F' has
the same files as R, the user can later move their checkout to R' with a mixed reset. That keeps
all files on disk, so the feat and any edits made since show as unstaged changes.

## Modes

- **Repair:** F and R exist. Do the steps below.
- **Fresh:** the user asks you to refactor code and the newest commit is a feat. Do not edit the
  user's checkout. Make a temporary worktree at F (`git worktree add --detach <tmp>/refactor-new
  F`), write the refactor there, commit it as R, and remove that worktree. Then do the steps
  below. You wrote R, so you know which edits are refactor edits. Use that knowledge in step 4.
- **Again:** the user committed a new refactor on top of F' on a branch from an earlier run. This is
  Repair with F = that F' and R = the new commit.

## Steps

Run git in the cwd, unless the user names a directory. Use the Bash tool: PowerShell changes
`^{tree}` and `@{...}`. After step 1, use full shas, not `HEAD~1`.

1. Find F and R. Default: F = `HEAD~1`, R = `HEAD`. Then check that `git rev-parse R^` equals F,
   and that F has one parent (`git rev-parse F^2` fails). Uncommitted changes in the user's
   checkout do not matter, because the skill does not touch it.
2. Build R' in a temporary worktree. Use the session scratchpad directory, or a temp directory:

   ```
   git worktree add --detach <tmp>/refactor-first F^
   git -C <tmp>/refactor-first cherry-pick R
   ```

   If the cherry-pick has no conflicts, go to step 4. Still do all the checks.
3. Resolve each conflict. In a cherry-pick, `HEAD` (ours) is base and theirs is R.
   - Start from the HEAD side.
   - Apply only R's intent to it: renames, moved code, split or merged functions, comments.
   - Delete all lines that exist only in F. Example: F adds a function and R renames a local in it.
     R' does not contain that function.
   - If R changed code that F moved, apply the change where base has that code. Example: F moved a
     parser into a new function and R refactored the parser. R' refactors the parser in its base
     location.
   - Lines with no conflict can also be wrong. Git applies an R hunk when its context exists in
     base, even if the hunk calls a name that only F adds. Read the full `git diff --cached` in the
     temp worktree, not only the conflict blocks.
   - Then mark the conflicts resolved and continue:

     ```
     git -C <tmp>/refactor-first add -A
     GIT_EDITOR=true git -C <tmp>/refactor-first cherry-pick --continue
     ```

4. Check R'. If a check fails, fix R' (`git commit --amend` in the temp worktree), then do all
   checks again.
   - The changed files load. For Lua, per file:

     ```
     nvim --headless -c "lua assert(loadfile([[<file>]]))" -c q
     ```

     Also check for undefined globals (LuaLS, `luacheck`, or `luac -p -l <file>` and its
     `GETGLOBAL`/`SETGLOBAL` names). For other languages, use the project's build, linter, or
     tests.
   - `git diff F^ R'` contains only refactor changes. It must not add behavior.
   - Make F':

     ```
     git commit-tree "R^{tree}" -p R' -m "$(git log -1 --format=%B F)"
     ```

   - `git range-diff F^..F R'..F'`: the feat patch can change only by R's edits (for example a
     renamed local). A hunk that is new or missing means R' is wrong.
   - `git range-diff F..R F^..R'`: R' can differ from R only where R touched lines that F added.
5. Make the branch `rf/<R short sha>` (7 characters) and its backup `rf/before/<R short sha>`,
   then remove the temp worktree:

   ```
   git branch rf/<R short sha> F'
   git branch rf/before/<R short sha> R
   git worktree remove <tmp>/refactor-first
   ```

   If `rf/<R short sha>` exists, an earlier run reordered the same R. If its F' has R's tree and
   its R' passes step 4, report it and make no new branch. If not, ask the user before you move
   it. If `rf/before/<R short sha>` exists, it must point to R. If not, ask the user before you
   move it.

6. Report to the user:
   - For each conflict: which side you took, what you changed, and why.
   - The result of each check in step 4.
   - The branch names, and the commands below with the real shas and branch names filled in.

## Commands for the user

Take the reordered history as it is, in the user's checkout. F' has the same files as R, so a mixed
reset keeps all files on disk, and edits made since stay. Then push it:

```
git reset rf/<R short sha>
git push --force-with-lease
```

The backup `rf/before/<R short sha>` keeps the old history. To go back: `git reset
rf/before/<R short sha>`.

Or show the feat as unstaged changes on top of R', in the user's checkout. This needs the checkout's
HEAD to still be R (`git rev-parse HEAD`). Files on disk do not change, so edits made since stay.
Staged changes become unstaged.

```
git reset -N <branch>~1
```

This moves the checkout's own branch to R'. `-N` keeps the files that F adds visible in
`git diff` (intent-to-add), not untracked. The old history stays in `rf/before/<R short sha>`.

- To commit the feat on top: `git add -A`, then `git commit -C <F sha>`. This also commits any
  other unstaged edits, so stage only the feat if the user made other edits.
- To go back: `git reset rf/before/<R short sha>`. Files on disk do not change.
- If F was on a remote branch (`git branch -r --contains F`), a push of the reordered branch needs
  `--force-with-lease`.
- To repeat: commit the next refactor on top of F' and run the skill again (mode Again).

## Rules

- Never resolve a conflict by taking the theirs side as it is. The theirs side contains F's code.
- Never change the user's checkout: no reset, switch, stash, or file edit there.
