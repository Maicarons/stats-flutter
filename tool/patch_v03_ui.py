from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_hub.dart")
t = p.read_text(encoding="utf-8")
if "examine_full" not in t:
    t = t.replace(
        "      _Item('正态性检验', 'KS / 偏度峰度', 'normality'),",
        "      _Item('正态性检验', 'KS / 偏度峰度', 'normality'),\n      _Item('EXAMINE 全套', '百分位/极值/茎叶/箱线/Q-Q', 'examine_full'),\n      _Item('箱线图', '多组分布对比', 'boxplot'),\n      _Item('Q-Q 图', '正态分位图', 'qqplot'),",
    )
    t = t.replace(
        "      _Item('主成分因子分析', 'PCA 载荷矩阵', 'factor_pca'),",
        "      _Item('主成分因子分析', 'PCA 载荷矩阵', 'factor_pca'),\n      _Item('因子分析（全）', 'varimax / KMO / Bartlett', 'factor_full'),",
    )
    p.write_text(t, encoding="utf-8")
    print("hub")

p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "case 'examine_full':" not in t:
    t = t.replace(
        "        case 'normality':\n          _runNormality();\n          break;",
        "        case 'normality':\n          _runNormality();\n          break;\n        case 'examine_full':\n          _runExamine();\n          break;\n        case 'boxplot':\n          _runBoxplot();\n          break;\n        case 'qqplot':\n          _runQQ();\n          break;\n        case 'factor_full':\n          _runFactorFull();\n          break;",
    )
    impl = r'''
  void _runExamine() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw '请选择变量';
    final r = examine(ds.numericColumn(name));
    _report = AnalysisReport(
      title: 'EXAMINE',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '描述',
          tables: [
            ReportTable(
              headers: const ['N', '均值', 'SD', '中位数', 'Q1', 'Q3', '偏度', '峰度'],
              rows: [
                [
                  '${r.desc.n}',
                  formatNum(r.desc.mean),
                  formatNum(r.desc.sd),
                  formatNum(r.desc.median),
                  formatNum(r.desc.q1),
                  formatNum(r.desc.q3),
                  formatNum(r.desc.skewness),
                  formatNum(r.desc.kurtosis),
                ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: '百分位',
          tables: [
            ReportTable(
              headers: const ['P', '值'],
              rows: [for (final p in r.percentiles.rows) ['${p.p}', formatNum(p.value)]],
            ),
          ],
          notes: '5% 截尾均值=${formatNum(r.percentiles.trimmedMean5)}  '
              'Winsorized=${formatNum(r.percentiles.winsorizedMean5)}',
        ),
        ReportSection(
          heading: '极值',
          tables: [
            ReportTable(
              headers: const ['#', '最小', '最大'],
              rows: List.generate(
                r.extremes.lowest.length,
                (i) => [
                  '${i + 1}',
                  '${formatNum(r.extremes.lowest[i].value)} (${r.extremes.lowest[i].caseIndex})',
                  '${formatNum(r.extremes.highest[i].value)} (${r.extremes.highest[i].caseIndex})',
                ],
              ),
            ),
          ],
        ),
        ReportSection(
          heading: '箱线',
          tables: [
            ReportTable(
              headers: const ['下须', 'Q1', '中位', 'Q3', '上须', '离群数'],
              rows: [
                [
                  formatNum(r.box.lowerWhisker),
                  formatNum(r.box.q1),
                  formatNum(r.box.median),
                  formatNum(r.box.q3),
                  formatNum(r.box.upperWhisker),
                  '${r.box.outliers.length}',
                ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: '茎叶图',
          body: '${r.stemLeaf.header}\n' +
              r.stemLeaf.rows
                  .map((e) => '${e.stem} | ${e.leaf}  (${e.frequency})')
                  .join('\n'),
        ),
        ReportSection(
          heading: '正态性 (D\'Agostino-Pearson)',
          tables: [
            ReportTable(
              headers: const ['Z偏度', 'Z峰度', 'χ²', 'df', 'p', '判断'],
              rows: [
                [
                  formatNum(r.normality.zSkew),
                  formatNum(r.normality.zKurt),
                  formatNum(r.normality.chiSquare),
                  '2',
                  formatP(r.normality.p),
                  r.normality.looksNormal ? '近似正态' : '偏离正态',
                ],
              ],
            ),
          ],
        ),
      ],
    );
    _chart = SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            for (final p in r.qq) ScatterSpot(p.theoretical, p.sample),
          ],
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  void _runBoxplot() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw '请选择变量';
    List<BoxPlotData> boxes;
    List<String> labels;
    if (_groupVar != null) {
      final g = _splitByGroup(name, _groupVar!);
      labels = g.keys.toList();
      boxes = boxPlotGroups(labels.map((k) => g[k]!).toList());
    } else {
      labels = [name];
      boxes = [boxPlot(ds.numericColumn(name))];
    }
    _report = AnalysisReport(
      title: '箱线图',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '分布摘要',
          tables: [
            ReportTable(
              headers: const ['组', 'N', '中位数', 'Q1', 'Q3', 'IQR', '离群'],
              rows: [
                for (var i = 0; i < boxes.length; i++)
                  [
                    labels[i],
                    '${ds.numericColumn(name).length}',
                    formatNum(boxes[i].median),
                    formatNum(boxes[i].q1),
                    formatNum(boxes[i].q3),
                    formatNum(boxes[i].iqr),
                    '${boxes[i].outliers.length}',
                  ],
              ],
            ),
          ],
        ),
      ],
    );
    // simple chart as bar of quartiles is weak; use report only + QQ reuse skipped
  }

  void _runQQ() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw '请选择变量';
    final pts = normalQQPointsStandardized(ds.numericColumn(name));
    _report = AnalysisReport(
      title: 'Q-Q 图',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '正态分位对照',
          body: '点数 ${pts.length}；点越贴近 y=x 直线越接近正态。',
        ),
      ],
    );
    _chart = SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [for (final p in pts) ScatterSpot(p.theoretical, p.sample)],
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  void _runFactorFull() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个变量';
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorAnalyze(cols, names: _selectedVars, maxFactors: 3, rotate: true);
    final rot = r.rotatedLoadings;
    _report = AnalysisReport(
      title: '因子分析（全）',
      subtitle: 'PCA + Varimax',
      sections: [
        ReportSection(
          heading: '适切性与球形检验',
          tables: [
            ReportTable(
              headers: const ['KMO', 'Bartlett χ²', 'df', 'p'],
              rows: [
                [
                  formatNum(r.kmo.overall),
                  formatNum(r.bartlett.chiSquare),
                  formatNum(r.bartlett.df, digits: 0),
                  formatP(r.bartlett.p),
                ],
              ],
            ),
            ReportTable(
              caption: '逐变量 KMO',
              headers: const ['变量', 'KMO'],
              rows: [
                for (var i = 0; i < r.kmo.names.length; i++)
                  [r.kmo.names[i], formatNum(r.kmo.perVariable[i])],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: '特征值 / 共同度',
          tables: [
            ReportTable(
              headers: const ['变量', '共同度', 'PC1', 'PC2', 'PC3'],
              rows: [
                for (var v = 0; v < _selectedVars.length; v++)
                  [
                    _selectedVars[v],
                    formatNum(r.communalities[v]),
                    for (var c = 0; c < 3; c++)
                      c < r.unrotated.loadings[v].length
                          ? formatNum(r.unrotated.loadings[v][c])
                          : '—',
                  ],
              ],
            ),
          ],
        ),
        if (rot != null)
          ReportSection(
            heading: 'Varimax 旋转载荷',
            tables: [
              ReportTable(
                headers: [
                  '变量',
                  for (var i = 0; i < rot[0].length; i++) 'F${i + 1}'
                ],
                rows: [
                  for (var v = 0; v < rot.length; v++)
                    [
                      v < _selectedVars.length ? _selectedVars[v] : 'X${v + 1}',
                      for (final l in rot[v]) formatNum(l),
                    ],
                ],
              ),
            ],
            notes: '旋转平方和=${formatNum(r.rotationSS)}',
          ),
      ],
    );
  }
'''
    anchor = "  AnalysisReport _nonparamReport(NonparametricResult r) {"
    t = t.replace(anchor, impl + "\n" + anchor, 1)
    p.write_text(t, encoding="utf-8")
    print("runner")
print("done")
