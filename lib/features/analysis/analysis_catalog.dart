/// 分析目录：把「分析中心」的展示元数据与执行 id 集中定义（文案走 l10n）。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

class AnalysisItem {
  final String id;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) desc;
  final bool advanced;

  const AnalysisItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    this.advanced = false,
  });
}

class AnalysisCategory {
  final String Function(AppLocalizations) title;
  final IconData icon;
  final List<AnalysisItem> items;

  const AnalysisCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// 按 id 取条目（用于「最近 / 收藏」复用）。
AnalysisItem? analysisById(String id) {
  for (final c in analysisCatalog) {
    for (final it in c.items) {
      if (it.id == id) return it;
    }
  }
  return null;
}

const List<AnalysisCategory> analysisCatalog = [
  AnalysisCategory(
    title: _catDescribe,
    icon: Icons.insights,
    items: [
      AnalysisItem(
        id: 'descriptives',
        icon: Icons.summarize_outlined,
        title: _anDescriptives,
        desc: _anDescriptivesDesc,
      ),
      AnalysisItem(
        id: 'frequencies',
        icon: Icons.bar_chart_outlined,
        title: _anFrequencies,
        desc: _anFrequenciesDesc,
      ),
      AnalysisItem(
        id: 'explore',
        icon: Icons.travel_explore,
        title: _anExplore,
        desc: _anExploreDesc,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catCompare,
    icon: Icons.compare_arrows,
    items: [
      AnalysisItem(
        id: 'ttest_one',
        icon: Icons.exposure_plus_1,
        title: _anTtestOne,
        desc: _anTtestOneDesc,
      ),
      AnalysisItem(
        id: 'ttest_ind',
        icon: Icons.swap_horiz,
        title: _anTtestInd,
        desc: _anTtestIndDesc,
      ),
      AnalysisItem(
        id: 'ttest_paired',
        icon: Icons.compare_arrows,
        title: _anTtestPaired,
        desc: _anTtestPairedDesc,
      ),
      AnalysisItem(
        id: 'anova',
        icon: Icons.stacked_bar_chart,
        title: _anAnova,
        desc: _anAnovaDesc,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catCorrelate,
    icon: Icons.hub_outlined,
    items: [
      AnalysisItem(
        id: 'correlation',
        icon: Icons.grid_on,
        title: _anCorrelation,
        desc: _anCorrelationDesc,
      ),
      AnalysisItem(
        id: 'crosstabs',
        icon: Icons.table_chart_outlined,
        title: _anCrosstabs,
        desc: _anCrosstabsDesc,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catModel,
    icon: Icons.timeline,
    items: [
      AnalysisItem(
        id: 'regression',
        icon: Icons.show_chart,
        title: _anRegression,
        desc: _anRegressionDesc,
      ),
      AnalysisItem(
        id: 'kmeans',
        icon: Icons.scatter_plot,
        title: _anKmeans,
        desc: _anKmeansDesc,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catNonparam,
    icon: Icons.speed,
    items: [
      AnalysisItem(
        id: 'mannwhitney',
        icon: Icons.waves,
        title: _anMannwhitney,
        desc: _anMannwhitneyDesc,
      ),
      AnalysisItem(
        id: 'wilcoxon',
        icon: Icons.swap_vert,
        title: _anWilcoxon,
        desc: _anWilcoxonDesc,
      ),
      AnalysisItem(
        id: 'kruskal',
        icon: Icons.multiline_chart,
        title: _anKruskal,
        desc: _anKruskalDesc,
      ),
      AnalysisItem(
        id: 'reliability',
        icon: Icons.verified_outlined,
        title: _anReliability,
        desc: _anReliabilityDesc,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catExtra,
    icon: Icons.extension_outlined,
    items: [
      AnalysisItem(
        id: 'means',
        icon: Icons.layers_outlined,
        title: _anMeans,
        desc: _anMeansDesc,
      ),
      AnalysisItem(
        id: 'normality',
        icon: Icons.functions,
        title: _anNormality,
        desc: _anNormalityDesc,
      ),
      AnalysisItem(
        id: 'examine_full',
        icon: Icons.manage_search,
        title: _anExamineFull,
        desc: _anExamineFullDesc,
        advanced: true,
      ),
      AnalysisItem(
        id: 'boxplot',
        icon: Icons.candlestick_chart_outlined,
        title: _anBoxplot,
        desc: _anBoxplotDesc,
      ),
      AnalysisItem(
        id: 'qqplot',
        icon: Icons.timeline,
        title: _anQqplot,
        desc: _anQqplotDesc,
      ),
      AnalysisItem(
        id: 'roc',
        icon: Icons.area_chart,
        title: _anRoc,
        desc: _anRocDesc,
      ),
      AnalysisItem(
        id: 'tukey',
        icon: Icons.format_list_numbered,
        title: _anTukey,
        desc: _anTukeyDesc,
        advanced: true,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catDimreduce,
    icon: Icons.auto_graph,
    items: [
      AnalysisItem(
        id: 'factor_pca',
        icon: Icons.blur_on,
        title: _anFactorPca,
        desc: _anFactorPcaDesc,
      ),
      AnalysisItem(
        id: 'factor_full',
        icon: Icons.blur_circular,
        title: _anFactorFull,
        desc: _anFactorFullDesc,
        advanced: true,
      ),
      AnalysisItem(
        id: 'logistic',
        icon: Icons.toggle_on_outlined,
        title: _anLogistic,
        desc: _anLogisticDesc,
      ),
      AnalysisItem(
        id: 'logistic_full',
        icon: Icons.toggle_on,
        title: _anLogisticFull,
        desc: _anLogisticFullDesc,
        advanced: true,
      ),
      AnalysisItem(
        id: 'glm_two',
        icon: Icons.grid_view,
        title: _anGlmTwo,
        desc: _anGlmTwoDesc,
        advanced: true,
      ),
      AnalysisItem(
        id: 'stepwise',
        icon: Icons.linear_scale,
        title: _anStepwise,
        desc: _anStepwiseDesc,
        advanced: true,
      ),
      AnalysisItem(
        id: 'ctables',
        icon: Icons.table_view,
        title: _anCtables,
        desc: _anCtablesDesc,
        advanced: true,
      ),
    ],
  ),
  AnalysisCategory(
    title: _catCharts,
    icon: Icons.bar_chart,
    items: [
      AnalysisItem(
        id: 'histogram',
        icon: Icons.equalizer,
        title: _anHistogram,
        desc: _anHistogramDesc,
      ),
      AnalysisItem(
        id: 'scatter',
        icon: Icons.scatter_plot,
        title: _anScatter,
        desc: _anScatterDesc,
      ),
      AnalysisItem(
        id: 'bar',
        icon: Icons.bar_chart,
        title: _anBar,
        desc: _anBarDesc,
      ),
    ],
  ),
];

// —— l10n 访问器（避免目录里出现裸字符串） ——
String _catDescribe(AppLocalizations l) => l.anCatDescribe;
String _catCompare(AppLocalizations l) => l.anCatCompare;
String _catCorrelate(AppLocalizations l) => l.anCatCorrelate;
String _catModel(AppLocalizations l) => l.anCatModel;
String _catNonparam(AppLocalizations l) => l.anCatNonparam;
String _catExtra(AppLocalizations l) => l.anCatExtra;
String _catDimreduce(AppLocalizations l) => l.anCatDimreduce;
String _catCharts(AppLocalizations l) => l.anCatCharts;

String _anDescriptives(AppLocalizations l) => l.anDescriptives;
String _anDescriptivesDesc(AppLocalizations l) => l.anDescriptivesDesc;
String _anFrequencies(AppLocalizations l) => l.anFrequencies;
String _anFrequenciesDesc(AppLocalizations l) => l.anFrequenciesDesc;
String _anExplore(AppLocalizations l) => l.anExplore;
String _anExploreDesc(AppLocalizations l) => l.anExploreDesc;
String _anTtestOne(AppLocalizations l) => l.anTtestOne;
String _anTtestOneDesc(AppLocalizations l) => l.anTtestOneDesc;
String _anTtestInd(AppLocalizations l) => l.anTtestInd;
String _anTtestIndDesc(AppLocalizations l) => l.anTtestIndDesc;
String _anTtestPaired(AppLocalizations l) => l.anTtestPaired;
String _anTtestPairedDesc(AppLocalizations l) => l.anTtestPairedDesc;
String _anAnova(AppLocalizations l) => l.anAnova;
String _anAnovaDesc(AppLocalizations l) => l.anAnovaDesc;
String _anCorrelation(AppLocalizations l) => l.anCorrelation;
String _anCorrelationDesc(AppLocalizations l) => l.anCorrelationDesc;
String _anCrosstabs(AppLocalizations l) => l.anCrosstabs;
String _anCrosstabsDesc(AppLocalizations l) => l.anCrosstabsDesc;
String _anRegression(AppLocalizations l) => l.anRegression;
String _anRegressionDesc(AppLocalizations l) => l.anRegressionDesc;
String _anKmeans(AppLocalizations l) => l.anKmeans;
String _anKmeansDesc(AppLocalizations l) => l.anKmeansDesc;
String _anMannwhitney(AppLocalizations l) => l.anMannwhitney;
String _anMannwhitneyDesc(AppLocalizations l) => l.anMannwhitneyDesc;
String _anWilcoxon(AppLocalizations l) => l.anWilcoxon;
String _anWilcoxonDesc(AppLocalizations l) => l.anWilcoxonDesc;
String _anKruskal(AppLocalizations l) => l.anKruskal;
String _anKruskalDesc(AppLocalizations l) => l.anKruskalDesc;
String _anReliability(AppLocalizations l) => l.anReliability;
String _anReliabilityDesc(AppLocalizations l) => l.anReliabilityDesc;
String _anMeans(AppLocalizations l) => l.anMeans;
String _anMeansDesc(AppLocalizations l) => l.anMeansDesc;
String _anNormality(AppLocalizations l) => l.anNormality;
String _anNormalityDesc(AppLocalizations l) => l.anNormalityDesc;
String _anExamineFull(AppLocalizations l) => l.anExamineFull;
String _anExamineFullDesc(AppLocalizations l) => l.anExamineFullDesc;
String _anBoxplot(AppLocalizations l) => l.anBoxplot;
String _anBoxplotDesc(AppLocalizations l) => l.anBoxplotDesc;
String _anQqplot(AppLocalizations l) => l.anQqplot;
String _anQqplotDesc(AppLocalizations l) => l.anQqplotDesc;
String _anRoc(AppLocalizations l) => l.anRoc;
String _anRocDesc(AppLocalizations l) => l.anRocDesc;
String _anTukey(AppLocalizations l) => l.anTukey;
String _anTukeyDesc(AppLocalizations l) => l.anTukeyDesc;
String _anFactorPca(AppLocalizations l) => l.anFactorPca;
String _anFactorPcaDesc(AppLocalizations l) => l.anFactorPcaDesc;
String _anFactorFull(AppLocalizations l) => l.anFactorFull;
String _anFactorFullDesc(AppLocalizations l) => l.anFactorFullDesc;
String _anLogistic(AppLocalizations l) => l.anLogistic;
String _anLogisticDesc(AppLocalizations l) => l.anLogisticDesc;
String _anLogisticFull(AppLocalizations l) => l.anLogisticFull;
String _anLogisticFullDesc(AppLocalizations l) => l.anLogisticFullDesc;
String _anGlmTwo(AppLocalizations l) => l.anGlmTwo;
String _anGlmTwoDesc(AppLocalizations l) => l.anGlmTwoDesc;
String _anStepwise(AppLocalizations l) => l.anStepwise;
String _anStepwiseDesc(AppLocalizations l) => l.anStepwiseDesc;
String _anCtables(AppLocalizations l) => l.anCtables;
String _anCtablesDesc(AppLocalizations l) => l.anCtablesDesc;
String _anHistogram(AppLocalizations l) => l.anHistogram;
String _anHistogramDesc(AppLocalizations l) => l.anHistogramDesc;
String _anScatter(AppLocalizations l) => l.anScatter;
String _anScatterDesc(AppLocalizations l) => l.anScatterDesc;
String _anBar(AppLocalizations l) => l.anBar;
String _anBarDesc(AppLocalizations l) => l.anBarDesc;
