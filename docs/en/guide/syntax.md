# Syntax language

Open the syntax editor from the Data menu (**Data → "Syntax editor…"**). It runs an executable subset of PSPP syntax: commands end with a period, the output panel lists one result per command, and failures are labelled with a line number you can click to jump back to the source.

This page covers the language layer added in v1.5.0 (comments, macros, `INCLUDE`, error locations, `.sps` round-trip); the list of executable commands lives in [Transforms](/en/guide/transforms).

## Comments

Following PSPP, a comment introduced by `*` or `COMMENT` is **not "the rest of this line"** — it runs to the next end-of-line period or to a blank line:

```text
* Some explanation.
COMPUTE x = score + 1.
```

The comment above ends at its period, so `COMPUTE` still runs. Details:

- Only an **end-of-line** period closes the comment: `* see the v1.2.0 notes (inner periods do not close it).` is one comment in full;
- `COMMENT` is equivalent to `*` and may span several lines, again ending at an end-of-line period;
- a blank line also ends a comment;
- an inline `/* … */` is stripped and does not disturb the arguments: `COMPUTE x = score /* add one */ + 1.`;
- a line holding nothing but `/* … */` **ends the current command**, as in PSPP:

```text
COMPUTE x = score + 1
/* this command has no period yet; end it here */
LIST.
```

- when a comment swallows following commands (usually a missing period) the editor shows a **hint** instead of silently dropping commands:

```text
* missing period
LIST.
```

## Macros

```text
DEFINE !show(vars=!DEFAULT(pre) !TOKENS(1))
DESCRIPTIVES !vars.
!ENDDEFINE.

!show vars=post.
!show.
```

- **Arguments**: positional (`!POSITIONAL`, referenced as `!1`, `!2`, …) and keyword arguments, read with `!TOKENS(n)`, `!CHAREND('/')` or `!CMDEND`, plus defaults via `!DEFAULT(value)`; the two kinds may be mixed;
- **Calls**: `!show vars=post.` (PSPP style) or `!sum2(pre, post).` (parenthesised, for SPSS habits);
- **Macro functions**: `!CONCAT` `!QUOTE` `!UNQUOTE` `!UPCASE` `!LENGTH` `!SUBSTR` `!HEAD` `!TAIL` `!INDEX` `!EVAL` `!BLANKS` `!NULL`; macro calls inside arguments expand first (`!CONCAT(!a, _2)`);
- **Flow control**: `!LET` for local variables, `!IF` / `!THEN` / `!ELSE` / `!ENDIF`, and `!DO` / `!TO` / `!BY` / `!DOEND` loops, nestable;
- self-recursion has a depth limit; redefining a macro with `DEFINE` replaces the old one; `DEFINE` inside a comment is not registered.

Constructs this version does **not** implement report "unsupported" instead of being ignored: `!DO !v !IN (…)`, `!ENCLOSE`, `!NOEXPAND` / `!OFFEXPAND` / `!ONEXPAND`.

## INCLUDE

```text
INCLUDE 'common.sps'.
INCLUDE FILE='common.sps' ENCODING='UTF-8'.
```

- the included file is injected into the current script and run with it, and the **macro table carries over**: a `DEFINE` in an included file applies to later commands;
- relative paths resolve against the **directory of the current `.sps` file**, not the launch directory;
- circular includes are an error; nesting is capped at 16 levels;
- an error inside an included file stops the remaining commands (PSPP semantics: an error in an included file aborts the whole script);
- output labels commands from that file with its name and line number, and clicking jumps back.

## Error locations

- every command carries a start and end position; failures are labelled "line N" and clicking moves the caret to that line;
- commands produced by macro expansion trace back to their original position (expansion does not lose line/column information);
- cases that are suspicious but not errors — a comment swallowing commands, for instance — are reported as hints, distinct from failures.

## `.sps` round-trip

- **Open**: a UTF-8 BOM is stripped first; invalid bytes are replaced with U+FFFD and the number of replacements is reported rather than silently discarded;
- **Save** overwrites the current file, **Save as** picks a new path; files are written as UTF-8 without a BOM, so PSPP reads them directly;
- the editor has a command template bar at the top for inserting commands, and "Attach dataset" adds another `.sav` or project file (see [Transforms](/en/guide/transforms)).
