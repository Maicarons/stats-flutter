#!/usr/bin/env python3
"""Create dozens of logical commits for stats-flutter."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(r"F:\workspace\stats-flutter")

def git(*args, check=True):
    r = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if check and r.returncode != 0:
        print("FAIL", args, r.stderr[:400])
        sys.exit(1)
    return r.stdout

def commit(msg, paths):
    """Stage given paths (files or dirs) and commit."""
    if not paths:
        print("skip empty", msg)
        return
    for p in paths:
        git("add", "-A", p, check=False)
    st = git("status", "--short")
    if not st.strip():
        print("nothing to commit:", msg)
        return
    git("commit", "-m", msg)
    print("✓", msg)

# --- 01 toolchain / project skeleton ---
commit(
    "chore: initialize Flutter multi-platform project skeleton",
    [".gitignore", "analysis_options.yaml", "pubspec.yaml", "stats_flutter.iml", ".idea"],
)

commit(
    "chore(android): use Tencent Gradle distribution and Aliyun Maven mirrors",
    ["android"],
)

commit(
    "chore: add GitHub Actions CI workflow",
    [".github"],
)

# --- 02 statkit kernel (split) ---
commit(
    "feat(statkit): add pure-Dart statistics package skeleton",
    ["packages/statkit/pubspec.yaml", "packages/statkit/README.md", "packages/statkit/lib/statkit.dart"],
)

commit(
    "feat(statkit): implement distributions (normal, t, chi-square, F, gamma)",
    ["packages/statkit/lib/src/distributions.dart"],
)

commit(
    "feat(statkit): implement descriptives and percentile helpers",
    ["packages/statkit/lib/src/descriptives.dart"],
)

commit(
    "feat(statkit): implement frequencies and histogram binning",
    ["packages/statkit/lib/src/frequencies.dart"],
)

commit(
    "feat(statkit): implement t-tests, ANOVA, Levene and chi-square",
    ["packages/statkit/lib/src/hypothesis.dart"],
)

commit(
    "feat(statkit): implement Pearson/Spearman correlation",
    ["packages/statkit/lib/src/correlation.dart"],
)

commit(
    "feat(statkit): implement linear and multiple regression",
    ["packages/statkit/lib/src/regression.dart"],
)

commit(
    "feat(statkit): implement nonparametric tests",
    ["packages/statkit/lib/src/nonparametric.dart"],
)

commit(
    "feat(statkit): implement Cronbach alpha reliability",
    ["packages/statkit/lib/src/reliability.dart"],
)

commit(
    "feat(statkit): implement k-means clustering",
    ["packages/statkit/lib/src/clustering.dart"],
)

commit(
    "feat(statkit): implement means, normality, ROC, Tukey HSD",
    ["packages/statkit/lib/src/extra_tests.dart"],
)

commit(
    "feat(statkit): implement PCA factor analysis and logistic regression",
    ["packages/statkit/lib/src/factor_logistic.dart"],
)

commit(
    "feat(statkit): add number formatting helpers",
    ["packages/statkit/lib/src/format.dart"],
)

commit(
    "test(statkit): cover core statistical procedures",
    ["packages/statkit/test"],
)

# --- 03 app core ---
commit(
    "feat(core): add dataset and variable models",
    ["lib/core/models"],
)

commit(
    "feat(core): add Material 3 theme with Noto Sans SC",
    ["lib/core/theme"],
)

commit(
    "feat(core): add PSPP-style data transforms",
    ["lib/core/transforms"],
)

commit(
    "feat(core): add syntax command engine subset",
    ["lib/core/syntax"],
)

# --- 04 shared state ---
commit(
    "feat(shared): add project store and dataset proxy state",
    ["lib/shared/project_store.dart", "lib/shared/dataset_store.dart", "lib/shared/app_settings.dart"],
)

commit(
    "feat(shared): add unified brand logo painter",
    ["lib/shared/brand_logo.dart"],
)

# --- 05 localization ---
commit(
    "feat(i18n): add English and Chinese ARB localizations",
    ["lib/l10n", "l10n.yaml"],
)

# --- 06 data editor ---
commit(
    "feat(data): add editable spreadsheet grid with double-click edit",
    ["lib/features/data_editor/editable_data_grid.dart"],
)

commit(
    "feat(data): add value labels and missing values editors",
    ["lib/features/data_editor/value_labels_dialog.dart", "lib/features/data_editor/missing_values_dialog.dart"],
)

commit(
    "feat(data): add CSV import/export",
    ["lib/features/data_editor/csv_io.dart"],
)

commit(
    "feat(data): assemble data editor page with variable view",
    ["lib/features/data_editor/data_editor_page.dart"],
)

# --- 07 analysis ---
commit(
    "feat(analysis): add analysis hub catalog",
    ["lib/features/analysis/analysis_hub.dart"],
)

commit(
    "feat(output): add report builder for statistical output",
    ["lib/features/output"],
)

commit(
    "feat(analysis): add analysis runner with charts",
    ["lib/features/analysis/analysis_runner.dart"],
)

# --- 08 transform / syntax UI ---
commit(
    "feat(transform): add data transform UI",
    ["lib/features/transform"],
)

commit(
    "feat(syntax): add syntax editor page",
    ["lib/features/syntax"],
)

# --- 09 learn / quiz ---
commit(
    "feat(learn): add statistics learning module",
    ["lib/features/learn"],
)

commit(
    "feat(quiz): add quiz bank and instant scoring",
    ["lib/features/quiz"],
)

# --- 10 settings / about ---
commit(
    "feat(settings): add theme, language and reset settings",
    ["lib/features/settings/settings_page.dart"],
)

commit(
    "feat(settings): add about page with bilingual README",
    ["lib/features/settings/about_page.dart", "assets/content"],
)

# --- 11 projects / workspace ---
commit(
    "feat(projects): add project model and list home",
    ["lib/features/projects/project_list_page.dart", "lib/features/projects/project_workspace_page.dart"],
)

commit(
    "feat(home): global shell with projects/learn/quiz/settings",
    ["lib/features/home"],
)

commit(
    "feat(splash): add branded splash screen",
    ["lib/features/splash"],
)

# --- 12 app entry + assets ---
commit(
    "feat(app): wire MaterialApp with l10n and splash entry",
    ["lib/main.dart"],
)

commit(
    "feat(assets): add demo CSV dataset",
    ["assets/data", "assets/content"],
)

commit(
    "chore(icons): add unified app icon for all platforms",
    ["assets/icon", "ios", "macos", "windows/runner/resources", "web"],
)

# --- 13 docs ---
commit(
    "docs: add VitePress bilingual documentation site",
    ["docs"],
)

commit(
    "docs: add project README",
    ["README.md"],
)

commit(
    "chore: add tool scripts for icons and patches",
    ["tool"],
)

# leftover
left = git("status", "--short")
if left.strip():
    commit("chore: sync remaining project files", ["."])
    left = git("status", "--short")
    if left.strip():
        print("REMAINING:\n", left)

print("DONE")
print(git("log", "--oneline"))
