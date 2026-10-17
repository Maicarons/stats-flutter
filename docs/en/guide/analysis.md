# Analysis

Pick a procedure, set parameters, run, and read a text report with charts.

## Categories

- **Descriptives & Explore**: descriptives, frequencies, histogram / bar / scatter, box plot (whiskers / IQR box / median / mean / outliers, grouped, at most 6 side by side), error bar chart (mean with 95% CI), normal Q-Q plot (scatter + y = x guide line), normality tests (Lilliefors-corrected p)
- **Compare Means**: one-sample / independent / paired t-tests, Oneway ANOVA, ANCOVA (group comparison controlling a covariate, Type III sums of squares), Tukey HSD
- **Association**: Pearson/Spearman correlation (pairwise deletion, see [missing values](/en/guide/missing-values)), crosstabs chi-square
- **Regression & Clustering**: linear / stepwise regression, logistic regression, multinomial logistic regression, K-Means (with cluster scatter), PCA (loadings + scree plot), ROC
- **Nonparametric & Reliability**: Mann-Whitney (tie-corrected), Wilcoxon, Kruskal-Wallis, Jonckheere-Terpstra trend, permutation tests (two-sample mean difference / paired difference, exact enumeration for small samples), Cronbach α

## Reports

Each report includes group statistics, test tables (t/F/χ², df, p), effect sizes (Cohen d, η², Cramér's V), and notes such as Levene results.

p-values use APA style (`<.001` / `.032`) with significance stars.

### Export

- The top-right menu shares the **whole report** (plain text) or exports it to an HTML / Markdown file.
- The menu next to each section heading **copies or exports that section alone** (Markdown or HTML), named like `stats-<report>-<section>-20261015.md`; a non-ASCII section title falls back to its index.
