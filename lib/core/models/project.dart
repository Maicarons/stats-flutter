/// 工程模型：一个工程 = 一份统计表 + 元数据
library;

import 'dataset.dart';

class ProjectMeta {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;
  int nCases;
  int nVars;

  ProjectMeta({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.nCases = 0,
    this.nVars = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'nCases': nCases,
        'nVars': nVars,
      };

  factory ProjectMeta.fromJson(Map<String, dynamic> j) => ProjectMeta(
        id: j['id'] as String,
        name: (j['name'] ?? 'Untitled') as String,
        description: j['description'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        nCases: (j['nCases'] ?? 0) as int,
        nVars: (j['nVars'] ?? 0) as int,
      );
}

/// 完整工程（元数据 + 数据集）
class Project {
  final ProjectMeta meta;
  final Dataset dataset;

  Project({required this.meta, required this.dataset});

  factory Project.create({
    required String name,
    String? description,
    Dataset? dataset,
  }) {
    final now = DateTime.now();
    final id = 'p_${now.microsecondsSinceEpoch}';
    final ds = dataset ?? Dataset(name: name);
    return Project(
      meta: ProjectMeta(
        id: id,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
        nCases: ds.nCases,
        nVars: ds.nVars,
      ),
      dataset: ds,
    );
  }

  void touch() {
    meta.updatedAt = DateTime.now();
    meta.nCases = dataset.nCases;
    meta.nVars = dataset.nVars;
    dataset.name = meta.name;
  }

  Map<String, dynamic> toJson() => {
        'meta': meta.toJson(),
        'dataset': {
          'name': dataset.name,
          'path': dataset.path,
          'weightVariable': dataset.weightVariable,
          'splitVariable': dataset.splitVariable,
          'variables': [for (final v in dataset.variables) v.toJson()],
          'cases': [
            for (final row in dataset.cases)
              [for (final cell in row) cell],
          ],
        },
      };

  factory Project.fromJson(Map<String, dynamic> j) {
    final meta = ProjectMeta.fromJson(
        Map<String, dynamic>.from(j['meta'] as Map));
    final dsJson = Map<String, dynamic>.from(j['dataset'] as Map);
    final vars = [
      for (final v in (dsJson['variables'] as List? ?? []))
        Variable.fromJson(Map<String, dynamic>.from(v as Map)),
    ];
    final cases = [
      for (final row in (dsJson['cases'] as List? ?? []))
        [
          for (final cell in (row as List)) cell as Object?,
        ],
    ];
    final ds = Dataset(name: dsJson['name'] as String? ?? meta.name, variables: vars, cases: cases)
      ..path = dsJson['path'] as String?
      ..weightVariable = dsJson['weightVariable'] as String?
      ..splitVariable = dsJson['splitVariable'] as String?;
    return Project(meta: meta, dataset: ds);
  }

  Project copyAs(String newName) {
    final p = Project.create(
      name: newName,
      description: meta.description,
      dataset: dataset.copy(),
    );
    p.touch();
    return p;
  }
}
