---
name: sbs
description: Explain the last example again, step by step: slower steps, more detail, explicit code shapes, and fewer constructs assumed known. Usage: /sbs [part of the example to focus on].
disable-model-invocation: true
---

# sbs

Step by step. Take the last example that you gave to explain a concept, and explain it again for a
user who does not know the constructs in it.

## Target

- The target is the most recent example in the conversation that explains a concept: a code block,
  a command, or a trace. Usually it is in your last answer.
- If the arguments name a part of the example (a line, a function, a step), explain only that part.
- If the last answer was an earlier `/sbs`, go one level slower on the step the user names. If the
  user names no step, ask which step.
- Keep the same example: the same names, the same values, the same order. Do not change to a
  different example. The user must be able to map each step to the original.

## Scope

- Explain each construct that the example uses: syntax, library calls, idioms, operators, implicit
  conversions, default arguments. Assume the user knows none of them.
- Do not explain constructs that the example does not use. Do not add alternatives, best practices,
  or history.
- If the original example skipped a step (an implicit return, a hidden default, a value that a
  caller passes in), make that step explicit.

## Steps

1. Split the example into the smallest steps that each add one construct or one transformation.
   Inside out for nested calls. Top to bottom for statements.
2. For each step, give:
   - The code fragment for this step only. Name intermediate values that the original example
     inlined.
   - The concrete input and output, with sample values. Show the shape of each value: type, keys,
     length, nesting.
   - One to three sentences: what the construct does. If the construct is new to the explanation,
     add a minimal separate code sample with its output.
3. End with the original example, unchanged, and one line per step that maps the step to the part
   of the example.

Get sample output from a real run when the code is safe to run (use the scratchpad). If you cannot
run it, trace it by hand and say that the values are traced.

## Output format

````
### Step 1: vim.api.nvim_list_bufs()

```lua
local bufs = vim.api.nvim_list_bufs()
-- bufs: { 1, 3, 4 }   list of buffer numbers (integers), one per buffer, listed or not
```

`nvim_list_bufs()` takes no arguments and returns a Lua list. A Lua list is a table with keys
1, 2, 3, ...
````

The detail grows, but filler does not. Keep the caveman and ASD-STE100 rules.

## Example

Original example:

```lua
local fts = vim.tbl_map(function(b) return vim.bo[b].filetype end, vim.api.nvim_list_bufs())
```

`/sbs` gives these steps:

1. `vim.api.nvim_list_bufs()`: returns `{ 1, 3, 4 }`, a list of buffer numbers.
2. `function(b) return vim.bo[b].filetype end`: an anonymous function. Show it with a name and one
   call: `get_ft(3) --> "lua"`.
3. `vim.bo[b]`: buffer-local options of buffer `b`, indexed like a table. Show
   `vim.bo[3].filetype --> "lua"`.
4. `vim.tbl_map(fn, list)`: calls `fn` on each item and returns a new list. Show the expansion:
   `{ get_ft(1), get_ft(3), get_ft(4) } --> { "", "lua", "markdown" }`.
5. The original line, and the map: step 1 is the second argument, steps 2 and 3 are the first
   argument, step 4 is the outer call.

Arguments: $ARGUMENTS
