# 数据变换

入口：**工程工作区 → 变换**，或数据页菜单「数据变换…」。变换直接作用在当前数据集上。

## 支持的变换

| 命令 | 作用 |
|------|------|
| **COMPUTE** | 用表达式计算新变量（支持 + - * / 与 abs sqrt ln exp log10 sin cos tan round trunc） |
| **RECODE** | 按 `旧值=新值` 规则重编码 |
| **AUTORECODE** | 把取值（数值或字符串）编码为 1..k 的数值码并自动加值标签 |
| **COUNT** | 统计满足匹配值的变量个数 |
| **RANK** | 生成秩、百分位、正态得分、n 分位组等派生于秩的变量 |
| **SAMPLE** | 随机抽取个案（按比例，或「n FROM N」精确抽 n 个） |
| **SORT CASES** | 按一个或多个变量排序 |
| **SELECT IF** | 按条件筛选个案（`>` `<` `==` `!=` `&&` `||`） |
| **AGGREGATE** | 按分组变量汇总均值 |
| **FLIP** | 行列转置 |
| **COMBINE FILES** | 与另一个数据集纵向追加（ADD FILES）或按键横向匹配（MATCH FILES） |

## RANK：派生于秩的变量

```text
RANK VARIABLES=score (A) /RANK /TIES=MEAN.
RANK VARIABLES=score (D) /NTILES(4) /INTO=quartile.
```

- 变量后的 `(A)` / `(D)` 指定升序 / 降序，默认升序；
- 输出函数可同时写多个：

  | 选项 | 含义 |
  |------|------|
  | `/RANK` | 秩 |
  | `/N` | 结内的个案数 |
  | `/RFRACTION` | 秩 / 有效个案数 |
  | `/PROPORTION` | Blom 比例 `(r − 3/8) / (w + 1/4)` |
  | `/PERCENT` | 百分位 `r · 100 / w` |
  | `/NORMAL` | 比例的正态得分 Φ⁻¹ |
  | `/NTILES(k)` | n 分位组 1..k |

- `/TIES=MEAN|LOW|HIGH|CONDENSE` 决定并列取值的秩（平均 / 取小 / 取大 / 压缩），默认 `MEAN` 即常见的「平均秩」；
- `/INTO=名字` 指定目标变量名，默认按函数取名（`R_` / `N_` / `RF_` / `PR_` / `P_` / `Z_` / `NT_` 前缀）；
- 缺失个案（含用户缺失值）不参与排序，结果为空。

## AUTORECODE：字符串与数值统一编码

```text
AUTORECODE VARIABLES=city /INTO=city_n.
AUTORECODE VARIABLES=a b c /INTO=x y z /GROUP /DESCENDING.
```

- 逐个源变量把所有非空取值升序编号 1..k（`/DESCENDING` 改为降序），并自动加值标签（优先用取值已有的值标签，其次用显示文本）；
- **用户缺失值也参与编码，但恒排在最后**（取最大的若干码），并在目标变量上标为缺失；缺失码超过 3 个时自动改用**缺失范围**（与 PSPP 一致）；
- `/GROUP` 时所有源变量共用同一张编码表（要求类型一致）；
- 目标变量为整数、名义尺度，沿用源变量的变量标签。

## SAMPLE：抽样

```text
SAMPLE 0.5.            * 每个个案以 50% 概率保留（个数不固定）
SAMPLE 5 FROM 10.      * 在前 10 个个案里等概率地恰好留 5 个
SAMPLE 0.5 /SEED=42.   * 固定随机种子，同一种子结果可复现
```

## MRSETS：多重响应集

```text
MRSETS /MDGROUP NAME=$brands LABEL='常购品牌' VARIABLES=q1a q1b q1c VALUE=1.
MRSETS /MCGROUP NAME=$colors VARIABLES=c1 c2 c3.
MRSETS /DISPLAY NAME=ALL.
MRSETS /FREQUENCIES NAME=$brands.
MRSETS /CROSSTABS NAME=$brands BY=gender.
```

- `MDGROUP`（多分类二分集）：按 `VALUE=` 判定某个变量算不算「选中」；
- `MCGROUP`（多分类集）：每个变量的取值本身就是一个响应；
- 定义后可用 `/DISPLAY` 查看、`/FREQUENCIES` 出响应频数、`/CROSSTABS ... BY=分组变量` 出响应 × 分组表（PSPP 里这两张表由 CTABLES 提供，这里是应用的扩展写法）；
- 响应表同时给出**应答数**与**应答个案数**两个分母；计数不加权（加权口径见[缺失值口径](/guide/missing-values)）；
- `/DELETE NAME=$m|ALL` 删除定义；同名重复定义会覆盖（与 PSPP 的 `dict_add_mrset` 一致）。

## COMBINE FILES：合并数据集

```text
ADD FILES /FILE=* /FILE=其它文件 /IN=来源.
MATCH FILES /FILE=* /TABLE=查表文件 /BY 编号.
```

- `ADD FILES` 把两个数据集的个案纵向追加（变量按名字对齐，缺的补空）；
- `MATCH FILES` 用 `/BY` 键把另一个数据集横向匹配进来（哈希连接，不要求输入已排序）；
- `/IN=变量` 生成 0/1 来源指示变量；`/KEEP`、`/DROP`、`/RENAME=(旧=新)` 可调整变量；
- 字典按 PSPP `merge_dictionaries` 的规则对齐：先出现的文件定义的变量胜出，后面的文件只补空缺；字符串宽度取最大；类型冲突报错；`MATCH TABLES` 里重复键取先出现的个案；
- 语法编辑器顶部可「附加数据集」把另一个 `.sav` / 工程文件挂进来，命令行里的 `*` 代表当前数据集；数据页菜单也提供图形化的「合并数据集…」。

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
AUTORECODE VARIABLES=city /INTO=city_n.
RANK VARIABLES=post (A) /RANK /NTILES(4).
SAMPLE 0.5 /SEED=20261016.
MRSETS /MDGROUP NAME=$m VARIABLES=a b VALUE=1.
ADD FILES /FILE=* /FILE=其它文件.
MATCH FILES /FILE=* /TABLE=查表文件 /BY 编号.
SORT CASES BY post DESCENDING.
SELECT IF post >= 70.
LIST.
HELP.
```

编辑器顶部有命令模板条，点击即可插入；输出面板显示每个命令的执行结果。整行以 `*` 开头的是注释。

注释语义、宏、`INCLUDE`、错误定位与 `.sps` 往返见[语法语言](/guide/syntax)。

## 其他数据操作

数据页菜单还提供：

- **加权个案** WEIGHT CASES
- **拆分文件** SPLIT FILE
- **查找个案**
- CSV 导入 / 导出
