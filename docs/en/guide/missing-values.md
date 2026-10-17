# Missing values

When a procedure reads data, "missing" covers two things:

- **system-missing**: an empty cell (`.` / never entered);
- **user-missing values**: values declared on a variable with `MISSING VALUES` (`-1`, `99`, `999`, or a range such as `11 THRU 14`).

Both are treated as missing by **every procedure**. This page states each rule, so one dataset cannot end up with contradictory Ns across procedures.

## The five rules

| Rule | Content |
|------|---------|
| **A** | A single-variable procedure looks at that variable alone: its system-missing and user-missing values are both invalid. |
| **B** | Multi-variable procedures align variables **case by case**. Correlations use **pairwise deletion**, the PSPP / SPSS default (each pair drops its own missing cases); procedures that need complete cases (paired t-test, paired permutation, simple regression, K-means, reliability, factor analysis) use **row-wise deletion**, keeping only cases valid on every variable involved. |
| **C** | Weighted statistics require **both the value and the weight to be valid**; either one missing drops the case. |
| **D** | With a grouping variable, cases missing on **the grouping variable or the analysis variable enter no group** (a user-missing value of the grouping variable is not a group of its own); group labels use the displayed value, value labels first. |
| **E** | Categorical procedures (frequencies, crosstabs, `FREQUENCIES`, bar charts) count user-missing values as a **missing** category rather than a value; crosstab rows and columns exclude them. |

## Procedure by procedure

| Procedure | Rule |
|-----------|------|
| Descriptives, frequencies, histogram, box plot, error bar, Q-Q plot | A |
| One-sample t-test, normality test, ROC | A |
| Independent-samples t-test, one-way / two-way ANOVA, ANCOVA, Kruskal-Wallis, ordered-alternative trend, two-sample permutation test | D (missing on the grouping or the analysis variable both drop the case) + A |
| Paired t-test, Wilcoxon signed rank, paired permutation | B (complete pairs) |
| Pearson / Spearman correlation, partial correlation | B (pairwise) |
| Simple / multiple / stepwise regression, logistic regression, factor analysis, K-means, reliability | B (row-wise) |
| Weighted descriptives and other weighted procedures | C |
| Frequencies, crosstabs, CTABLES, bar charts | E |
| Multiple response sets (MRSETS `/FREQUENCIES`, `/CROSSTABS`) | A + E: a variable is tested for "selected" on its own, counts are unweighted, and "cases with a response" counts cases with at least one valid response |

> The **raw** cell values (user-missing ones included) stay in the dataset: the data editor, exports and "find cases" show them, and only procedures apply the rules above. `Dataset.rawColumn` returns raw values, `Dataset.numericColumn` returns the analysis values with user-missing values blanked out.

## Difference from PSPP

PSPP also excludes user-missing values by default but offers a per-procedure `MISSING=INCLUDE` switch that treats them as ordinary values. This app **always excludes** them and does not offer the switch: one consistent rule is harder to misread. To really use `99` as a value, `RECODE` it first (or drop the `MISSING VALUES` declaration).

Everything else follows PSPP 2.1.2, and `test/pspp_parity_test.dart` checks it against expectations shipped with PSPP itself (AUTORECODE, RANK, ONEWAY, pairwise CORRELATIONS, NPAR TESTS Mann-Whitney) on every CI run.

## Two statistical conventions fixed in v1.4.0

The review and the parity work turned up one alignment defect and two convention mismatches — all of the "the numbers do not match the textbook / PSPP" kind:

1. **Case misalignment (defect)**: some multi-variable procedures filtered each column separately and then truncated by position, which **misaligned** the variables (a case valid on `pre` but missing on `post` shifted the two columns by one). All procedures now read case-aligned data per the table above, with regression tests.
2. **Levene's test** now centres on the group **mean** (PSPP / SPSS convention). It previously used the group median (Brown-Forsythe), which does not reproduce the Levene table of PSPP or SPSS; SPSS's ONEWAY / T-TEST / GLM all use the mean.
3. **Mann-Whitney U** now includes the tie correction in its asymptotic variance, `σ² = n1·n2·[(n+1)/12 − Σ(t³−t)/(12·n·(n−1))]`, with `p = 2·Φ(z)` (PSPP's "Asymp. Sig. (2-tailed)"). The continuity-corrected Z / p (SPSS, R `correct = TRUE`) remain available as `extra['zContinuityCorrected']` / `extra['pContinuityCorrected']`.

See the [statkit API](/en/api/statkit) for the implementations and [Analysis](/en/guide/analysis) for the procedures.
