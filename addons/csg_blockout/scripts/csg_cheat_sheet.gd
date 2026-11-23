@tool
class_name CsgBlockoutCheatSheet
extends RefCounted
## "⋯ > Shortcuts" window: every key and mouse gesture of the plugin on one page,
## with the bindings currently set in Editor Settings > Shortcuts.

static var _dialog: AcceptDialog

## [keys, description key] per row, keys as shown on the key caps.
static func rows() -> Array:
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	var out: Array = [
		["%s+A" % OS.get_keycode_string(config.action_key if config else KEY_SHIFT), "CHEAT_PIE"],
		["Esc", "CHEAT_ESC"],
		[CsgBlockoutI18n.t("CHEAT_KEY_DOUBLE_CLICK_TOOL"), "CHEAT_LOCK"],
		["Shift", "CHEAT_SEPARATE"],
		["F", "CHEAT_FRAME"],
		[_keys(["grid_smaller", "grid_bigger"]), "CHEAT_GRID"],
		[_keys(["nudge_left", "nudge_right", "nudge_forward", "nudge_back"]), "CHEAT_NUDGE"],
		[_keys(["nudge_up", "nudge_down"]), "CHEAT_NUDGE_VERTICAL"],
		[_keys(["drop_to_surface"]), "DROP_ACTION"],
		[_keys(["rotate_ccw", "rotate_cw"]), "CHEAT_ROTATE"],
		[_keys(["array_duplicate"]), "ARRAY_ACTION"],
		[CsgBlockoutI18n.t("CHEAT_KEY_DRAG_ARROW"), "CHEAT_PUSH"],
		[CsgBlockoutI18n.t("CHEAT_KEY_CLICK_LABEL"), "CHEAT_TYPE_SIZE"],
		[CsgBlockoutI18n.t("CHEAT_KEY_DOUBLE_CLICK_SHAPE"), "CHEAT_TREE"],
	]
	var play: String = _keys(["play_here"])
	if not play.is_empty():
		out.append([play, "PLAY_HERE"])
	return out

## Current bindings of shortcut ids, joined with " / " (unbound ones left out).
static func _keys(ids: Array) -> String:
	var parts: PackedStringArray = []
	for id: String in ids:
		var text: String = CsgBlockoutShortcuts.describe(id)
		if not text.is_empty():
			parts.append(text)
	return (" " if parts.size() > 2 else " / ").join(parts)

static func popup() -> void:
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	var s: float = EditorInterface.get_editor_scale()
	var base: Control = EditorInterface.get_base_control()
	_dialog = AcceptDialog.new()
	_dialog.name = "CsgBlockoutCheatSheet"
	_dialog.title = CsgBlockoutI18n.t("CHEAT_TITLE")
	# Texts are already translated; keep the editor's own dictionary off them.
	_dialog.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", int(round(10.0 * s)))
	var grid: GridContainer = GridContainer.new()
	grid.name = "Rows"
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", int(round(14.0 * s)))
	grid.add_theme_constant_override(&"v_separation", int(round(6.0 * s)))
	var cap: StyleBoxFlat = StyleBoxFlat.new()
	cap.bg_color = base.get_theme_color(&"dark_color_1", &"Editor") if base.has_theme_color(&"dark_color_1", &"Editor") else Color(0.1, 0.1, 0.12)
	cap.set_corner_radius_all(int(round(4.0 * s)))
	cap.set_content_margin_all(round(3.0 * s))
	cap.content_margin_left = round(7.0 * s)
	cap.content_margin_right = round(7.0 * s)
	for row: Array in rows():
		var keys: Label = Label.new()
		keys.text = row[0]
		keys.add_theme_stylebox_override(&"normal", cap)
		keys.size_flags_horizontal = Control.SIZE_SHRINK_END
		keys.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(keys)
		var what: Label = Label.new()
		what.text = CsgBlockoutI18n.t(row[1])
		what.custom_minimum_size.x = round(360.0 * s)
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(what)
	column.add_child(grid)
	var note: Label = Label.new()
	note.text = CsgBlockoutI18n.t("CHEAT_REBIND_NOTE")
	note.modulate = Color(1, 1, 1, 0.6)
	column.add_child(note)
	_dialog.add_child(column)
	_dialog.confirmed.connect(_dialog.queue_free)
	_dialog.canceled.connect(_dialog.queue_free)
	base.add_child(_dialog)
	_dialog.popup_centered()
