# 参与贡献 CSG_Blockout

[English](CONTRIBUTING.md)

感谢你愿意帮忙。问题反馈、功能建议、翻译、演示动图和 Pull Request 都欢迎。

---

## 项目定位（以及不做什么）

CSG_Blockout 是**关卡原型**工具，不是建模工具。它搭出来的一切都是原生、非破坏性的 Godot CSG 节点，目标是从画出第一个盒子到用角色跑进去验证，全程不离开节点树。

为了保持这个定位，以下需求**不在范围内**，相关 issue 会被关闭：

- 通用顶点/边编辑（那等于自己写几何内核，专门的笔刷编辑器已经做得很好）。
- 逐面 UV 编辑（CSG 的材质是按图元分配的，硬做逐面 UV 会破坏数据模型）。
- 导入 `.map` 文件（转出来是几百个 CSG 节点，编辑体验很差）。

拿不准自己的想法算不算？开一个功能建议问问就好，模板就是为此准备的。

---

## 反馈问题

请使用 **Bug report** issue 模板。最有用的反馈包含：

- Godot 版本（帮助 → 关于，例如 `4.7.stable`）和插件版本（`plugin.cfg`，或项目设置的插件列表）。
- 操作系统。
- 精确的复现步骤，最好从空场景开始。
- 你预期的结果，以及实际发生了什么。
- **输出 (Output)** 面板和 **调试器 → 错误** 面板里的报错。
- 如果方便，附一个能复现问题的最小 `.tscn`。

---

## 开发环境

1. 新建（或打开）一个 Godot **4.6+** 项目。
2. 把你的 fork 克隆到项目的 addons 目录：
   ```bash
   git clone https://github.com/<your-name>/Godot-CSG-Blockout.git addons/csg_blockout
   ```
3. 在 **项目 → 项目设置 → 插件** 中启用 **CSG_Blockout**。
4. `scenes/demo.tscn` 可以直接拿来试功能。
5. 修改 `@tool` 脚本或插件入口脚本后，把插件关掉再打开，或使用 **项目 → 重新加载当前项目**，让编辑器加载最新代码。

---

## 代码规范

代码支持 **Godot 4.6 及以上**（在 4.7 上开发），使用 **GDScript 2.0**；不同引擎版本间有差异的调用统一走 `scripts/core/csg_compat.gd`。请遵守以下规则，让改动和插件其余部分保持一致：

**类型与语法**
- 全部静态类型，不允许无类型变量。容器必须带类型：`Array[Type]`、`Dictionary[KeyType, ValueType]`（混合类型的值显式写 `Variant`）。
- 高频使用的键和元数据用 `&"literal"` 形式的 `StringName`。
- 信号用 `signal.connect(callable)` 连接，不用字符串名。
- Inspector 按钮统一写成 `@export_tool_button("Label") var btn: Callable = _callback`。
- 魔数一律提升为 `const`。

**架构**
- 父调子，子发信号。不用 `get_parent()` 或 `get_node("../..")`，子节点通过信号通知父节点。
- 程序化节点的 setter 不能直接重建 CSG：只设 `_dirty = true`，在 `_process` 里按 `REGEN_THROTTLE_MS` 时间戳节流重建。
- 编辑器专用逻辑用 `if not Engine.is_editor_hint(): return` 隔离。
- 程序化预览实例**不能**设置 `owner`，以免被存进场景文件。只有在烘焙或创建真正的场景节点时，才在 `add_child()` 之后设置 `node.owner = get_tree().edited_scene_root`。
- 由视口或插件 UI 引起的场景树改动，必须通过 `EditorUndoRedoManager` 作为一个完整的 do/undo 操作提交。
- 跨帧或外部节点引用，使用前先用 `is_instance_valid(node)` 检查。
- 排布算法是 `Resource`（`CSGPattern`）。替换前先断开旧资源的 `changed` 信号：`if res.changed.is_connected(cb): res.changed.disconnect(cb)`。

**统一入口**
- 所有面向用户的文字都走 `CsgBlockoutI18n.t("KEY")`（带参数的用 `tf()`）。
- 所有配置都走 `CsgBlockoutConfig.get_config()`；新配置项放在 `addons/csg_blockout/` 下。

---

## 翻译

界面文字在 `scripts/csg_blockout_i18n.gd` 的 `TABLE` 字典里。每个键都需要 7 种语言：`zh`、`en`、`ja`、`ko`、`es`、`pt`、`ru`。

- 新增键时 7 种语言都要填。可以先用机器翻译，在 PR 里注明即可，方便母语者校对。
- 非常欢迎修正现有翻译，哪怕只改一个词也可以提 PR。

---

## 文档

- 面向用户的文档成对出现：`README.md` / `README_CN.md`、`TUTORIAL_EN.md` / `TUTORIAL_CN.md`、`ARCHITECTURE.md` / `ARCHITECTURE_CN.md`。改了其中一个，请同步另一个（或在 PR 里说明需要别人帮忙补另一种语言）。
- 任何用户能感知到的改动，都在 `CHANGELOG.md` 的 `## [Unreleased]` 下加一条。写用户会注意到什么，而不是怎么实现的。
- 新增或修改的节点属性、项目设置，要写进两份 `ARCHITECTURE` 文档的 API 表格。

---

## Pull Request

1. Fork 后从 `main` 拉分支。
2. 一个 PR 只做一件事。修 bug 和无关的重构请拆成两个 PR。
3. 提交信息遵循带 scope 的 [Conventional Commits](https://www.conventionalcommits.org/)，与现有历史一致，例如 `fix(pie-menu): ...`、`feat(stairs): ...`、`docs(readme): ...`。
4. 在编辑器里测一遍：执行改动，`Ctrl + Z` 撤销，`Ctrl + Y` 重做，再保存并重新打开场景。
5. 涉及 UI 或视口的改动，请在 PR 里附截图或短视频。
6. 填写 PR 模板。

小而聚焦的 PR 审得最快。较大的功能请先开 issue，把方案对齐了再动手，免得白费功夫。

---

## 协议

提交贡献即表示你同意以本项目的 [MIT License](LICENSE) 授权你的贡献。
