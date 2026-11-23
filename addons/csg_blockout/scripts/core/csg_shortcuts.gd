@tool
class_name CsgBlockoutShortcuts
extends RefCounted
## Viewport shortcuts, registered under "csg_blockout/" in Editor Settings > Shortcuts
## so users can rebind them. Defaults avoid Godot 4.7's built-in 3D editor keys,
## except Page Down: it shadows "Snap Object to Floor" only while a CSG node is
## selected, and End ("drop to surface") covers that use.

const PREFIX: String = "csg_blockout/"

## id -> [keycode, ctrl, shift, alt, English display name]
const DEFAULTS: Dictionary = {
	"grid_smaller": [KEY_BRACKETLEFT, false, false, false, "Grid: Smaller"],
	"grid_bigger": [KEY_BRACKETRIGHT, false, false, false, "Grid: Bigger"],
	"nudge_left": [KEY_LEFT, false, false, false, "Nudge: Left"],
	"nudge_right": [KEY_RIGHT, false, false, false, "Nudge: Right"],
	"nudge_forward": [KEY_UP, false, false, false, "Nudge: Away From Camera"],
	"nudge_back": [KEY_DOWN, false, false, false, "Nudge: Toward Camera"],
	"nudge_up": [KEY_PAGEUP, false, false, false, "Nudge: Up"],
	"nudge_down": [KEY_PAGEDOWN, false, false, false, "Nudge: Down"],
	"drop_to_surface": [KEY_END, false, false, false, "Drop to Surface Below"],
	"rotate_ccw": [KEY_COMMA, false, false, false, "Rotate -15° (Shift: 90°)"],
	"rotate_cw": [KEY_PERIOD, false, false, false, "Rotate +15° (Shift: 90°)"],
	"array_duplicate": [KEY_D, true, true, false, "Duplicate Along Axis"],
	# Unbound by default; users can assign one in Editor Settings > Shortcuts.
	"play_here": [KEY_NONE, false, false, false, "Play From Here (at cursor)"],
}

## Shortcuts whose Shift variant is also accepted (Shift changes the step size).
const SHIFT_VARIANTS: PackedStringArray = ["rotate_ccw", "rotate_cw", "nudge_left", "nudge_right", "nudge_forward", "nudge_back", "nudge_up", "nudge_down"]

static func register_all() -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings == null or not settings.has_method(&"add_shortcut"):
		return
	for id: String in DEFAULTS:
		var path: String = PREFIX + id
		if settings.has_shortcut(path):
			continue
		var spec: Array = DEFAULTS[id]
		var sc: Shortcut = Shortcut.new()
		sc.resource_name = spec[4]
		if spec[0] != KEY_NONE:
			var ev: InputEventKey = InputEventKey.new()
			ev.keycode = spec[0]
			ev.ctrl_pressed = spec[1]
			ev.shift_pressed = spec[2]
			ev.alt_pressed = spec[3]
			sc.events = [ev]
		settings.add_shortcut(path, sc)

## True when `event` triggers shortcut `id`. With allow_shift, Shift+key also counts.
static func matches(id: String, event: InputEvent, allow_shift: bool = false) -> bool:
	if not (event is InputEventKey) or not event.is_pressed():
		return false
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	var path: String = PREFIX + id
	if settings != null and settings.has_method(&"is_shortcut") and settings.has_shortcut(path):
		if settings.is_shortcut(path, event):
			return true
		if allow_shift and (event as InputEventKey).shift_pressed:
			var plain: InputEventKey = (event as InputEventKey).duplicate()
			plain.shift_pressed = false
			return settings.is_shortcut(path, plain)
		return false
	# Fallback for engines without editor shortcut registration.
	var spec: Array = DEFAULTS.get(id, [])
	if spec.is_empty() or spec[0] == KEY_NONE:
		return false
	var k: InputEventKey = event as InputEventKey
	var shift_ok: bool = k.shift_pressed == spec[2] or (allow_shift and not spec[2])
	return k.keycode == spec[0] and k.ctrl_pressed == spec[1] and shift_ok and k.alt_pressed == spec[3]

## Human-readable binding for tooltips and the cheat sheet, e.g. "Ctrl+Shift+D" or
## "[" (empty when unbound).
static func describe(id: String) -> String:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	var path: String = PREFIX + id
	var text: String = ""
	if settings != null and settings.has_method(&"get_shortcut") and settings.has_shortcut(path):
		var sc: Shortcut = settings.get_shortcut(path)
		if sc != null and sc.has_valid_event():
			text = sc.get_as_text()
	else:
		var spec: Array = DEFAULTS.get(id, [])
		if not spec.is_empty() and spec[0] != KEY_NONE:
			var parts: PackedStringArray = []
			if spec[1]: parts.append("Ctrl")
			if spec[2]: parts.append("Shift")
			if spec[3]: parts.append("Alt")
			parts.append(OS.get_keycode_string(spec[0]))
			text = "+".join(parts)
	return _pretty(text)

## Symbols for keys whose names read poorly ("BracketLeft" -> "[").
const KEY_SYMBOLS: Dictionary = {
	"BracketLeft": "[", "BracketRight": "]", "Comma": ",", "Period": ".",
	"Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "PageUp": "PgUp", "PageDown": "PgDn",
	"None": "",
}

static func _pretty(text: String) -> String:
	var parts: PackedStringArray = text.split("+")
	for i: int in parts.size():
		parts[i] = KEY_SYMBOLS.get(parts[i], parts[i])
	return "+".join(parts) if not parts[parts.size() - 1].is_empty() else ""
