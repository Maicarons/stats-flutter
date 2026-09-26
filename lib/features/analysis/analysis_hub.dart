import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'analysis_runner.dart';

class AnalysisHub extends StatelessWidget {
  final bool embedded;
  final dynamic project;
  const AnalysisHub({super.key, this.embedded = true, this.project});

  static const _categories = [
    _Cat('描述与探索', Icons.insights, [
      _Item('描述统计', '均值、标准差、偏度峰度、置信区间', 'descriptives'),
      _Item('频率分析', '频数表、百分比、累计', 'frequencies'),
      _Item('探索分析', '分位数、极值、正态性', 'explore'),
    ]),
    _Cat('比较均值', Icons.compare_arrows, [
      _Item('单样本 t 检验', '均值 vs 检验值', 'ttest_one'),
      _Item('独立样本 t 检验', '两组均值比较 + Levene', 'ttest_ind'),
      _Item('配对样本 t 检验', '前后测 / 配对设计', 'ttest_paired'),
      _Item('单因素 ANOVA', '多组均值 + 效应量', 'anova'),
    ]),
    _Cat('相关与关联', Icons.hub, [
      _Item('相关分析', 'Pearson / Spearman 矩阵', 'correlation'),
      _Item('交叉表卡方', '列联表、χ²、Cramér V', 'crosstabs'),
    ]),
    _Cat('回归与聚类', Icons.timeline, [
      _Item('线性回归', '简单 / 多元、系数表', 'regression'),
      _Item('K-Means 聚类', '快速聚类、中心点', 'kmeans'),
    ]),
    _Cat('非参数与信度', Icons.speed, [
      _Item('Mann-Whitney U', '两独立样本秩和', 'mannwhitney'),
      _Item('Wilcoxon 符号秩', '两相关样本', 'wilcoxon'),
      _Item('Kruskal-Wallis H', 'k 独立样本', 'kruskal'),
      _Item('Cronbach α 信度', '量表内部一致性', 'reliability'),
    ]),
    _Cat('补充过程', Icons.extension, [
      _Item('分层均值 MEANS', '分组均值表', 'means'),
      _Item('正态性检验', 'KS / 偏度峰度', 'normality'),
      _Item('ROC 曲线', 'AUC 与诊断', 'roc'),
      _Item('事后比较 Tukey', 'ANOVA 两两差异', 'tukey'),
    ]),
    _Cat('降维与分类', Icons.auto_graph, [
      _Item('主成分因子分析', 'PCA 载荷矩阵', 'factor_pca'),
      _Item('逻辑回归', '二分类预测', 'logistic'),
    ]),
    _Cat('图表', Icons.bar_chart, [
      _Item('直方图', '分布形态', 'histogram'),
      _Item('散点图', '两变量关系', 'scatter'),
      _Item('条形图', '分类频数', 'bar'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context).tabAnalysis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final cat in _categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(cat.icon,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(cat.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            ...cat.items.map((item) => _AnalysisCard(item: item)),
          ],
        ],
      ),
    );
  }
}

class _Cat {
  final String title;
  final IconData icon;
  final List<_Item> items;
  const _Cat(this.title, this.icon, this.items);
}

class _Item {
  final String title;
  final String desc;
  final String id;
  const _Item(this.title, this.desc, this.id);
}

class _AnalysisCard extends StatelessWidget {
  final _Item item;
  const _AnalysisCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalysisRunner(analysisId: item.id, title: item.title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(item.desc,
                          style: TextStyle(
                              color: scheme.outline, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
