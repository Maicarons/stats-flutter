# Data Editor

Excel-like browsing and editing with Data and Variable views.

## Double-click to edit

- **Double-click** a cell to edit
- **Long-press** on touch devices
- **Enter** commit & move down
- **Tab** commit & move right (Shift+Tab left)
- **Esc** cancel

Keyboard navigation: **click** to select a cell (on desktop a click does not start editing), **arrow keys** move the selection, **Enter / F2** edits the selected cell, **Ctrl/Cmd+Z** undoes and **Ctrl/Cmd+Shift+Z** / **Ctrl/Cmd+Y** redoes.

Numeric columns accept digits, minus and decimal point only.

On wide screens (≥600 logical pixels) the **`#` column and the first variable column stay frozen**; horizontal scrolling only moves the remaining columns. Row numbers and the header are always pinned.

## Views

| View | Purpose |
|------|---------|
| Data View | cases × variables matrix, frozen row numbers, sticky header |
| Variable View | type, measure, label, decimals, value labels |

## CSV

- Load demo dataset (30 × 6)
- Import CSV (auto type inference)
- Import Stata `.dta` (117/118/119; numerics / fixed strings / names & labels; strL long strings read as empty)
- Export CSV (share / clipboard)

## Value labels

Configure `value → label` maps in Variable View, then toggle **Show value labels** in the toolbar.
