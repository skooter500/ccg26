@tool
class_name CsgBlockoutTags
extends RefCounted
## Semantic tags for blockout surfaces: wall, floor, hazard, interactive.
## Tagging stores the tag in the node's metadata ("csg_blockout_tag", visible in the
## Inspector and readable at runtime, e.g. to treat hazards as damaging) and assigns a
## color-coded grid material. The legend can be exported as an SVG for design docs.

const META_TAG: StringName = &"csg_blockout_tag"
const TAGS: Array[StringName] = [&"wall", &"floor", &"hazard", &"interactive"]
const COLORS: Dictionary = {
	&"wall": Color(0.62, 0.68, 0.8),
	&"floor": Color(0.84, 0.8, 0.7),
	&"hazard": Color(0.9, 0.3, 0.25),
	&"interactive": Color(0.35, 0.78, 0.45),
}

static func material_for(tag: StringName) -> Material:
	var base: String = CsgBlockoutConfig.plugin_path if not CsgBlockoutConfig.plugin_path.is_empty() else "res://addons/csg_blockout"
	var path: String = base.path_join("res/materials/mat_tag_%s.tres" % tag)
	return load(path) as Material if ResourceLoader.exists(path) else null

static func tag_of(n: Node) -> StringName:
	var v: Variant = n.get_meta(META_TAG, &"")
	return StringName(v) if v is String or v is StringName else &""

static func label(tag: StringName) -> String:
	return CsgBlockoutI18n.t("TAG_" + String(tag).to_upper())

## Tags (or with tag == &"" untags) the CSG shapes / frozen nodes in `nodes`, as one
## undo step. Untagging puts the current material preset back.
static func apply(nodes: Array[Node], tag: StringName) -> int:
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("TAG_ACTION"))
	var material: Material = material_for(tag) if tag != &"" else CsgBlockoutConfig.get_config().get_active_material()
	var count: int = 0
	# Combiners have no material of their own: tag the primitives inside them.
	var targets: Array[Node] = []
	for n: Node in nodes:
		if n is CSGCombiner3D:
			for prim: CSGShape3D in CsgBlockoutShapeInfo.primitives_under(n):
				if not targets.has(prim):
					targets.append(prim)
		elif not targets.has(n):
			targets.append(n)
	for n: Node in targets:
		if n is CSGShape3D and &"material" in n:
			action.set_property(n, &"material", material)
		elif CsgBlockoutFreeze.is_frozen(n):
			action.set_property(n, &"material_override", material if tag != &"" else null)
		else:
			continue
		action.assign_meta(n, META_TAG, String(tag) if tag != &"" else null)
		count += 1
	action.commit()
	return count

static func apply_to_selection(tag: StringName) -> int:
	return apply(EditorInterface.get_selection().get_selected_nodes(), tag)

## Number of tagged nodes per tag in the edited scene.
static func counts() -> Dictionary:
	var out: Dictionary = {}
	for t: StringName in TAGS:
		out[t] = 0
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return out
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var t: StringName = tag_of(n)
		if out.has(t):
			out[t] = int(out[t]) + 1
		stack.append_array(n.get_children())
	return out

## SVG legend: one swatch per tag with its localized name and usage count.
static func legend_svg() -> String:
	var c: Dictionary = counts()
	var row_h: int = 36
	var width: int = 360
	var height: int = 64 + row_h * TAGS.size()
	var lines: PackedStringArray = []
	lines.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Noto Sans, Segoe UI, sans-serif">' % [width, height, width, height])
	lines.append('<rect width="100%" height="100%" rx="10" fill="#1f2228"/>')
	lines.append('<text x="20" y="38" font-size="20" font-weight="600" fill="#f2f4f8">%s</text>' % _xml(CsgBlockoutI18n.t("LEGEND_TITLE")))
	for i: int in TAGS.size():
		var tag: StringName = TAGS[i]
		var y: int = 56 + i * row_h
		var col: Color = COLORS[tag]
		lines.append('<rect x="20" y="%d" width="24" height="24" rx="4" fill="#%s" stroke="#00000055"/>' % [y, col.to_html(false)])
		lines.append('<text x="56" y="%d" font-size="16" fill="#e6e8ee">%s</text>' % [y + 18, _xml(label(tag))])
		lines.append('<text x="%d" y="%d" font-size="14" fill="#9aa0ad" text-anchor="end">×%d</text>' % [width - 20, y + 18, int(c[tag])])
	lines.append("</svg>")
	return "\n".join(lines)

static func export_legend(path: String) -> Error:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(legend_svg())
	f.close()
	if path.begins_with("res://"):
		EditorInterface.get_resource_filesystem().update_file(path)
	return OK

## Opens a save dialog and writes the legend there.
static func export_legend_with_dialog() -> void:
	var dialog: EditorFileDialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray(["*.svg ; SVG"])
	dialog.title = CsgBlockoutI18n.t("EXPORT_LEGEND")
	dialog.current_file = "blockout_legend.svg"
	dialog.file_selected.connect(func(path: String) -> void:
		var err: Error = export_legend(path)
		CsgBlockoutStatus.report(CsgBlockoutI18n.tf("LEGEND_SAVED", [path]) if err == OK else error_string(err),
			EditorToaster.SEVERITY_INFO if err == OK else EditorToaster.SEVERITY_ERROR)
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_file_dialog()

static func _xml(s: String) -> String:
	return s.xml_escape()
