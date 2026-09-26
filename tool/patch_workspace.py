from pathlib import Path

# Make key pages accept optional Project and support embedded (no AppBar) mode.

# 1) DataEditorPage
p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")

# constructor
t = t.replace(
    "class DataEditorPage extends StatefulWidget {\n  const DataEditorPage({super.key});",
    """class DataEditorPage extends StatefulWidget {
  /// embedded=true 时不画外层 Scaffold/AppBar（作为工作区 Tab）
  final bool embedded;
  final dynamic project;

  const DataEditorPage({super.key, this.embedded = true, this.project});""",
)

# wrap Scaffold body when embedded - easier: always use body without appbar when embedded
old_build_start = """  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(ds.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: ["""
new_build_start = """  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final actions = ["""
if old_build_start in t:
    t = t.replace(old_build_start, new_build_start)
    print("data build start")
else:
    print("WARN data build start")

# close actions list and build body
old_actions_end = """        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l10n.dataView),
            Tab(text: l10n.variableView),
          ],
        ),
      ),
      body: Column("""
new_actions_end = """    ];
    final body = Column("""
if old_actions_end in t:
    t = t.replace(old_actions_end, new_actions_end)
    print("data actions end")
else:
    print("WARN data actions end")

# FAB + return
old_fab = """      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCase(l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCase),
      ),
    );
  }"""
new_fab = """    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(ds.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              actions: actions,
              bottom: TabBar(
                controller: _tab,
                tabs: [
                  Tab(text: l10n.dataView),
                  Tab(text: l10n.variableView),
                ],
              ),
            ),
      body: widget.embedded
          ? Column(
              children: [
                TabBar(
                  controller: _tab,
                  tabs: [
                    Tab(text: l10n.dataView),
                    Tab(text: l10n.variableView),
                  ],
                ),
                Expanded(child: body),
              ],
            )
          : body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCase(l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCase),
      ),
    );
  }"""
if old_fab in t:
    t = t.replace(old_fab, new_fab)
    print("data fab")
else:
    print("WARN data fab")

p.write_text(t, encoding="utf-8")
print("data_editor patched")
