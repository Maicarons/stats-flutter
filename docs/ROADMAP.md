# Roadmap — Stats-flutter 下一步发展

对照 GNU PSPP 2.1.2（`_ref/pspp-2.1.2`）与当前实现的差距，以及产品演进优先级。

---

## 一、总体定位（已完成的基础）

| 层 | 状态 |
|----|------|
| 工程化数据管理 | ✅ 多工程、持久化、表格编辑 |
| 统计内核 statkit | ✅ 已发 pub.dev 0.1.0 |
| 主分析流程 | ✅ 描述 / t / ANOVA / 相关 / 回归 / 非参数 / 信度 / 聚类 |
| 学习 + 测试 | ✅ 8 课 + 20 题 |
| 发布体系 | ✅ GitHub Pages 文档、pub OIDC 发布 CI |

---

## 二、相对 PSPP 仍未搬完的能力（按影响排序）

### A. 数据层（PSPP 语言核心）— 影响：高

| PSPP 命令 | 现状 | 说明 |
|-----------|------|------|
| `WEIGHT CASES` 语义 | ❌ 只存变量，分析未加权 | 所有估计量应支持频数权 |
| `SPLIT FILE` 语义 | ❌ 只存变量，分析未分组跑 | 分组重复输出 |
| `SAMPLE` | ❌ | 随机抽样 |
| `AUTORECODE` | ❌ | 字符串→数值码 |
| `RANK`（百分位/正态分） | 🔶 仅简单秩 | 缺 %ile、NTILES |
| `RENAME / DELETE VARIABLES` | 🔶 UI 可删，语法未接 | |
| `TEMPORARY` | ❌ | 临时变换作用域 |
| `DO IF / LOOP / REPEAT` | ❌ | 程序流 |
| `VECTOR` | ❌ | 变量组 |
| `APPLY DICTIONARY` | ❌ | 字典复用 |
| `COMBINE FILES`（ADD/MATCH） | ❌ | 合并数据集 |
| `MRSETS` 多重响应 | ❌ | |
| `GET / SAVE`（.sav） | ❌ | **SPSS 互通关键** |
| `GET DATA` Excel/ODS | ❌ 仅 CSV | |

### B. 统计过程 — 影响：高

| 过程 | 现状 | 缺口 |
|------|------|------|
| **EXAMINE** | 🔶 仅偏度峰度+KS | 茎叶、箱线、极值表、Q-Q、百分位表 |
| **GLM** | ❌ | 析因 / 多元方差、交互效应 |
| **FACTOR** | 🔶 PCA | 方差最大旋转、PAF、KMO/Bartlett、碎石图、共同度 |
| **LOGISTIC** | 🔶 梯度下降 | SE/Wald/OR CI、分类表、逐步回归、多类 |
| **CTABLES** | ❌ | PSPP 旗舰表引擎（大工程） |
| **GRAPH** | 🔶 直方/条/散 | 箱线、饼图、误差条、Q-Q 图 |
| NPAR 完整集 | 🔶 | BINOMIAL、COCHRAN、FRIEDMAN、KENDALL、MCNEMAR、MEDIAN、KS 精确、Jonckheere-Terpstra |
| 精确检验 | ❌ | Fisher 精确、置换 p |
| 中介 / 多元 | ❌ | 更远期 |

### C. 语法与输出 — 影响：中

| 项 | 现状 | 缺口 |
|----|------|------|
| 语法执行器 | 🔶 子集 | 多数命令、注释、宏 `DEFINE`、`INCLUDE` |
| 语法编辑器 | 🔶 | 语法高亮、.sps 打开/保存、错误跳转 |
| 输出管理 | 🔶 文本报告 | 表样式、导出 PDF/HTML/ODS、输出树 |
| 用户缺失值 | 🔶 可设置 | **分析时按用户缺失值排除**未完全贯通 |

### D. 工程与产品 — 影响：中

| 项 | 说明 |
|----|------|
| 大数据性能 | ListView 虚拟化已有，万行级需基准 |
| 撤销/重做 | 数据编辑 |
| 自动保存 | 工作区定时保存 |
| 多语言文案 | 分析报告硬编码中文 |
| 移动端适配 | 表格手势、窄屏对话框 |
| 单元/黄金测试 | 报告输出回归测试 |

---

## 三、建议版本路线

### v0.2.0 — 权重与语义补全（statkit）✅ 已完成
1. `WeightedDescriptives` / 加权 t、方差、相关
2. `splitGroups()` 辅助 + 分组跑分析
3. 补 NPAR：BINOMIAL、KENDALL、MCNEMAR、FRIEDMAN、COCHRAN
4. 精确二项 / Fisher（小样本）
5. 更多单测 + 基准

### v0.3.0 — 探索性分析
1. **EXAMINE 全套**：百分位、极值、茎叶、箱线图数据
2. 图表：箱线、误差条、Q-Q
3. 正态性：Shapiro-Wilk 近似或完整 KS-Lilliefors
4. FACTOR：varimax、KMO、Bartlett、碎石

### v0.4.0 — 模型增强
1. LOGISTIC：Wald、OR CI、分类表、Hosmer-Lemeshow
2. GLM 单元/双元 ANOVA（固定效应）
3. 逐步回归（前进/后退）
4. CTABLES 简化版（透视汇总表）

### v1.1.0 — 互通与工程流 ✅ 已完成
1. **SPSS .sav 读写**（`pspp-dump-sav` 文档 + 格式说明）
2. Excel 导入
3. 语法高亮 + .sps 工程文件
4. 报告导出 PDF / HTML
5. 用户缺失值在全部过程中生效

### v1.2.0 — 体验
1. 撤销/重做、自动保存
2. 报告 i18n
3. 移动端手势优化
4. 大数据基准（10万行）

---

## 四、技术债与质量

| 项 | 建议 |
|----|------|
| CI | 补 `dart test` 矩阵、覆盖率 |
| 依赖告警 | 处理 Dependabot 1 high / 3 moderate |
| 统计正确性 | 与 PSPP/SPSS 已知例对拍（`examples/*.sps`） |
| API 稳定 | statkit 0.2 后锁定公开 API，标注 experimental |
| 文档 | 每个新过程同步 zh/en + 用例 |

## 五、优先级结论

**若继续「完整搬运 PSPP」：**  
优先顺序建议 → **权重/拆分语义 → EXAMINE → .sav 互通 → NPAR 补全 → FACTOR 旋转 → GLM/CTABLES**。

**若做产品差异化：**  
学习测试模块做成「课→练→分析」闭环，比死磕 CTABLES 更有传播价值；`.sav` 互通是采用率关键。

主路线推荐：**v0.2 权重与 NPAR 补全 → v0.3 EXAMINE+图 → v1.1 .sav**，其余按反馈插队。
