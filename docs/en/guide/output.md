# Output & export

Every analysis run drops a report into the **output tree** on the run page. A procedure can be run repeatedly, all results stay for the session, and reports export in three formats.

## The output tree

- **Each run appends a card**, newest first; the previous run is never overwritten;
- cards default to **newest expanded, the rest collapsed**; click a title or the arrow to expand or collapse — manual state wins, and running again does not pop old cards open;
- the tree lives for **the current session only** (not saved into the project, not carried across launches) — reports can always be re-run, so stale numbers are never read;
- the header shows a **count**, and "Clear output" asks for confirmation before emptying the current procedure's cards;
- each card offers copy, share (plain text), export (PDF / HTML / Markdown) and delete.

## Export

| Format | Notes |
|--------|-------|
| **PDF** | Keeps heading levels, zebra tables, running header and "page x / y"; numeric columns right-aligned, p-value columns starred and coloured; Chinese uses a bundled subset font (`StatsSansSC`, OFL-1.1), so no system font is needed |
| **HTML** | Single file with inline styles — open it in a browser or mail it as is |
| **Markdown** | Plain-text tables, easy to paste into a wiki or commit to a repository |

All three write into the application documents directory and then open the system share sheet. "Export all" in the app bar **merges every card of the current procedure into one file**: each report is preceded by a "title · generated at" divider, in the same order as the output tree (newest first).

## Table styling

Screen, HTML and PDF share one set of rules, so a table looks the same wherever it is read:

- **Numeric columns right-aligned**: recognises `12.5`, `.023`, `<.001`, `≤0.05`, `1.2e-05`, `1,204`, `12.5%`, and ignores the trailing stars a correlation coefficient carries (`0.62 **`);
- **p-value columns**: `p < 0.05` earns stars (`*` / `**` / `***`) and a colour by significance level;
- **Variable and value labels**: tables show a variable's **label** where it has one (falling back to the name), frequencies and crosstabs show **value labels** (for example `1 → Male`), and report notes spell out the "label = variable name" mapping so nothing has to be guessed.
