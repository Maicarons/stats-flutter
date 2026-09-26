from pathlib import Path

def rep(path, a, b, label):
    p = Path(path)
    t = p.read_text(encoding="utf-8")
    if a not in t:
        print("WARN", label)
        return
    p.write_text(t.replace(a, b), encoding="utf-8")
    print("ok", label)

root = Path(r"F:\workspace\stats-flutter")
lp = root / r"lib\features\projects\project_list_page.dart"

rep(
    lp,
    "import '../home/home_shell.dart';",
    "import 'project_workspace_page.dart';",
    "import workspace",
)

rep(
    lp,
    """class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});""",
    """class ProjectListPage extends StatefulWidget {
  /// true: embedded in global shell
  final bool embedded;
  const ProjectListPage({super.key, this.embedded = true});""",
    "ctor",
)

rep(
    lp,
    """        builder: (_) => HomeShell(
          project: p,
          onExit: () => projectStore.closeCurrent(),
        ),""",
    "        builder: (_) => ProjectWorkspacePage(project: p),",
    "open workspace",
)

sp = root / r"lib\features\splash\splash_page.dart"
rep(
    sp,
    "import '../projects/project_list_page.dart';",
    "import '../home/home_shell.dart';",
    "splash import",
)
rep(
    sp,
    "child: const ProjectListPage(),",
    "child: const HomeShell(),",
    "splash nav",
)

print("done")
