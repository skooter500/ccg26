# Contributing to CSG_Blockout

[简体中文](CONTRIBUTING_CN.md)

Thanks for helping out. Bug reports, feature ideas, translations, demo clips, and pull requests are all welcome.

---

## What this project is (and isn't)

CSG_Blockout is a **level prototyping** tool, not a modeling tool. Everything it builds stays a native, non-destructive Godot CSG node, and the goal is to go from the first box to a playable test without leaving the node tree.

To keep that focus, the following are **out of scope**, and requests for them will be closed:

- General vertex/edge editing (that means writing a geometry kernel; dedicated brush editors already do this well).
- Per-face UV editing (CSG materials are per-primitive; forcing per-face UVs would break the data model).
- Importing `.map` files (converting them produces hundreds of CSG nodes and a poor editing experience).

Not sure whether your idea fits? Open a feature request and ask; that's what it's for.

---

## Reporting a bug

Use the **Bug report** issue template. The most useful reports include:

- Godot version (Help → About, e.g. `4.7.stable`) and plugin version (`plugin.cfg`, or the Plugins list in Project Settings).
- Operating system.
- Exact steps to reproduce, starting from an empty scene if possible.
- What you expected, and what happened instead.
- Any errors from the **Output** and **Debugger → Errors** panels.
- A minimal `.tscn` that shows the problem, if you can share one.

---

## Development setup

1. Create (or open) a Godot **4.6+** project.
2. Clone your fork into the project's addons folder:
   ```bash
   git clone https://github.com/<your-name>/Godot-CSG-Blockout.git addons/csg_blockout
   ```
3. Enable **CSG_Blockout** in **Project → Project Settings → Plugins**.
4. `scenes/demo.tscn` is a handy scene for trying things out.
5. After editing `@tool` scripts or the plugin entry script, toggle the plugin off and on, or use **Project → Reload Current Project**, so the editor picks up the changes.

---

## Code conventions

The codebase supports **Godot 4.6 and later** (it is developed on 4.7) with **GDScript 2.0**; calls that differ between engine versions go through `scripts/core/csg_compat.gd`. Please follow these rules so changes stay consistent with the rest of the plugin:

**Typing and syntax**
- Static typing everywhere. No untyped variables. Containers are typed: `Array[Type]`, `Dictionary[KeyType, ValueType]` (use `Variant` explicitly for mixed values).
- Use `&"literal"` `StringName`s for frequently used keys and metadata.
- Connect signals with `signal.connect(callable)`, never by string name.
- Inspector buttons use `@export_tool_button("Label") var btn: Callable = _callback`.
- Promote magic numbers to `const`.

**Architecture**
- Call down, signal up. Don't use `get_parent()` or `get_node("../..")`; children notify parents through signals.
- Setters on procedural nodes must not rebuild CSG directly. Set `_dirty = true` and rebuild in `_process`, throttled by a `REGEN_THROTTLE_MS` timestamp.
- Gate editor-only logic with `if not Engine.is_editor_hint(): return`.
- Procedural preview instances must **not** get an `owner`, so they aren't saved into the scene. Only set `node.owner = get_tree().edited_scene_root` (after `add_child()`) when baking or creating a real scene node.
- Any change to the scene tree triggered from the viewport or plugin UI must go through `EditorUndoRedoManager` as a single do/undo action.
- Check cross-frame or external node references with `is_instance_valid(node)` before using them.
- Pattern algorithms are `Resource`s (`CSGPattern`). Before swapping one, disconnect the old one's `changed` signal: `if res.changed.is_connected(cb): res.changed.disconnect(cb)`.

**Shared facilities**
- All user-facing text goes through `CsgBlockoutI18n.t("KEY")` (or `tf()` for formatted strings).
- All settings go through `CsgBlockoutConfig.get_config()`; new settings live under `addons/csg_blockout/`.

---

## Translations

UI strings live in the `TABLE` dictionary in `scripts/csg_blockout_i18n.gd`. Every key needs all 7 languages: `zh`, `en`, `ja`, `ko`, `es`, `pt`, `ru`.

- When adding a key, fill in all 7. Machine translation is fine as a starting point; just say so in the PR so native speakers can review it.
- Corrections to existing translations are very welcome, even as tiny PRs.

---

## Documentation

- User-facing docs come in pairs: `README.md` / `README_CN.md`, `TUTORIAL_EN.md` / `TUTORIAL_CN.md`, `ARCHITECTURE.md` / `ARCHITECTURE_CN.md`. If you change one, update the other too (or say in the PR that you need help with the other language).
- Add an entry under `## [Unreleased]` in `CHANGELOG.md` for any user-visible change. Describe what users will notice, not how it's implemented.
- New or changed node properties and Project Settings go in the API tables in both `ARCHITECTURE` files.

---

## Pull requests

1. Fork, then branch from `main`.
2. Keep each PR to one topic. A bug fix and an unrelated refactor should be two PRs.
3. Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a scope, as in the existing history, e.g. `fix(pie-menu): ...`, `feat(stairs): ...`, `docs(readme): ...`.
4. Test in the editor: try the change, undo it with `Ctrl + Z`, redo it with `Ctrl + Y`, then save and reopen the scene.
5. For UI or viewport changes, attach a screenshot or short clip to the PR.
6. Fill in the pull request template.

Small, focused PRs get reviewed fastest. For larger features, open an issue first so we can agree on the approach before you spend time on it.

---

## License

By contributing, you agree that your contributions are licensed under the project's [MIT License](LICENSE).
