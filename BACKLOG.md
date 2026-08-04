# Backlog

## XIB → Code 迁移（剩余 20 个）

> 背景：项目正分批把所有 XIB 改成代码 + Masonry 布局。已完成 4 个 batch，覆盖最常见
> 的 Search / Info / Me / Bill / Detail 等模块。详见 `CLAUDE.md` 的 Layout 段。
>
> 每个 XIB 都是 dark mode / i18n 隐患（XIB 烤死 sRGB 静态色 + 文案不进 wrap 脚本）。
> 顺手转 — 触到某个 view 改别的东西时一并迁。

### Batch 5 — AddCategory 模块（3 个）

> 包含一个 UICollectionView 用 cell + reusable header + 一个自定义输入框。需要先
> 熟悉 collection view 注册流程。

- [ ] `Modules/AddCategory/View/ACACollectionCell.xib`
- [ ] `Modules/AddCategory/View/ACAReusableHeader.xib`
- [ ] `Modules/AddCategory/View/ACATextField.xib`

### Batch 6 — Chart 模块残余（6 个）

> 这 6 个 XIB 文件在 runtime 都已经被 `.m` 的 `initUI`/`setBackgroundColor:` 覆盖了
> 关键色，所以**没有视觉 bug**。但 XIB 仍留着 → 是死代码 + 维护风险（IBOutlet
> drift 沉默）。优先级低于 Batch 5。

- [ ] `Modules/Chart/View/BookChart/BCHUDContentCell.xib`（已显式 setTextColor 覆盖白字）
- [ ] `Modules/Chart/View/Date/ChartDateCell.xib`（无色 baked）
- [ ] `Modules/Chart/View/HUD/ChartHUDCell.xib`（无色 baked）
- [ ] `Modules/Chart/View/Navigation/ChartNavigation.xib`（runtime bg = 主色绿）
- [ ] `Modules/Chart/View/SegmentControl/ChartSegmentControl.xib`（runtime bg = 主色绿）
- [ ] `Modules/Chart/View/Table/ChartSectionHeader.xib`（已显式 setBackgroundColor 覆盖白底）

### Batch 7 — Detail / Home / Share（5 个）

- [ ] `Modules/Detail/View/BDHeader.xib` — 账单详情顶部 header
- [ ] `Modules/Home/View/Navigation/HomeNavigation.xib` — 首页顶 bar
- [ ] `Modules/Share/View/ShareBadge.xib` — 分享图徽章
- [ ] `Modules/Share/View/ShareOrder.xib` — 分享图单条
- [ ] `Modules/Share/View/ShareShot.xib` — 分享截图容器

### Batch 8 — 杂项模块（5 个）

- [ ] `Common/Empty/View/KKGoodsEmpty.xib` — 全局空态视图
- [x] `Modules/Book/View/Keyboard/BKCKeyboard.xib` — 记账数字键盘（2026-08-04 已迁移：
      buildSubviews 代码布局，textContent frame 定位 + 内部 Auto Layout，按钮栅格 frame 计算；
      模拟器截图验证过。顺带删掉了多币种插入时的"运行时拆 XIB 约束"hack）
- [ ] `Modules/Book/View/Mark/MarkCollectionViewCell.xib` — 备注标签 cell
- [ ] `Modules/Category/View/CAHeader.xib` — 类别页 header
- [ ] `Modules/Category/View/CategoryCell.xib` — 类别 cell

### Batch 9 — RegisterController（1 个，最大）

> 唯一一个用 XIB 拼整个 Controller 的（不是单个 view）。包含布局 + 多个 outlet +
> 事件。工作量最大，建议单独一个 batch。

- [ ] `Modules/Register/Controller/RegisterController.xib`

---

## 迁移参考

- 转换模板见 commit history：`0192bf1` (batch 1) / `7f28f54` (batch 2) /
  `fc59ce5` (batch 3) / `2f0498a` (batch 4)
- 取消 `loadFirstNib:` → `loadCode:` / `alloc-init` / `initWithStyle:`
- pbxproj 每个 XIB 要清 4 条引用（`PBXBuildFile` 2 条 + `PBXFileReference` 1 条 + `PBXResourcesBuildPhase` 1 条）
- 颜色：所有静态 sRGB → `KKDynamicColor` / `systemBackgroundColor` /
  `secondarySystemGroupedBackgroundColor` 等（dark mode 适配）
- 文案：所有中文 → `KKLocalized(@"...")` （wrap 脚本只扫 `.m/.h`）
