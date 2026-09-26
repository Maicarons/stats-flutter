# 数据变换

对应 PSPP 的 Transform 菜单，入口：**工程工作区 → 变换**，或数据页菜单「数据变换…」。

## 支持的变换

| 命令 | 作用 |
|------|------|
| **COMPUTE** | 用表达式计算新变量（支持 + - * / 与 abs sqrt ln exp log10 sin cos tan round trunc） |
| **RECODE** | 按 `旧值=新值` 规则重编码 |
| **COUNT** | 统计满足匹配值的变量个数 |
| **RANK** | 生成秩次变量（可降序） |
| **SORT CASES** | 按一个或多个变量排序 |
| **SELECT IF** | 按条件筛选个案（`>` `<` `==` `!=` `&&` `||`） |
| **AGGREGATE** | 按分组变量汇总均值 |
| **FLIP** | 行列转置 |

## 语法编辑器

入口：数据页菜单 →「语法编辑器…」

可执行子集（句点结尾）：

```text
DESCRIPTIVES pre post hours.
FREQUENCIES gender method.
T-TEST /TESTVAL=60 /VARIABLES=post.
CORRELATIONS /VARIABLES=pre post hours.
COMPUTE gain = post - pre.
RECODE gender (1=0) (2=1) INTO sex.
SORT CASES BY post DESCENDING.
SELECT IF post >= 70.
LIST.
HELP.
```

编辑器顶部有命令模板条，点击即可插入。输出面板显示每个命令的执行结果。

## 其他数据操作

数据页菜单还提供：

- **加权个案** WEIGHT CASES
- **拆分文件** SPLIT FILE
- **查找个案**
- CSV 导入 / 导出
