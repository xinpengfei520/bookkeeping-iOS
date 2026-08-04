# Backlog

## XIB → Code 迁移 ✅ 已全部完成（2026-08-04）

> 20 个遗留 XIB 已在 Batch 4–9 分批迁完，工程内不再有任何 .xib。
> Batch 9 的 RegisterController 确认是零引用死代码，整个 Modules/Register/ 模块直接删除
> （git 历史可找回）。统一模式：init → buildSubviews(Masonry) → initUI → set*；
> cell 用 registerClass: 注册，普通视图用 loadCode:。

## 迁移参考

- 转换模板见 commit history：`0192bf1` (batch 1) / `7f28f54` (batch 2) /
  `fc59ce5` (batch 3) / `2f0498a` (batch 4)
- 取消 `loadFirstNib:` → `loadCode:` / `alloc-init` / `initWithStyle:`
- pbxproj 每个 XIB 要清 4 条引用（`PBXBuildFile` 2 条 + `PBXFileReference` 1 条 + `PBXResourcesBuildPhase` 1 条）
- 颜色：所有静态 sRGB → `KKDynamicColor` / `systemBackgroundColor` /
  `secondarySystemGroupedBackgroundColor` 等（dark mode 适配）
- 文案：所有中文 → `KKLocalized(@"...")` （wrap 脚本只扫 `.m/.h`）
