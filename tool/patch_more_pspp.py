from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\statkit.dart")
t = p.read_text(encoding="utf-8")
if "factor_logistic" not in t:
    t = t.rstrip() + "\nexport 'src/factor_logistic.dart';\n"
    p.write_text(t, encoding="utf-8")
    print("export added")
else:
    print("exists")

# analysis hub: add factor/logistic
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_hub.dart")
t = p.read_text(encoding="utf-8")
if "factor_pca" not in t:
    t = t.replace(
        "    _Cat('图表', Icons.bar_chart, [",
        """    _Cat('降维与分类', Icons.auto_graph, [
      _Item('主成分因子分析', 'PCA 载荷矩阵', 'factor_pca'),
      _Item('逻辑回归', '二分类预测', 'logistic'),
    ]),
    _Cat('图表', Icons.bar_chart, [""",
    )
    p.write_text(t, encoding="utf-8")
    print("hub added")
else:
    print("hub exists")

# analysis runner: add cases + impl
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "case 'factor_pca':" not in t:
    t = t.replace(
        "        case 'tukey':\n          _runTukey();\n          break;",
        "        case 'tukey':\n          _runTukey();\n          break;\n        case 'factor_pca':\n          _runFactor();\n          break;\n        case 'logistic':\n          _runLogistic();\n          break;",
    )
    print("cases added")

if "void _runFactor()" not in t:
    impl = r'''
  void _runFactor() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个变量';
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorPca(cols, names: _selectedVars, maxFactors: 3);
    _report = AnalysisReport(
      title: '主成分因子分析',
      subtitle: 'PCA · ${_selectedVars.join(", ")}',
      sections: [
        ReportSection(
          heading: '特征值与方差',
          tables: [
            ReportTable(
              headers: const ['成分', '特征值', '方差贡献率', '累计'],
              rows: [
                for (var i = 0; i < r.eigenvalues.length; i++)
                  [
                    'PC${i + 1}',
                    formatNum(r.eigenvalues[i]),
                    '${(r.eigenvalues[i] / _selectedVars.length * 100).toStringAsFixed(1)}%',
                    '${(r.eigenvalues.sublist(0, i + 1).fold<double>(0, (a, b) => a + b) / _selectedVars.length * 100).toStringAsFixed(1)}%',
                  ],
              ],
            ),
            ReportTable(
              caption: '载荷矩阵',
              headers: [
                '变量',
                for (var i = 0; i < r.eigenvalues.length; i++) 'PC${i + 1}'
              ],
              rows: [
                for (var v = 0; v < _selectedVars.length; v++)
                  [
                    r.variables[v],
                    for (final l in r.loadings[v]) formatNum(l),
                  ],
              ],
            ),
          ],
          notes: '总方差解释率 ${formatNum(r.totalVarianceExplained)}。采用相关矩阵主成分法（未旋转）。',
        ),
      ],
    );
  }

  void _runLogistic() {
    if (_yVar == null || _xVar == null) throw '请选择因变量与自变量';
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final med = percentile(List.of(y.sublist(0, n))..sort(), 50);
    final xs = [x.sublist(0, n)];
    final ys = [
      for (var i = 0; i < n; i++) y[i] >= med ? 1 : 0,
    ];
    final r = logisticRegression(xs, ys, names: [_xVar!]);
    _report = AnalysisReport(
      title: '逻辑回归',
      subtitle: '${_yVar!} (>=median) ~ ${_xVar!}',
      sections: [
        ReportSection(
          heading: '模型',
          tables: [
            ReportTable(
              headers: const ['项', 'B (log-odds)', 'OR=exp(B)'],
              rows: [
                for (var i = 0; i < r.coefficients.length; i++)
                  [
                    r.names[i],
                    formatNum(r.coefficients[i]),
                    formatNum(math.exp(r.coefficients[i])),
                  ],
              ],
            ),
            ReportTable(
              headers: const ['伪R² (McFadden)', '正确率', '迭代'],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  '${(r.accuracy * 100).toStringAsFixed(1)}%',
                  '${r.iterations}',
                ],
              ],
            ),
          ],
          notes: '采用梯度下降拟合，样本量建议 ≥ 30。OR>1 表示风险增加。',
        ),
      ],
    );
  }
'''
    anchor = "  AnalysisReport _nonparamReport(NonparametricResult r) {"
    t = t.replace(anchor, impl + "\n" + anchor, 1)
    print("impl added")

p.write_text(t, encoding="utf-8")
print("runner done")

# data editor menu: syntax editor
p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")
if "SyntaxEditorPage" not in t:
    t = t.replace(
        "import '../transform/transform_page.dart';",
        "import '../syntax/syntax_editor_page.dart';\nimport '../transform/transform_page.dart';",
    )
    t = t.replace(
        "              PopupMenuItem(value: 'transform', child: const Text('数据变换…')),",
        "              PopupMenuItem(value: 'transform', child: const Text('数据变换…')),\n              PopupMenuItem(value: 'syntax', child: const Text('语法编辑器…')),\n              PopupMenuItem(value: 'weight', child: const Text('加权个案…')),\n              PopupMenuItem(value: 'split', child: const Text('拆分文件…')),\n              PopupMenuItem(value: 'find', child: const Text('查找个案…')),",
    )
    t = t.replace(
        "      case 'transform':",
        """      case 'syntax':
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SyntaxEditorPage()),
          );
        }
        break;
      case 'weight':
        _pickWeight(l10n);
        break;
      case 'split':
        _pickSplit(l10n);
        break;
      case 'find':
        _findCase(l10n);
        break;
      case 'transform':""",
    )
    # add helper methods before class end of state - append to _addVar method area
    helpers = r'''
  Future<void> _pickWeight(AppLocalizations l10n) async {
    final names = ds.variables.map((v) => v.name).toList();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('WEIGHT CASES'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('不加权'),
          ),
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
        ],
      ),
    );
    if (v == null) return;
    ds.weightVariable = v.isEmpty ? null : v;
    datasetStore.touch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v.isEmpty ? '已取消加权' : '加权变量: $v')),
      );
    }
  }

  Future<void> _pickSplit(AppLocalizations l10n) async {
    final names = ds.variables.map((v) => v.name).toList();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('SPLIT FILE'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('不分组'),
          ),
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
        ],
      ),
    );
    if (v == null) return;
    ds.splitVariable = v.isEmpty ? null : v;
    datasetStore.touch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v.isEmpty ? '已关闭拆分' : '拆分变量: $v')),
      );
    }
  }

  Future<void> _findCase(AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    final q = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('查找'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入要查找的内容…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('查找'),
          ),
        ],
      ),
    );
    if (q == null || q.trim().isEmpty) return;
    final key = q.trim().toLowerCase();
    final hits = <int>[];
    for (var i = 0; i < ds.nCases; i++) {
      final hay = ds.cases[i].map((e) => e?.toString() ?? '').join(' ');
      if (hay.toLowerCase().contains(key)) hits.add(i + 1);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hits.isEmpty
              ? '未找到「$q」'
              : '找到 ${hits.length} 处：${hits.take(12).join(", ")}${hits.length > 12 ? "…" : ""}',
        ),
      ),
    );
  }
'''
    # insert before the last closing of _DataEditorPageState - find "_addCase(AppLocalizations"
    marker = "  void _addCase(AppLocalizations l10n) {"
    t = t.replace(marker, helpers + "\n" + marker, 1)
    p.write_text(t, encoding="utf-8")
    print("data menu + helpers")
else:
    print("data already has syntax")

print("all patches done")
