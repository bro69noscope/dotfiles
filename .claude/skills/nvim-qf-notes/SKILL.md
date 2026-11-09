---
name: nvim-qf-notes
description: Annotate the code locations relevant to the current question as nvim virtual lines and a quickfix list, by writing .claude-qf-notes.lua in the user's nvim cwd (the main checkout, even from a worktree) for the user to run with `:luafile .claude-qf-notes.lua`. Source files are never modified. Use when the user invokes /nvim-qf-notes or asks for code locations or notes in nvim.
---

# nvim-qf-notes

This skill only places an explanation into the nvim UI. It does not decide what the explanation says
or how detailed it is. The prompt that came with `/nvim-qf-notes` (or `$ARGUMENTS` if given) does
that: work out the answer the way that prompt asks, then dispatch its segments onto the code lines
they belong to, in `.claude-qf-notes.lua` in the user's nvim cwd, overwriting any existing one.
Answer the user's question as usual; the notes file is an addition. Never edit the source files
themselves.

## Where the notes file goes

Write it where the user's nvim runs, not where Claude happens to be working. Claude cannot see
nvim's cwd, so use the main checkout: the first entry of `git worktree list --porcelain`, run from
the primary working directory. This holds even when the session is isolated in a linked worktree
(for example `.claude/worktrees/<name>`), so never write the file into the worktree. If the prompt
names another directory, or the user says nvim runs elsewhere, use that instead.

If the location is ambiguous, ask before writing instead of guessing. Ambiguous means, for
example: the annotated file lives in a different repo or checkout than the main one (such as
`rev5` versus `nvim-config3.0`), several checkouts hold the file and the prompt does not say which,
or the user has mentioned running nvim from somewhere else earlier in the conversation. Use
AskUserQuestion with the candidate directories as options. When the answer is clear from the
prompt, do not ask.

`file` paths are relative to that directory. A file inside a linked worktree is therefore written
as `.claude/worktrees/<name>/lua/...`, and `line` comes from reading that actual file. If the
annotated file exists in both main and a worktree, annotate the one the prompt names.

## Template

The script is generated from the user's template, so every run starts from the same base:

`C:\Users\ville\myfiles\dotfiles\nvim-config3.0\scripts\templates-for-ai-gen\claude-qf-notes.lua`

Read the template on every run. Write `.claude-qf-notes.lua` as an exact copy of it, replacing only
the entries inside the `local notes = { ... }` table. Do not change any other line, spacing, or
comment of the template. If the template cannot be read, stop and tell the user. Do not fall back
to a remembered copy.

The template is the source of truth for how notes are drawn and how the quickfix list is filled.
When the user asks for a change to that behavior, edit the template first, then regenerate. Never
let a change live only in a generated `.claude-qf-notes.lua`. Keep any example entry in the template
in the same shape as the entries below.

## Notes

Each location is one or two notes: a start note on the first relevant line and, when the relevant
code spans more than one line, an end note on the last relevant line. Write each note in the
multi-line shape the template uses, with a trailing comma after every field and every entry:

```lua
  {
    file = "relative/path/to/file.ext",
    line = 39,
    text = "[1] START(a3): what this code does and why it matters",
  },
```

- `file`: path relative to the notes file's directory (see above), forward slashes.
- `line`: 1-based line of the real code. Read the file or grep for it before writing. Never guess.
  There are no markers in the source, so there is nothing to shift the numbers.
- `text`: the part of the answer that belongs to this line, as terse or as in depth as the prompt
  calls for. The start note covers the code from this line on, the end note closes it, for example
  what it hands off to. Do not shorten or pad it for the sake of the skill.
- Start every text with `[n]`, where n is the step number of the location in the flow, and
  use the same n for its start and end note. The run id, described below, goes in the parentheses.
  The template decides above or below from the `[n] END(<id>):` prefix, so keep that prefix exact.
  Start notes begin `[n] START(<id>):`. A note that has a single line and no start/end pair still
  begins `[n] START(<id>):`.
- Run id: pick 2 random lowercase hex characters (`0-9a-f`) once per run, different from the id of
  the previous run, and use that same id in every note of the file. It is how the user checks that
  the notes in the editor are the ones Claude is talking about.
- Order the notes in the order they happen in the flow, not alphabetically, with the end note
  directly after its start note.
- Lua string rules: use double-quoted strings, escape `\` and `"` inside text, and put no newline
  in text.
- The template wraps long text over several virtual lines at 100 columns, so `text` stays one
  string with no newline, however long it is.
- Files that cannot be annotated (binary) are skipped. Mention them in the reply.

## What the template does

Each note is drawn as a virtual line of its own, never inline with code: start notes above their
line, end notes below it, indented to match the line, and word-wrapped at 100 columns (indent
included) onto as many virtual lines as needed, in the `DiagnosticVirtualTextHint` highlight. They
live in the extmark namespace `claude_qf_notes`.

Every note, start and end, also becomes a quickfix entry, in the same order, so `:cnext` and
`:cprev` walk the flow and the `[n] START(<id>):`/`[n] END(<id>):` text shows in the list. The list
is titled `claude_qf_notes`. It is updated in place when it is still in the quickfix stack,
otherwise it is pushed as a new list, so any other list the user has is kept. It is not opened
automatically.

## Related files in the user's nvim config

These live in `C:\Users\ville\myfiles\dotfiles\nvim-config3.0` and depend on the template. Keep
them in sync when the template changes:

- `lua/scripts/ui/claude-qf-notes/navigate.lua`: finds the list by its title, so `QFLIST_TITLE` must
  equal the template's. It tracks the last quickfix step the user jumped to in the global mark `N`
  (declared as `claude_qf_notes_step` in `lua/config/reserved.lua`), and provides `open()` and
  `clear()`. `open()` regenerates the notes by running `.claude-qf-notes.lua` when the file changed
  since the last run or the list or virtual lines are gone, and otherwise just makes the existing
  list current and jumps to the step. `clear()` removes the virtual lines by namespace and closes
  the quickfix window. It never deletes the list. It is set up from `init.lua`.
- `lua/scripts/ui/claude-qf-notes/expand-note.lua`: `peek()` reads the virtual lines on the cursor
  line and shows them as real text in a float, wrapped at 100 columns. The template's wrapping width
  should match its own.
- `navigate.lua` runs the script by its filename, `NOTES_FILE`, so the generated file name must
  equal it. The template states the name in a comment.
- Both modules declare the extmark namespace as a module-level `NAMESPACE`, and its name must equal
  the template's.
- `lua/config/keymaps.lua`: `<leader>cn` calls `open()`, `<leader>cs` calls `peek()`, and
  `<leader>cq` calls `clear()`.

If the namespace name, the list title, the file name, the `[n] END(<id>):` convention, or the
100-column width changes in the template, update the files above in the same change.

## After writing

Tell the user:

- Press `<leader>cn` from nvim started in (or `:cd`'d to) the directory the notes file was written
  to, since paths are relative. Say which directory that is. Because the file was just rewritten, it
  runs `.claude-qf-notes.lua` and opens the list at the last step they visited if it is still in the
  new list, otherwise at the first one. Pressed again later with the file unchanged, it only returns
  to the notes list and the last step, for example after a detour into other lists. `:luafile
  .claude-qf-notes.lua` alone redraws the notes and refills the list.
- `<leader>cs` shows the note under the cursor as selectable text.
- `<leader>cq` clears the virtual lines and closes the quickfix window. Nothing in the source files
  needs cleaning up, so the git tree stays clean. The list stays in the quickfix stack and the `N`
  mark is kept, so `<leader>cn` still returns to it, redrawing the virtual lines by re-running the
  script.
- `.claude-qf-notes.lua` is a generated file; they may want to gitignore it.

Finish the reply with the run id as its very last line, on a line of its own, for example
`Notes id: a3`, with nothing after it. Every note shows the id inside START(...):/END(...):, so the
user can confirm the notes in the editor are this run's. Do not put the id in the first line, and do
not add text, a question or a sign-off after it.
