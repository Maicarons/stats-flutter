# Transforms

Transform menu inside the **project workspace**.

## Commands

| Command | Purpose |
|---------|---------|
| **COMPUTE** | new variable from expression |
| **RECODE** | map old values to new |
| **COUNT** | count matching cells |
| **RANK** | rank variable |
| **SORT CASES** | sort by one or more keys |
| **SELECT IF** | filter cases |
| **AGGREGATE** | group means |
| **FLIP** | transpose |

## Syntax editor

A syntax subset runner is available from the Data menu:

```text
DESCRIPTIVES pre post.
T-TEST /TESTVAL=60 /VARIABLES=post.
COMPUTE gain = post - pre.
SORT CASES BY post DESCENDING.
SELECT IF post >= 70.
LIST.
HELP.
```

Also: WEIGHT CASES, SPLIT FILE, find cases, CSV import/export.
