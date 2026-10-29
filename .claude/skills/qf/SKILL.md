---
name: qf
description: Write relevant code locations for the current question or explanation to qf.txt in the working directory, in a format nvim's `:cfile qf.txt` loads into the quickfix list. Use when the user invokes /qf or asks for code locations in qf.txt.
---

# qf

Collect the code locations relevant to the current topic (or to `$ARGUMENTS` if given) and write them to `qf.txt` in the primary working directory, overwriting any existing file. Answer the user's question as usual; the file is an addition.

## Format

One location per line, exactly:

```
relative/path/to/file.ext:LINE: short description
```

Rules, because nvim's default errorformat is strict:

- Path relative to the working directory, forward slashes.
- A colon directly after the line number, then a space, then the text. Spaces instead of the colon break parsing.
- A single line number. No ranges (`41-46`), no column.
- No title, blank lines, or comments. Every line must be a location.
- Order locations in the order they happen in the flow, not alphabetically.
- Verify each line number against the file before writing. Never guess.

## After writing

Tell the user to run `:cfile qf.txt` from nvim started in (or `:cd`'d to) the working directory, since paths are relative.
