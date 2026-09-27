from pathlib import Path

# UI: add GLM / stepwise / ctables / logistic full
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_hub.dart")
t = p.read_text(encoding="utf-8")
if "glm_two" not in t:
    t = t.replace(
        "      _Item('逻辑回归', '二分类预测', 'logistic'),",
        "      _Item('逻辑回归', '二分类预测', 'logistic'),\n      _Item('逻辑回归（全）', 'Wald/OR CI/分类表/HL', 'logistic_full'),\n      _Item('GLM 双元 ANOVA', 'A×B 固定效应', 'glm_two'),\n      _Item('逐步回归', '前进/后退筛选', 'stepwise'),\n      _Item('CTABLES 透视表', '行列汇总', 'ctables'),",
    )
    p.write_text(t, encoding="utf-8")
    print("hub")

p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "case 'glm_two':" not in t:
    t = t.replace(
        "        case 'logistic':\n          _runLogistic();\n          break;",
        "        case 'logistic':\n          _runLogistic();\n          break;\n        case 'logistic_full':\n          _runLogisticFull();\n          break;\n        case 'glm_two':\n          _runGlmTwo();\n          break;\n        case 'stepwise':\n          _runStepwise();\n          break;\n        case 'ctables':\n          _runCtables();\n          break;",
    )
    impl = r'''
  void _runLogisticFull() {
    if (_yVar == null || _xVar == null) throw '请选择因变量与自变量';
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final med = percentile(List.of(y.sublist(0, n))..sort(), 50);
    final r = logisticRegressionFull(
      [x.sublist(0, n)],
      [for (var i = 0; i < n; i++) y[i] >= med ? 1 : 0],
      names: [_xVar!],
    );
    _report = AnalysisReport(
      title: '逻辑回归（全）',
      subtitle: '${_yVar!} ~ ${_xVar!}',
      sections: [
        ReportSection(
          heading: '系数（Wald）',
          tables: [
            ReportTable(
              headers: const ['项', 'B', 'SE', 'Wald', 'p', 'OR', 'OR 95%CI'],
              rows: [
                for (final c in r.coefficients)
                  [
                    c.name,
                    formatNum(c.beta),
                    formatNum(c.se),
                    formatNum(c.wald),
                    formatP(c.p),
                    formatNum(c.oddsRatio),
                    '[${formatNum(c.orLower95)}, ${formatNum(c.orUpper95)}]',
                  ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: '模型与分类',
          tables: [
            ReportTable(
              headers: const ['伪R²', 'Omnibus χ²', 'p', 'N'],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  formatNum(r.omnibusChi),
                  formatP(r.omnibusP),
                  '${r.n}',
                ],
              ],
            ),
            ReportTable(
              caption: '分类表（阈值 0.5）',
              headers: const ['正确率', '敏感度', '特异度', '精确率'],
              rows: [
                [
                  '${(r.table.accuracy * 100).toStringAsFixed(1)}%',
                  '${(r.table.sensitivity * 100).toStringAsFixed(1)}%',
                  '${(r.table.specificity * 100).toStringAsFixed(1)}%',
                  '${(r.table.precision * 100).toStringAsFixed(1)}%',
                ],
              ],
            ),
            ReportTable(
              caption: 'Hosmer-Lemeshow',
              headers: const ['χ²', 'df', 'p', '组数'],
              rows: [
                [
                  formatNum(r.hl.chiSquare),
                  '${r.hl.df}',
                  formatP(r.hl.p),
                  '${r.hl.groups}',
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runGlmTwo() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    // Use groupVar as A, and method-like second factor if available from selected else singleton B
    final aName = _groupVar!;
    final bName = _selectedVars.length > 1 ? _selectedVars[1] : aName;
    final gi = ds.indexOf(aName);
    final bi = ds.indexOf(bName);
    final vi = ds.indexOf(vName);
    if (gi < 0 || vi < 0) throw '变量不存在';
    final cells = <(String, String), List<double>>{};
    for (final row in ds.cases) {
      final a = gi < row.length ? ds.variables[gi].displayValue(row[gi]) : null;
      final b = bi >= 0 && bi < row.length
          ? ds.variables[bi].displayValue(row[bi])
          : '—';
      final raw = vi < row.length ? row[vi] : null;
      if (a == null || raw is! num) continue;
      cells.putIfAbsent((a, b), () => []).add(raw.toDouble());
    }
    if (cells.isEmpty) throw '无有效数据';
    final r = cells.length == 1 || aName == bName
        ? glmOneWay({for (final e in cells.entries) e.key.$1: e.value}, yName: vName)
        : glmTwoWay(cells, yName: vName);
    _report = AnalysisReport(
      title: aName == bName ? 'GLM 单元 ANOVA' : 'GLM 双元 ANOVA',
      subtitle: vName,
      sections: [
        ReportSection(
          heading: '主体间效应',
          tables: [
            ReportTable(
              headers: const ['来源', 'SS', 'df', 'MS', 'F', 'p', '偏η²'],
              rows: [
                for (final t in r.terms)
                  [
                    t.name,
                    formatNum(t.ss),
                    '${t.df}',
                    formatNum(t.ms),
                    formatNum(t.f),
                    formatP(t.p),
                    formatNum(t.partialEta2),
                  ],
                [
                  '误差',
                  formatNum(r.ssError),
                  '${r.dfError}',
                  formatNum(r.msError),
                  '',
                  '',
                  '',
                ],
              ],
            ),
          ],
          notes:
              'R²=${formatNum(r.r2)}  调整R²=${formatNum(r.adjR2)}  RMSE=${formatNum(r.rmse)}  N=${r.n}',
        ),
      ],
    );
  }

  void _runStepwise() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个预测变量';
    if (_yVar == null) throw '请选择因变量';
    final y = ds.numericColumn(_yVar!);
    final names = List<String>.from(_selectedVars);
    final xs = [for (final n in names) ds.numericColumn(n)];
    final n = y.length < xs.first.length ? y.length : xs.first.length;
    final r = stepwiseRegression(
      [for (final col in xs) col.sublist(0, n)],
      y.sublist(0, n),
      names: names,
      method: StepwiseMethod.both,
    );
    _report = AnalysisReport(
      title: '逐步回归',
      subtitle: '${_yVar!} ~ stepwise',
      sections: [
        ReportSection(
          heading: '进入模型的变量',
          body: r.selected.isEmpty ? '（无变量进入）' : r.selected.join(', '),
          tables: [
            ReportTable(
              headers: const ['步', '动作', '变量', 'R²', '调整R²'],
              rows: [
                for (var i = 0; i < r.steps.length; i++)
                  [
                    '${i + 1}',
                    r.steps[i].action == 'enter' ? '进入' : '移除',
                    r.steps[i].variable,
                    formatNum(r.steps[i].r2),
                    formatNum(r.steps[i].adjR2),
                  ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runCtables() {
    if (_yVar == null || _xVar == null) throw '请选择行/列变量';
    final rowKeys = ds.rawColumn(_yVar!);
    final colKeys = ds.rawColumn(_xVar!);
    final r = crosstabSummary(
      rowKeys: rowKeys,
      colKeys: colKeys,
      rowVar: _yVar!,
      colVar: _xVar!,
      summary: CellSummary.count,
      rowLabels: {
        for (final e in ds.variables[ds.indexOf(_yVar!)].valueLabels.entries)
          e.key: e.value,
      },
      colLabels: {
        for (final e in ds.variables[ds.indexOf(_xVar!)].valueLabels.entries)
          e.key: e.value,
      },
    );
    _report = AnalysisReport(
      title: 'CTABLES 透视表',
      subtitle: '${_yVar!} × ${_xVar!}',
      sections: [
        ReportSection(
          heading: '汇总（计数）',
          tables: [
            ReportTable(
              headers: ['', ...r.colLabels, '合计'],
              rows: [
                for (var i = 0; i < r.rowLabels.length; i++)
                  [
                    r.rowLabels[i],
                    for (final c in r.cells[i]) c.display,
                    r.rowTotals[i].display,
                  ],
                [
                  '合计',
                  for (final c in r.colTotals) c.display,
                  r.grandTotal.display,
                ],
              ],
            ),
          ],
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
