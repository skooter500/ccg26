@tool
class_name CsgBlockoutFrozenInspector
extends EditorInspectorPlugin
## Inspector panel for frozen blockout: bake options (collision type, lightmap UV2,
## occluder, LODs), rebake in place, unfreeze, and the glTF round trip.

const COLLISION_KEYS: Dictionary = {
	"auto": "COLLISION_AUTO",
	"none": "COLLISION_NONE",
	"trimesh": "COLLISION_TRIMESH",
	"primitives": "COLLISION_PRIMITIVES",
	"convex": "COLLISION_CONVEX",
}

func _can_handle(object: Object) -> bool:
	return object is MeshInstance3D and CsgBlockoutFreeze.is_frozen(object as Node)

func _parse_begin(object: Object) -> void:
	add_custom_control(_build_panel(object as MeshInstance3D))

static func _build_panel(frozen: MeshInstance3D) -> Control:
	var opts: Dictionary = CsgBlockoutBakePipeline.normalized(frozen.get_meta(CsgBlockoutFreeze.META_BAKE, {}))
	var panel: VBoxContainer = VBoxContainer.new()
	panel.name = "CsgBlockoutFrozenPanel"
	var title: Label = Label.new()
	title.text = CsgBlockoutI18n.t("FROZEN_PANEL_TITLE")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override(&"font_color", Color(0.55, 0.85, 1.0))
	panel.add_child(title)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	panel.add_child(grid)

	var collision: OptionButton = OptionButton.new()
	collision.name = "Collision"
	for mode: String in CsgBlockoutBakePipeline.COLLISION_MODES:
		collision.add_item(CsgBlockoutI18n.t(COLLISION_KEYS[mode]))
	collision.select(CsgBlockoutBakePipeline.COLLISION_MODES.find(String(opts["collision"])))
	collision.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collision.fit_to_longest_item = false
	compact(collision)
	collision.tooltip_text = collision.text
	collision.item_selected.connect(func(_i: int) -> void: collision.tooltip_text = collision.text)
	_row(grid, "BAKE_COLLISION", collision)

	var uv2: CheckBox = CheckBox.new()
	uv2.name = "UV2"
	uv2.button_pressed = bool(opts["uv2"])
	_row(grid, "BAKE_UV2", uv2)

	var texel: SpinBox = SpinBox.new()
	texel.name = "Texel"
	texel.min_value = 0.01
	texel.max_value = 4.0
	texel.step = 0.01
	texel.value = float(opts["texel"])
	texel.suffix = "m"
	_row(grid, "BAKE_TEXEL", texel)

	var occluder: CheckBox = CheckBox.new()
	occluder.name = "Occluder"
	occluder.button_pressed = bool(opts["occluder"])
	_row(grid, "BAKE_OCCLUDER", occluder)

	var lod: CheckBox = CheckBox.new()
	lod.name = "LOD"
	lod.button_pressed = bool(opts["lod"])
	_row(grid, "BAKE_LOD", lod)

	var buttons: HBoxContainer = HBoxContainer.new()
	panel.add_child(buttons)
	var rebake: Button = Button.new()
	rebake.name = "Rebake"
	rebake.text = CsgBlockoutI18n.t("REBAKE")
	rebake.icon = load("res://addons/csg_blockout/res/icons/freeze.svg") as Texture2D
	rebake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rebake.pressed.connect(func() -> void:
		var chosen: Dictionary = {
			"collision": CsgBlockoutBakePipeline.COLLISION_MODES[collision.selected],
			"uv2": uv2.button_pressed,
			"texel": texel.value,
			"occluder": occluder.button_pressed,
			"lod": lod.button_pressed,
		}
		CsgBlockoutFreeze.rebake([frozen], chosen))
	compact(rebake)
	buttons.add_child(rebake)
	var unfreeze: Button = Button.new()
	unfreeze.name = "Unfreeze"
	unfreeze.text = CsgBlockoutI18n.t("UNFREEZE")
	unfreeze.icon = load("res://addons/csg_blockout/res/icons/unfreeze.svg") as Texture2D
	unfreeze.pressed.connect(func() -> void: CsgBlockoutGltfRoundTrip.unfreeze_with_confirm([frozen]))
	compact(unfreeze)
	unfreeze.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unfreeze.size_flags_stretch_ratio = 0.5
	buttons.add_child(unfreeze)
	_add_round_trip(panel, frozen)
	panel.add_child(HSeparator.new())
	return panel

## Export .glb / use the refined mesh, with a status line that follows re-imports.
static func _add_round_trip(panel: VBoxContainer, frozen: MeshInstance3D) -> void:
	var title: Label = Label.new()
	title.text = CsgBlockoutI18n.t("GLTF_SECTION")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override(&"font_color", Color(0.55, 0.85, 1.0))
	panel.add_child(title)
	var status: GltfStatus = GltfStatus.new()
	status.name = "GltfStatus"
	status.frozen = frozen
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 200.0
	status.add_theme_color_override(&"font_color", Color(0.75, 0.75, 0.75))
	panel.add_child(status)
	var row: HBoxContainer = HBoxContainer.new()
	panel.add_child(row)
	var export_button: Button = Button.new()
	export_button.name = "ExportGltf"
	export_button.text = CsgBlockoutI18n.t("GLTF_EXPORT")
	export_button.icon = CSGTopBlockoutBar.editor_icon(&"Save")
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.pressed.connect(func() -> void:
		CsgBlockoutGltfRoundTrip.export_nodes([frozen])
		status.refresh())
	compact(export_button)
	row.add_child(export_button)
	var apply_button: Button = Button.new()
	apply_button.name = "UseRefined"
	apply_button.text = CsgBlockoutI18n.t("GLTF_APPLY")
	apply_button.icon = CSGTopBlockoutBar.editor_icon(&"Reload")
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(func() -> void: CsgBlockoutGltfRoundTrip.apply_refined([frozen]))
	compact(apply_button)
	row.add_child(apply_button)
	var show_button: Button = Button.new()
	show_button.name = "ShowGltf"
	show_button.icon = CSGTopBlockoutBar.editor_icon(&"Folder")
	show_button.tooltip_text = CsgBlockoutI18n.t("GLTF_SHOW_FILE")
	show_button.pressed.connect(func() -> void:
		var path: String = CsgBlockoutGltfRoundTrip.path_for(frozen)
		if FileAccess.file_exists(path):
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path)))
	row.add_child(show_button)
	status.buttons = [apply_button, show_button]
	status.refresh()

## Status line that follows file system changes, so a .glb saved from a DCC tool
## shows up as soon as Godot has re-imported it.
class GltfStatus extends Label:
	var frozen: MeshInstance3D
	var buttons: Array[Button] = []

	func _enter_tree() -> void:
		var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		if not fs.filesystem_changed.is_connected(refresh):
			fs.filesystem_changed.connect(refresh)
		if not fs.resources_reimported.is_connected(_on_reimported):
			fs.resources_reimported.connect(_on_reimported)

	func _exit_tree() -> void:
		var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		if fs.filesystem_changed.is_connected(refresh):
			fs.filesystem_changed.disconnect(refresh)
		if fs.resources_reimported.is_connected(_on_reimported):
			fs.resources_reimported.disconnect(_on_reimported)

	func _on_reimported(_files: PackedStringArray) -> void:
		refresh()

	func refresh() -> void:
		if not is_instance_valid(frozen):
			return
		text = CsgBlockoutGltfRoundTrip.status_text(frozen)
		var exists: bool = FileAccess.file_exists(CsgBlockoutGltfRoundTrip.path_for(frozen))
		for b: Button in buttons:
			b.disabled = not exists

static func _row(grid: GridContainer, label_key: String, control: Control) -> void:
	var label: Label = Label.new()
	label.text = CsgBlockoutI18n.t(label_key)
	label.tooltip_text = label.text
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)

## Long labels and translations must not widen the Inspector dock (that squeezes the
## viewport and makes its toolbar wrap): the text clips with an ellipsis and the full
## text goes to the tooltip.
static func compact(button: Button) -> void:
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if button.tooltip_text.is_empty():
		button.tooltip_text = button.text
