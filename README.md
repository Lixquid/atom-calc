# Calc

Calculation short-cuts for Atom.

## Commands

### `evaluate`

Evaluates the expression selected and appends it.

*Example*:
`5 + 5 + 5` => `5 + 5 + 5 = 15`

### `replace`

Evaluates the expression selected and replaces it.

*Example*:
`5 + 5 + 5` => `15`

### `count`

For every selection, replace the text with the currently selected index.

## Functions

Some functions not normally available to Javascript are available inside
expressions:

### `Math.pwd`

Generates a random password of a given length.
If not given a length, defaults to 20.

## Extended Variables

Extended Variables provide meaning to some "magic" variable names:

- `_` is replaced with the result of the last expression.
- `_n` (e.g. `_1`, `_2`, etc..) is replaced with the result of the `n`th
  expression.
- `i` is replaced with the number of the current selection.

## Notes

By default, all expressions are surrounded with `with (Math)`, which causes
all `Math` functions to be usable without needing a `Math.` prefix.
