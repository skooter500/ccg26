@tool
class_name CSGTopBlockoutBar extends HBoxContainer
## The plugin's part of the 3D editor toolbar: only actions that concern the whole
## level (grid, snap, check, play, freeze) and the "⋯" menu. The drawing tools and
## shapes live in the palette on the left (CSGSideBlockoutBar).

## Generic action from the bar's buttons/menus, dispatched by the plugin.
signal action_requested(action_id: StringName)

const MORE_SNAP_TO_GRID: int = 0
const MORE_CHECK_JUMP: int = 1
const MORE_EXPORT_LEGEND: int = 2
const MORE_REPEATER_REFRESH: int = 3
const MORE_REPEATER_BAKE: int = 4
const MORE_EXPORT_MESHLIB: int = 5
const MORE_EXPORT_GLTF: int = 6
const MORE_APPLY_GLTF: int = 7
const MORE_SHOW_DIMENSIONS: int = 8
const MORE_SHOW_RULERS: int = 9
const MORE_SHORTCUTS: int = 10

## [language_override value, menu label] for the "⋯ > Language" submenu.
const LANGUAGES: Array = [
	["auto", ""], ["en", "English"], ["zh_CN", "中文"], ["ja", "日本語"], ["ko", "한국어"],
	["es", "Español"], ["pt", "Português"], ["ru", "Русский"],
]

var _rulers_visible: bool = true
var _grid_option: OptionButton
var _snap_button: Button
var _more_button: MenuButton
var _freeze_button: Button
var _tag_menu: PopupMenu
var _language_menu: PopupMenu

func _init() -> void:
	name = "CsgBlockoutToolbar"

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_in_group(&"csg_blockout_ui"):
		add_to_group(&"csg_blockout_ui")
	var sel: EditorSelection = EditorInterface.get_selection()
	if sel and not sel.selection_changed.is_connected(_on_selection_changed):
		sel.selection_changed.connect(_on_selection_changed)
	if get_child_count() == 0:
		_build()
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	if not grid.changed.is_connected(_sync_grid_controls):
		grid.changed.connect(_sync_grid_controls)
	CsgBlockoutI18n.translate_node(self)
	_sync_grid_controls()
	_on_selection_changed()

## Grid size, snap, Check, Play, Freeze and "⋯". Flat buttons already have padding, so
## no extra gaps: Godot's own per-selection menus (e.g. "Mesh" for a frozen node)
## still fit on the same toolbar row.
func _build() -> void:
	add_theme_constant_override(&"separation", 0)
	_grid_option = OptionButton.new()
	_grid_option.name = "GridSize"
	_grid_option.flat = true
	_grid_option.focus_mode = Control.FOCUS_NONE
	_grid_option.set_meta("i18n_tooltip_key", "GRID_SIZE_TOOLTIP")
	# Compact: the popup still lists every size; the button only shows the current one.
	_grid_option.fit_to_longest_item = false
	_grid_option.custom_minimum_size.x = round(64.0 * (EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0))
	for s: float in CsgBlockoutGrid.SIZES:
		var label: String = ("%d m" % int(s)) if s >= 1.0 else ("%s m" % String.num(s, 3))
		_grid_option.add_item(label)
	_grid_option.item_selected.connect(_on_grid_size_selected)
	add_child(_grid_option)

	_snap_button = Button.new()
	_snap_button.name = "SnapToggle"
	_snap_button.flat = true
	_snap_button.toggle_mode = true
	_snap_button.focus_mode = Control.FOCUS_NONE
	_snap_button.set_meta("i18n_tooltip_key", "SNAP_TOOLTIP")
	_snap_button.icon = editor_icon(&"SnapGrid")
	_snap_button.toggled.connect(_on_snap_toggled)
	add_child(_snap_button)

	# Dimension labels are toggled from the "⋯" menu (view toggles there keep the bar
	# narrow enough to share a row with Godot's own per-selection menus).
	CsgBlockoutMeasureOverlay.load_state()
	_add_action_button(&"validate", editor_icon(&"StatusWarning"), "VALIDATE", "VALIDATE_TOOLTIP")
	_add_action_button(&"play_here", _plugin_icon("play_here.svg"), "PIE_PLAY", "PLAY_HERE_TOOLTIP")
	# One button whose icon follows the selection (freeze CSG / unfreeze frozen): its
	# width never changes, so the toolbar doesn't re-wrap.
	_freeze_button = _add_action_button(&"freeze_toggle", _freeze_icon(), "", "FREEZE_TOOLTIP")

	_more_button = MenuButton.new()
	_more_button.name = "MoreActions"
	_more_button.flat = true
	_more_button.text = "⋯"
	_more_button.set_meta("i18n_tooltip_key", "MORE_ACTIONS_TOOLTIP")
	_more_button.get_popup().id_pressed.connect(_on_more_id_pressed)
	_more_button.about_to_popup.connect(_update_more_menu_state)
	add_child(_more_button)
	_rebuild_more_menu()

## Plain (non-toggle) button that asks the plugin to run action `action_id`.
func _add_action_button(action_id: StringName, icon: Texture2D, text_key: String, tooltip_key: String) -> Button:
	var btn: Button = Button.new()
	btn.name = "Action_" + String(action_id)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.icon = icon
	if not text_key.is_empty():
		btn.text = CsgBlockoutI18n.t(text_key)
		btn.set_meta("i18n_text_key", text_key)
	btn.tooltip_text = CsgBlockoutI18n.t(tooltip_key)
	btn.set_meta("i18n_tooltip_key", tooltip_key)
	btn.pressed.connect(func() -> void: action_requested.emit(action_id))
	add_child(btn)
	return btn

## Built-in editor icon by name, or null outside the editor.
static func editor_icon(icon_name: StringName) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var theme: Theme = EditorInterface.get_editor_theme()
	if theme != null and theme.has_icon(icon_name, &"EditorIcons"):
		return theme.get_icon(icon_name, &"EditorIcons")
	return null

static func _plugin_icon(file_name: String) -> Texture2D:
	var path: String = CsgBlockoutConfig.plugin_path.path_join("res/icons").path_join(file_name)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _rebuild_more_menu() -> void:
	if _more_button == null:
		return
	var popup: PopupMenu = _more_button.get_popup()
	popup.clear()
	popup.add_check_item(CsgBlockoutI18n.t("SHOW_DIMENSIONS"), MORE_SHOW_DIMENSIONS)
	popup.set_item_tooltip(popup.get_item_index(MORE_SHOW_DIMENSIONS), CsgBlockoutI18n.t("DIMENSIONS_TOOLTIP"))
	popup.add_check_item(CsgBlockoutI18n.t("TOGGLE_RULERS"), MORE_SHOW_RULERS)
	popup.set_item_tooltip(popup.get_item_index(MORE_SHOW_RULERS), CsgBlockoutI18n.t("TOGGLE_RULERS_TOOLTIP"))
	popup.add_separator()
	popup.add_item(CsgBlockoutI18n.t("SNAP_SELECTION_TO_GRID"), MORE_SNAP_TO_GRID)
	popup.add_item(CsgBlockoutI18n.t("CHECK_JUMP_MENU"), MORE_CHECK_JUMP)
	popup.add_separator()
	if _tag_menu == null:
		_tag_menu = PopupMenu.new()
		_tag_menu.name = "TagMenu"
		_tag_menu.id_pressed.connect(_on_tag_id_pressed)
	_tag_menu.clear()
	for i: int in CsgBlockoutTags.TAGS.size():
		var tag: StringName = CsgBlockoutTags.TAGS[i]
		var swatch: GradientTexture2D = GradientTexture2D.new()
		swatch.width = 12
		swatch.height = 12
		swatch.gradient = Gradient.new()
		swatch.gradient.set_color(0, CsgBlockoutTags.COLORS[tag])
		swatch.gradient.set_color(1, CsgBlockoutTags.COLORS[tag])
		_tag_menu.add_icon_item(swatch, CsgBlockoutTags.label(tag), i)
	_tag_menu.add_separator()
	_tag_menu.add_item(CsgBlockoutI18n.t("TAG_CLEAR"), CsgBlockoutTags.TAGS.size())
	popup.add_submenu_node_item(CsgBlockoutI18n.t("TAG_MENU"), _tag_menu)
	popup.add_item(CsgBlockoutI18n.t("EXPORT_LEGEND"), MORE_EXPORT_LEGEND)
	popup.add_separator()
	popup.add_item(CsgBlockoutI18n.t("EXPORT_MESHLIB"), MORE_EXPORT_MESHLIB)
	popup.add_item(CsgBlockoutI18n.t("GLTF_EXPORT_MENU"), MORE_EXPORT_GLTF)
	popup.add_item(CsgBlockoutI18n.t("GLTF_APPLY_MENU"), MORE_APPLY_GLTF)
	popup.add_separator()
	popup.add_item("%s (Repeater/Spreader)" % CsgBlockoutI18n.t("REFRESH"), MORE_REPEATER_REFRESH)
	popup.add_item("%s (Repeater/Spreader)" % CsgBlockoutI18n.t("BAKE"), MORE_REPEATER_BAKE)
	popup.add_separator()
	popup.add_item(CsgBlockoutI18n.t("SHORTCUTS_MENU"), MORE_SHORTCUTS)
	if _language_menu == null:
		_language_menu = PopupMenu.new()
		_language_menu.name = "LanguageMenu"
		_language_menu.id_pressed.connect(_on_language_id_pressed)
	_language_menu.clear()
	for i: int in LANGUAGES.size():
		var label: String = LANGUAGES[i][1] if i > 0 else CsgBlockoutI18n.t("LANGUAGE_AUTO")
		_language_menu.add_radio_check_item(label, i)
	popup.add_submenu_node_item(CsgBlockoutI18n.t("LANGUAGE_MENU"), _language_menu)

## Greys out entries that don't apply to the current selection.
func _update_more_menu_state() -> void:
	var popup: PopupMenu = _more_button.get_popup()
	popup.set_item_checked(popup.get_item_index(MORE_SHOW_DIMENSIONS), CsgBlockoutMeasureOverlay.enabled)
	popup.set_item_checked(popup.get_item_index(MORE_SHOW_RULERS), _rulers_visible)
	var has_repeater: bool = EditorInterface.get_selection().get_selected_nodes().any(func(n: Node) -> bool: return n is CSGRepeater3D or n is CSGSpreader3D)
	for id: int in [MORE_REPEATER_REFRESH, MORE_REPEATER_BAKE]:
		var idx: int = popup.get_item_index(id)
		if idx >= 0:
			popup.set_item_disabled(idx, not has_repeater)
	var check_idx: int = popup.get_item_index(MORE_CHECK_JUMP)
	if check_idx >= 0:
		popup.set_item_disabled(check_idx, CsgBlockoutSelection.top_level_nodes().size() != 2)
	var meshlib_idx: int = popup.get_item_index(MORE_EXPORT_MESHLIB)
	if meshlib_idx >= 0:
		popup.set_item_disabled(meshlib_idx, CsgBlockoutMeshLibraryExport.selection_nodes().is_empty())
	var no_frozen: bool = CsgBlockoutGltfRoundTrip.selected_frozen().is_empty()
	for id: int in [MORE_EXPORT_GLTF, MORE_APPLY_GLTF]:
		var gltf_idx: int = popup.get_item_index(id)
		if gltf_idx >= 0:
			popup.set_item_disabled(gltf_idx, no_frozen)
	if _language_menu != null:
		var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
		var current: String = config.language_override if config else "auto"
		for i: int in LANGUAGES.size():
			var code: String = LANGUAGES[i][0]
			_language_menu.set_item_checked(i, current == code or (code == "zh_CN" and current == "zh") or (code == "auto" and current.is_empty()))

func _on_tag_id_pressed(id: int) -> void:
	var tag: StringName = CsgBlockoutTags.TAGS[id] if id < CsgBlockoutTags.TAGS.size() else &""
	CsgBlockoutTags.apply_to_selection(tag)

func _on_language_id_pressed(id: int) -> void:
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	if config == null or id < 0 or id >= LANGUAGES.size():
		return
	config.language_override = LANGUAGES[id][0]
	config.save_config()
	get_tree().call_group(&"csg_blockout_ui", &"update_language")

func _sync_grid_controls() -> void:
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	if _grid_option != null:
		var idx: int = CsgBlockoutGrid.SIZES.find(grid.size)
		if idx >= 0 and _grid_option.selected != idx:
			_grid_option.select(idx)
	if _snap_button != null:
		_snap_button.set_pressed_no_signal(grid.snap_enabled)

func _on_grid_size_selected(index: int) -> void:
	CsgBlockoutGrid.get_grid().set_size(CsgBlockoutGrid.SIZES[index])

func _on_snap_toggled(pressed: bool) -> void:
	CsgBlockoutGrid.get_grid().set_snap_enabled(pressed)

func _on_more_id_pressed(id: int) -> void:
	match id:
		MORE_SHOW_DIMENSIONS:
			CsgBlockoutMeasureOverlay.set_enabled(not CsgBlockoutMeasureOverlay.enabled)
			action_requested.emit(&"refresh_overlays")
		MORE_SHOW_RULERS:
			set_rulers_visible(not _rulers_visible)
		MORE_SNAP_TO_GRID:
			CsgBlockoutTransformHotkeys.snap_selection_to_grid()
		MORE_CHECK_JUMP:
			CsgBlockoutMeasureOverlay.check_jump_between_selection()
		MORE_EXPORT_LEGEND:
			CsgBlockoutTags.export_legend_with_dialog()
		MORE_EXPORT_MESHLIB:
			CsgBlockoutMeshLibraryExport.export_selection_with_dialog()
		MORE_EXPORT_GLTF:
			CsgBlockoutGltfRoundTrip.export_selection()
		MORE_APPLY_GLTF:
			CsgBlockoutGltfRoundTrip.apply_selection()
		MORE_REPEATER_REFRESH:
			_on_refresh_pressed()
		MORE_REPEATER_BAKE:
			_on_bake_pressed()
		MORE_SHORTCUTS:
			CsgBlockoutCheatSheet.popup()

func update_language() -> void:
	CsgBlockoutI18n.translate_node(self)
	_rebuild_more_menu()

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		return
	if is_in_group(&"csg_blockout_ui"):
		remove_from_group(&"csg_blockout_ui")
	var sel: EditorSelection = EditorInterface.get_selection()
	if sel and sel.selection_changed.is_connected(_on_selection_changed):
		sel.selection_changed.disconnect(_on_selection_changed)
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	if grid.changed.is_connected(_sync_grid_controls):
		grid.changed.disconnect(_sync_grid_controls)

func _on_selection_changed() -> void:
	if not Engine.is_editor_hint():
		return
	if _freeze_button == null:
		return
	var targets: Dictionary = CsgBlockoutFreeze.selection_targets()
	var can_unfreeze: bool = not (targets["frozen"] as Array).is_empty()
	var can_freeze: bool = not (targets["roots"] as Array).is_empty()
	_freeze_button.icon = _freeze_icon(can_unfreeze)
	_freeze_button.set_meta("i18n_tooltip_key", "UNFREEZE_TOOLTIP" if can_unfreeze else "FREEZE_TOOLTIP")
	_freeze_button.tooltip_text = CsgBlockoutI18n.t(_freeze_button.get_meta("i18n_tooltip_key"))
	_freeze_button.disabled = not (can_freeze or can_unfreeze)

static func _freeze_icon(unfreeze: bool = false) -> Texture2D:
	return _plugin_icon("unfreeze.svg" if unfreeze else "freeze.svg")

## Shows or hides every ruler in the edited scene.
func set_rulers_visible(on: bool) -> void:
	_rulers_visible = on
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_group(&"csg_rulers", &"visible", on)
		tree.call_group(&"csg_rulers", &"update_gizmos")

func _on_refresh_pressed() -> void:
	for node: Node in EditorInterface.get_selection().get_selected_nodes():
		if node is CSGRepeater3D:
			(node as CSGRepeater3D).repeat_template()
			break
		elif node is CSGSpreader3D:
			(node as CSGSpreader3D).spread_template()
			break

func _on_bake_pressed() -> void:
	for node: Node in EditorInterface.get_selection().get_selected_nodes():
		if node is CSGRepeater3D or node is CSGSpreader3D:
			if node.has_method(&"bake_instances"):
				node.call(&"bake_instances")
			break
