---
name: nvim-qf-notes
description: Annotate the code locations relevant to the current question as nvim virtual lines and a quickfix list, by writing a new titled note set .claude-qf-notes/<NNN>.lua in the user's nvim cwd (the main checkout, even from a worktree) for the user to open with `<leader>cn`. Source files are never modified. Use when the user invokes /nvim-qf-notes or asks for code locations or notes in nvim.
---

# nvim-qf-notes

This skill only places an explanation into the nvim UI. It does not decide what the explanation says
or how detailed it is. The prompt that came with `/nvim-qf-notes` (or `$ARGUMENTS` if given) does
that: work out the answer the way that prompt asks, then dispatch its segments onto the code lines
they belong to, in a note set file in the user's nvim cwd. Answer the user's question as usual; the
notes file is an addition. Never edit the source files themselves.

## Note sets

Each run writes a new note set, so the user can go back to the notes of an earlier question. The
sets live in the `.claude-qf-notes/` directory, one file per set, named `<NNN>.lua`: a 3-digit,
zero-padded number one higher than the highest existing one (`001.lua` when there is none). List
the directory before writing. Never overwrite an existing set, except when the user asks to fix or
extend the notes of an earlier run: then rewrite that set's file in place and keep its name.

Give every set a `TITLE`: a short summary of what the notes explain, 3 to 8 words and 60 characters
at most, such as `"merge command main flow"` or `"worktree pull with review flag"`. The user picks
sets by this title, so make it tell the set apart from the others in the directory. It is a
double-quoted Lua string
with no newline.

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

Read the template on every run. Write the note set file as an exact copy of it, replacing only the
`TITLE` string and the entries inside the `local notes = { ... }` table. Do not change any other
line, spacing, or comment of the template. If the template cannot be read, stop and tell the user.
Do not fall back to a remembered copy.

The template is the source of truth for how notes are drawn and how the quickfix list is filled.
When the user asks for a change to that behavior, edit the template first, then regenerate. Never
let a change live only in a generated note set file. Keep any example entry in the template in the
same shape as the entries below.

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
is titled `claude_qf_notes: <TITLE>`, and its context holds the path of the set script that filled
it (`claude_qf_notes_file`). All sets share this one list: it is updated in place when a list with
the `claude_qf_notes` title prefix is still in the quickfix stack, otherwise it is pushed as a new
list, so any other list the user has is kept. It is not opened automatically.

## Related files in the user's nvim config

These live in `C:\Users\ville\myfiles\dotfiles\nvim-config3.0` and depend on the template. Keep
them in sync when the template changes:

- `lua/scripts/ui/claude-qf-notes/navigate.lua`: finds the list by its title prefix, so
  `QFLIST_TITLE` must equal the template's, and reads the shown set from the list context
  (`shown_set()`). It finds the sets in `NOTES_DIR`, sorted by name, and reads `TITLE` from the
  first lines of each set. It tracks the last quickfix step the user jumped to in the global mark
  `N` (declared as `claude_qf_notes_step` in `lua/config/reserved.lua`), and remembers the last
  step of each set it switches away from. It provides `open()`, `cycle()`, `pick()` and `clear()`.
  `open()` shows the newest set when a new one was written since a set was last shown, and
  otherwise the shown set. It runs the set script when the set is not the shown one, the file
  changed since the last run, or the list or virtual lines are gone, and otherwise just makes the
  existing list current and jumps to the step. `cycle()` shows the next or previous set, and
  `pick()` picks a set by title in a snacks picker, where `<c-d>` deletes the selected sets.
  `clear()` hides the virtual lines but keeps the extmarks, so their positions are still tracked,
  and closes the quickfix window. It never deletes the list. It is set up from `init.lua`.
- `lua/scripts/ui/claude-qf-notes/expand-note.lua`: `peek()` reads the virtual lines on the cursor
  line and shows them as real text in a float, wrapped at 100 columns. The template's wrapping width
  should match its own.
- `lua/scripts/ui/claude-qf-notes/sync-lines.lua`: on save of an annotated buffer, writes the rows
  nvim has moved the note extmarks to back into the `line = N,` fields of the shown set file. It
  relies on the template giving each extmark the note's index as its `id`, on `line = N,` sitting
  on a line of its own, and on the `notes` table closing with `}` at column 0.
- `navigate.lua` finds the sets in `NOTES_DIR`, so the generated files must go there. The template
  states the directory in a comment. It reads the title from a line of the form
  `local TITLE = "..."`.
- Both modules declare the extmark namespace as a module-level `NAMESPACE`, and its name must equal
  the template's.
- `lua/config/keymaps.lua`: `<leader>cn` calls `open()`, `<leader>c]` and `<leader>c[` call
  `cycle()`, `<leader>ch` calls `pick()`, `<leader>cs` calls `peek()`, and `<leader>cq` calls
  `clear()`.

If the namespace name, the list title, the directory, the `TITLE` line, the list context key, the
`[n] END(<id>):` convention, or the 100-column width changes in the template, update the files
above in the same change.

## After writing

Tell the user:

- The set file written (for example `.claude-qf-notes/004.lua`) and its title.
- Press `<leader>cn` from nvim started in (or `:cd`'d to) the directory the notes file was written
  to, since paths are relative. Say which directory that is. Because a new set was written, it
  shows that set at its first step. Pressed again later, it only returns to the shown set and its
  last visited step, for example after a detour into other lists.
- `<leader>c[` and `<leader>c]` go to the previous (older) and next (newer) set, and `<leader>ch`
  picks a set by title. Each set opens at the step last visited in it.
- `<leader>cs` shows the note under the cursor as selectable text.
- `<leader>cq` clears the virtual lines and closes the quickfix window. Nothing in the source files
  needs cleaning up, so the git tree stays clean. The list stays in the quickfix stack and the `N`
  mark is kept, so `<leader>cn` still returns to it, redrawing the virtual lines by re-running the
  script.
- `.claude-qf-notes/` holds generated files; they may want to gitignore it.

Finish the reply with the run id as its very last line, on a line of its own, for example
`Notes id: a3`, with nothing after it. Every note shows the id inside START(...):/END(...):, so the
user can confirm the notes in the editor are this run's. Do not put the id in the first line, and do
not add text, a question or a sign-off after it.
