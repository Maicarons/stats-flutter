# Transforms

Entry: **project workspace → Transforms**, or the Data menu item "Transform…".
Transforms act directly on the current dataset.

## Commands

| Command | Purpose |
|---------|---------|
| **COMPUTE** | new variable from an expression (`+ - * /`, abs, sqrt, ln, exp, log10, sin, cos, tan, round, trunc) |
| **RECODE** | map old values to new ones |
| **AUTORECODE** | encode values (numeric or string) into 1..k codes with value labels |
| **COUNT** | count matching cells per case |
| **RANK** | rank-derived variables: rank, percentile, normal score, n-tiles |
| **SAMPLE** | draw cases randomly (by fraction, or exactly "n FROM N") |
| **SORT CASES** | sort by one or more keys |
| **SELECT IF** | filter cases (`>` `<` `==` `!=` `&&` `||`) |
| **AGGREGATE** | grouped means |
| **FLIP** | transpose |
| **COMBINE FILES** | append cases (ADD FILES) or match by key (MATCH FILES) from another dataset |

## RANK: rank-derived variables

```text
RANK VARIABLES=score (A) /RANK /TIES=MEAN.
RANK VARIABLES=score (D) /NTILES(4) /INTO=quartile.
```

- `(A)` / `(D)` after a variable selects ascending / descending order, ascending by default;
- output functions may be combined:

  | Option | Meaning |
  |--------|---------|
  | `/RANK` | rank |
  | `/N` | number of cases in the tie group |
  | `/RFRACTION` | rank / number of valid cases |
  | `/PROPORTION` | Blom proportion `(r − 3/8) / (w + 1/4)` |
  | `/PERCENT` | percentile `r · 100 / w` |
  | `/NORMAL` | normal score Φ⁻¹ of the proportion |
  | `/NTILES(k)` | n-tile group 1..k |

- `/TIES=MEAN|LOW|HIGH|CONDENSE` decides the rank of tied values (average / lowest / highest / condensed); the default `MEAN` is the familiar average rank;
- `/INTO=name` names the target variable; the default derives it from the function (`R_` / `N_` / `RF_` / `PR_` / `P_` / `Z_` / `NT_` prefix);
- missing cases (including user-missing values) do not participate and get an empty result.

## AUTORECODE: one code for strings and numbers alike

```text
AUTORECODE VARIABLES=city /INTO=city_n.
AUTORECODE VARIABLES=a b c /INTO=x y z /GROUP /DESCENDING.
```

- each source variable has its distinct non-blank values numbered 1..k in ascending order (`/DESCENDING` reverses it), with value labels filled in automatically (an existing value label wins over the displayed text);
- **user-missing values are still encoded, but always come last** (they take the highest codes) and are marked missing on the target variable; with more than three such codes the target switches to a **missing range**, as PSPP does;
- `/GROUP` shares one coding table across all source variables (they must have the same type);
- target variables are integers on a nominal scale and inherit the variable label.

## SAMPLE: drawing cases

```text
SAMPLE 0.5.            * keep each case with probability 50% (count varies)
SAMPLE 5 FROM 10.      * keep exactly 5 of the first 10 cases
SAMPLE 0.5 /SEED=42.   * fix the seed so a run is reproducible
```

## MRSETS: multiple response sets

```text
MRSETS /MDGROUP NAME=$brands LABEL='Brands bought' VARIABLES=q1a q1b q1c VALUE=1.
MRSETS /MCGROUP NAME=$colors VARIABLES=c1 c2 c3.
MRSETS /DISPLAY NAME=ALL.
MRSETS /FREQUENCIES NAME=$brands.
MRSETS /CROSSTABS NAME=$brands BY=gender.
```

- `MDGROUP` (multiple dichotomy): `VALUE=` decides whether a variable counts as "selected";
- `MCGROUP` (multiple category): every value of the listed variables is itself a response;
- once defined, `/DISPLAY` lists the sets, `/FREQUENCIES` reports response counts and `/CROSSTABS ... BY=group` crosstabulates responses by a group (PSPP builds these tables with CTABLES; the two extensions here are app-specific);
- response tables report both denominators, responses and cases with a response; counts are unweighted (see [missing values](/en/guide/missing-values) for the weighting rules);
- `/DELETE NAME=$m|ALL` removes a set; redefining a name overwrites it (as PSPP `dict_add_mrset` does).

## COMBINE FILES: merging datasets

```text
ADD FILES /FILE=* /FILE=other /IN=source.
MATCH FILES /FILE=* /TABLE=lookup /BY id.
```

- `ADD FILES` appends the cases of the second dataset (variables are aligned by name, missing ones are filled with blanks);
- `MATCH FILES` matches the second dataset in by the `/BY` key with a hash join (input need not be sorted);
- `/IN=var` adds a 0/1 source indicator; `/KEEP`, `/DROP` and `/RENAME=(old=new)` adjust the variables;
- dictionaries are merged with PSPP's `merge_dictionaries` rules: the first file that defines a variable wins, later files only fill gaps, string width takes the maximum and a type conflict is an error; with `MATCH FILES` a duplicate key keeps the first case;
- "Attach dataset" in the syntax editor adds another `.sav` or project file, and `*` stands for the current dataset; the Data menu also offers a dialog-driven "Merge datasets…".

## SAVE: write an SPSS system file (.sav)

```text
SAVE OUTFILE='results.sav' [FILELABEL='label'].
```

- Writes the current dataset as an **uncompressed `.sav` system file**
  (`$FL2`, UTF-8) that PSPP / SPSS open directly;
- variable names longer than 8 characters go into a long-names record
  (7/13); numeric / string variables, variable labels, numeric value
  labels and discrete & range missing values are all written back;
- relative paths resolve against the directory of the current `.sps`
  file;
- the Data menu's "Export data" also offers a graphical `.sav` export
  (written to the app documents directory, shareable).

## Program flow: DO IF / LOOP / VECTOR (v1.7.0)

```text
DO IF score >= 85.
COMPUTE grade = 1.
ELSE IF score >= 70.
COMPUTE grade = 2.
ELSE.
COMPUTE grade = 3.
END IF.

LOOP #i = 1 TO 10 BY 2.
COMPUTE acc = acc + #i.
END LOOP.

LOOP IF k < 100.
COMPUTE k = k + 7.
BREAK IF k >= 50.
END LOOP.

VECTOR v = x1 TO x10.
COMPUTE total = v(1) + v(2).
```

- **DO IF / ELSE IF / ELSE / END IF**: conditions are evaluated **per
  case**; every case takes the first branch whose condition holds;
  comparisons `< > <= >= = ~= !=` and `AND OR NOT` (case-insensitive)
  are supported;
- **LOOP / END LOOP**: `LOOP var = from TO to [BY step]` (inclusive) and
  `LOOP IF cond`; `BREAK [IF cond]` exits early; `END LOOP [IF cond]`
  terminates conditionally; the loop variable (e.g. `#i`) is referenceable
  in the body; iteration cap 10000 (infinite-loop guard);
- **VECTOR**: `VECTOR name = first TO last.` registers a run of numbered
  variables as a vector, or `VECTOR name(k).` (refers to name1…namek,
  creating missing ones); refer with `name(index)`, 1-based;
- only COMPUTE and RECODE are allowed inside blocks; `INCLUDE` cannot
  appear inside a block;
- a bare `LOOP.` must end via `BREAK`.

## SPLIT FILE: repeat analyses per group

```text
SPLIT FILE BY gender.
DESCRIPTIVES post.
SPLIT FILE OFF.
```

- after `SPLIT FILE BY vars…`, analyses run **once per combination of
  the split variables**; each group produces its own report card titled
  with the group label (e.g. `gender = Male`, honouring value labels);
- multiple split variables group by value combinations; an error inside
  one group does not stop the others;
- `SPLIT FILE OFF.` clears the split; the Data menu's "Split file…" is
  the graphical entry to the same state.

## Syntax editor

A syntax subset runner is available from the Data menu:

```text
DESCRIPTIVES pre post.
FREQUENCIES gender method.
T-TEST /TESTVAL=60 /VARIABLES=post.
CORRELATIONS /VARIABLES=pre post.
COMPUTE gain = post - pre.
RECODE gender (1=0) (2=1) INTO sex.
AUTORECODE VARIABLES=city /INTO=city_n.
RANK VARIABLES=post (A) /RANK /NTILES(4).
SAMPLE 0.5 /SEED=20261016.
SAVE OUTFILE='results.sav'.
SPLIT FILE BY gender.
DO IF gender = 1.
COMPUTE bonus = 10.
ELSE.
COMPUTE bonus = 20.
END IF.
LOOP #i = 1 TO 4.
COMPUTE acc = acc + #i.
END LOOP.
MRSETS /MDGROUP NAME=$m VARIABLES=a b VALUE=1.
ADD FILES /FILE=* /FILE=other.
MATCH FILES /FILE=* /TABLE=lookup /BY id.
SORT CASES BY post DESCENDING.
SELECT IF post >= 70.
LIST.
HELP.
```

The template bar above the editor inserts a command; the output pane reports each command. A whole line starting with `*` is a comment.

Comment semantics, macros, `INCLUDE`, error locations and the `.sps` round-trip are covered in [Syntax language](/en/guide/syntax).

## Other data operations

The Data menu also offers:

- **Weight cases** (WEIGHT CASES)
- **Split file** (SPLIT FILE — analyses repeat per group, see above)
- **Find cases**
- CSV import / export, **SPSS `.sav` export** (uncompressed system file, readable by PSPP / SPSS)
