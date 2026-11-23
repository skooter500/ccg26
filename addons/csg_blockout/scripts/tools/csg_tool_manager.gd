@tool
class_name CsgBlockoutToolManager
extends RefCounted
## Routes 3D viewport input to the active modal tool, then to passive tools, and
## draws the shared HUD on the viewport overlay: the tool chip at the top center
## (what the active tool wants next, and Esc), the status line below it, and the grid
## badge in the bottom left. Modal tools are one-shot: they end after one result
## unless started locked (double-click their button).

signal active_tool_changed(tool_id: StringName)

const PASS: int = EditorPlugin.AFTER_GUI_INPUT_PASS
const STOP: int = EditorPlugin.AFTER_GUI_INPUT_STOP
const RMB_CLICK_SLOP: float = 4.0
const BASE_FONT_SIZE: int = 13
const BASE_PADDING: float = 6.0
const CHIP_BG: Color = Color(0.1, 0.11, 0.14, 0.96)
const TEXT: Color = Color(0.93, 0.94, 0.97)
const TEXT_DIM: Color = Color(0.68, 0.7, 0.76)
const OK_COLOR: Color = Color(0.45, 0.85, 0.55)
const WARN_COLOR: Color = Color(1.0, 0.72, 0.3)
const ACTION_COLOR: Color = Color(0.45, 0.7, 1.0)

static var current: CsgBlockoutToolManager

var plugin: EditorPlugin
var active: CsgBlockoutTool
## The active tool stays after finishing a result (started with a double-click).
var locked: bool = false
## Passive tools in drawing order, and in input order (higher priority first).
var passives: Array[CsgBlockoutTool] = []
var _input_passives: Array[CsgBlockoutTool] = []
var _priorities: Dictionary = {}
var _modal_tools: Dictionary = {}
## Camera and mouse position of the viewport that received the last event.
var camera: Camera3D
var mouse_pos: Vector2 = Vector2.ZERO
var has_mouse: bool = false

var _rmb_down_pos: Vector2 = Vector2.ZERO
var _rmb_moved: bool = false
## Clickable HUD areas per camera: [{"rect": Rect2, "call": Callable}], and the area
## the HUD covers (clicks there never reach the tools underneath).
var _hotspots: Dictionary = {}
var _hud_rects: Dictionary = {}
var _swallow_release: bool = false

func _init(p_plugin: EditorPlugin) -> void:
	plugin = p_plugin
	current = self

static func refresh_all() -> void:
	if current != null:
		current.refresh()

## `input_priority`: passives with a higher value see input first (e.g. labels drawn on
## top of handles must win the click).
func add_passive(tool: CsgBlockoutTool, input_priority: int = 0) -> void:
	tool.manager = self
	passives.append(tool)
	_priorities[tool] = input_priority
	_input_passives = passives.duplicate()
	_input_passives.sort_custom(func(a: CsgBlockoutTool, b: CsgBlockoutTool) -> bool:
		return int(_priorities[a]) > int(_priorities[b]) or (int(_priorities[a]) == int(_priorities[b]) and passives.find(a) < passives.find(b)))

## Registers a modal tool so passive tools (hotkeys) can start it by id.
func register_tool(tool_id: StringName, tool: CsgBlockoutTool) -> void:
	tool.manager = self
	_modal_tools[tool_id] = tool

func get_tool(tool_id: StringName) -> CsgBlockoutTool:
	return _modal_tools.get(tool_id)

func activate(tool: CsgBlockoutTool, p_locked: bool = false) -> void:
	if active == tool:
		locked = p_locked
		refresh()
		return
	if active != null:
		var previous: CsgBlockoutTool = active
		active = null
		previous.deactivate()
	tool.manager = self
	active = tool
	locked = p_locked
	tool.activate()
	active_tool_changed.emit(tool.get_id())
	refresh()

func deactivate(tool: CsgBlockoutTool = null) -> void:
	if active == null or (tool != null and tool != active):
		return
	var previous: CsgBlockoutTool = active
	active = null
	locked = false
	previous.deactivate()
	active_tool_changed.emit(&"")
	refresh()

## A tool produced its result: it ends, unless locked.
func finish(tool: CsgBlockoutTool) -> void:
	if tool != active:
		return
	if locked:
		tool.activate()
		refresh()
	else:
		deactivate(tool)

func set_locked(value: bool) -> void:
	locked = value and active != null
	refresh()

func is_active(tool_id: StringName) -> bool:
	return active != null and active.get_id() == tool_id

func refresh() -> void:
	if plugin != null:
		plugin.update_overlays()

## Converts an event position to the SubViewport pixel space used by camera rays
## (differs when the viewport renders at half resolution).
func ray_pos(pos: Vector2) -> Vector2:
	if camera == null:
		return pos
	var container: SubViewportContainer = camera.get_viewport().get_parent() as SubViewportContainer
	if container != null and container.stretch_shrink > 1:
		return pos / float(container.stretch_shrink)
	return pos

## Position of a viewport-local point in the editor's root window.
func to_global(pos: Vector2) -> Vector2:
	if camera == null:
		return pos
	var container: Control = camera.get_viewport().get_parent() as Control
	return container.get_global_rect().position + pos if container != null else pos

func cast(pos: Vector2, exclude: Array = [], use_plane: bool = true, plane_height: float = 0.0) -> CsgBlockoutRaycast.Hit:
	if camera == null:
		return CsgBlockoutRaycast.Hit.new()
	return CsgBlockoutRaycast.cast(camera, ray_pos(pos), exclude, use_plane, plane_height)

## Selects what's under `pos` (the primitive whose surface was clicked), or nothing.
func select_at(pos: Vector2) -> void:
	var hit: CsgBlockoutRaycast.Hit = cast(pos, [], false)
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	if not hit.is_valid():
		return
	var target: Node = hit.collider
	if hit.collider is CSGShape3D and hit.shape != null:
		target = hit.shape
	if target != null:
		selection.add_node(target)

func handle_input(cam: Camera3D, event: InputEvent) -> int:
	camera = cam
	if event is InputEventMouse:
		mouse_pos = (event as InputEventMouse).position
		has_mouse = true
	# Right mouse belongs to Godot's freelook; a click without movement cancels the tool.
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			_rmb_down_pos = mb.position
			_rmb_moved = false
		elif not _rmb_moved and active != null:
			active.cancel()
			refresh()
		return PASS
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if event is InputEventMouseMotion and (event as InputEventMouseMotion).position.distance_to(_rmb_down_pos) > RMB_CLICK_SLOP:
			_rmb_moved = true
		return PASS
	if _hud_input(cam, event):
		return STOP
	if active != null:
		if event is InputEventKey and event.is_pressed() and (event as InputEventKey).keycode == KEY_ESCAPE:
			active.cancel()
			refresh()
			return STOP
		var r: int = active.input(cam, event)
		if r != PASS:
			refresh()
			return r
	for tool: CsgBlockoutTool in _input_passives:
		var r: int = tool.input(cam, event)
		if r != PASS:
			refresh()
			return r
	return PASS

## Clicks on the HUD (Esc key, toggles, the status action) are handled here and never
## reach the tools below.
func _hud_input(cam: Camera3D, event: InputEvent) -> bool:
	if not (event is InputEventMouseButton) or (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return false
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed:
		if _swallow_release:
			_swallow_release = false
			return true
		return false
	var key: int = cam.get_instance_id() if cam != null else 0
	for spot: Dictionary in _hotspots.get(key, []):
		if (spot["rect"] as Rect2).has_point(mb.position):
			_swallow_release = true
			(spot["call"] as Callable).call()
			refresh()
			return true
	for rect: Rect2 in _hud_rects.get(key, []):
		if rect.has_point(mb.position):
			_swallow_release = true
			return true
	return false

func draw_overlay(overlay: Control) -> void:
	var cam: Camera3D = _camera_for_overlay(overlay)
	if cam == null:
		cam = camera
	for tool: CsgBlockoutTool in passives:
		tool.draw_overlay(overlay, cam)
	if active != null:
		active.draw_overlay(overlay, cam)
	_draw_hud(overlay, cam)

## The editor overlay sits next to the SubViewportContainer that renders its camera.
func _camera_for_overlay(overlay: Control) -> Camera3D:
	var parent: Node = overlay.get_parent()
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child is SubViewportContainer:
			for sub: Node in child.get_children():
				if sub is SubViewport:
					return (sub as SubViewport).get_camera_3d()
	return null

func _show_grid_badge() -> bool:
	if active != null:
		return true
	for n: Node in EditorInterface.get_selection().get_selected_nodes():
		if n is CSGShape3D:
			return true
	return false

func _draw_hud(overlay: Control, cam: Camera3D) -> void:
	var key: int = cam.get_instance_id() if cam != null else 0
	var spots: Array[Dictionary] = []
	var rects: Array[Rect2] = []
	var scale: float = EditorInterface.get_editor_scale()
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var font_size: int = int(round(BASE_FONT_SIZE * scale))
	var pad: float = BASE_PADDING * scale
	if _show_grid_badge():
		var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
		var text: String = CsgBlockoutI18n.tf("HUD_GRID", [grid.label()])
		if not grid.snap_enabled:
			text += " · " + CsgBlockoutI18n.t("HUD_SNAP_OFF")
		draw_label(overlay, font, font_size, Vector2(pad * 2.0, overlay.size.y - pad * 2.0), text, false)
	var y: float = 10.0 * scale
	if active != null:
		var chip: Dictionary = active.chip()
		if not chip.is_empty():
			var rect: Rect2 = _draw_chip(overlay, chip, y, spots)
			rects.append(rect)
			y = rect.end.y + 6.0 * scale
	if CsgBlockoutStatus.is_visible():
		rects.append(_draw_status(overlay, y, spots))
	_hotspots[key] = spots
	_hud_rects[key] = rects

## The chip: [accent | Title  step  (key)label …  (Esc) exit]. Returns its rect.
func _draw_chip(overlay: Control, chip: Dictionary, y: float, spots: Array[Dictionary]) -> Rect2:
	var s: float = EditorInterface.get_editor_scale()
	var theme: Theme = EditorInterface.get_editor_theme()
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var bold: Font = theme.get_font(&"bold", &"EditorFonts") if theme != null and theme.has_font(&"bold", &"EditorFonts") else font
	var title_size: int = int(round(15 * s))
	var step_size: int = int(round(14 * s))
	var key_size: int = int(round(12 * s))
	var accent: Color = chip.get("accent", ACTION_COLOR)
	var title: String = chip.get("title", "")
	var step: String = chip.get("step", "")
	var warn: bool = bool(chip.get("warn", false))
	var tags: Array = chip.get("tags", [])
	if locked:
		tags = tags + [{"key": "", "label": CsgBlockoutI18n.t("TAG_LOCKED"), "on": true, "toggle": func() -> void: set_locked(false)}]
	var pad_x: float = 12.0 * s
	var pad_y: float = 7.0 * s
	var gap: float = 12.0 * s
	var exit_label: String = CsgBlockoutI18n.t("KEY_EXIT")
	# Measure.
	var title_w: float = bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var step_w: float = font.get_string_size(step, HORIZONTAL_ALIGNMENT_LEFT, -1, step_size).x
	var tag_ws: Array[float] = []
	for tag: Dictionary in tags:
		tag_ws.append(_tag_width(font, bold, tag, key_size, s))
	var esc_w: float = _keycap_width(bold, "Esc", key_size, s) + 5.0 * s + font.get_string_size(exit_label, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	var height: float = maxf(bold.get_height(title_size), font.get_height(step_size)) + pad_y * 2.0
	var width: float = pad_x + 4.0 * s + title_w + gap + step_w + gap + esc_w + pad_x
	for w: float in tag_ws:
		width += w + gap
	var x0: float = roundf((overlay.size.x - width) * 0.5)
	var rect: Rect2 = Rect2(x0, y, width, height)
	overlay.draw_style_box(_box(CHIP_BG, 8.0 * s, 6.0 * s), rect)
	overlay.draw_rect(Rect2(rect.position + Vector2(0.0, 6.0 * s), Vector2(4.0 * s, height - 12.0 * s)), accent)
	var baseline: float = y + (height + bold.get_ascent(title_size) - bold.get_descent(title_size)) * 0.5
	var x: float = x0 + pad_x + 4.0 * s
	overlay.draw_string(bold, Vector2(x, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, accent.lerp(Color.WHITE, 0.35))
	x += title_w + gap
	overlay.draw_string(font, Vector2(x, baseline), step, HORIZONTAL_ALIGNMENT_LEFT, -1, step_size, WARN_COLOR if warn else TEXT)
	x += step_w + gap
	for i: int in tags.size():
		var tag: Dictionary = tags[i]
		var tag_rect: Rect2 = _draw_tag(overlay, font, bold, tag, Vector2(x, y + height * 0.5), key_size, s, accent)
		if tag.get("toggle") is Callable and (tag["toggle"] as Callable).is_valid():
			spots.append({"rect": tag_rect.grow(3.0 * s), "call": tag["toggle"]})
		x += tag_ws[i] + gap
	var esc_rect: Rect2 = _draw_keycap(overlay, bold, "Esc", Vector2(x, y + height * 0.5), key_size, s, Color(0.93, 0.94, 0.97), Color(0.08, 0.09, 0.11))
	overlay.draw_string(font, Vector2(esc_rect.end.x + 5.0 * s, baseline), exit_label, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size, TEXT_DIM)
	spots.append({"rect": Rect2(esc_rect.position, Vector2(esc_w, esc_rect.size.y)).grow(4.0 * s), "call": func() -> void:
		if active != null:
			active.cancel()})
	return rect

func _draw_status(overlay: Control, y: float, spots: Array[Dictionary]) -> Rect2:
	var s: float = EditorInterface.get_editor_scale()
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var size: int = int(round(14 * s))
	var icon: String = "⚠" if CsgBlockoutStatus.warning else "✓"
	var icon_color: Color = WARN_COLOR if CsgBlockoutStatus.warning else OK_COLOR
	var text: String = CsgBlockoutStatus.text
	var action_text: String = CsgBlockoutStatus.action_label
	var pad_x: float = 12.0 * s
	var pad_y: float = 6.0 * s
	var icon_w: float = font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var action_w: float = 0.0 if action_text.is_empty() else font.get_string_size(action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 14.0 * s
	# Long messages (paths, node lists) are cut to fit the viewport.
	var max_text_w: float = overlay.size.x - 48.0 * s - pad_x * 2.0 - icon_w - 8.0 * s - action_w
	text = _fit(font, text, size, max_text_w)
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var height: float = font.get_height(size) + pad_y * 2.0
	var width: float = pad_x + icon_w + 8.0 * s + text_w + action_w + pad_x
	var rect: Rect2 = Rect2(roundf((overlay.size.x - width) * 0.5), y, width, height)
	overlay.draw_style_box(_box(CHIP_BG, 8.0 * s, 4.0 * s), rect)
	var baseline: float = y + (height + font.get_ascent(size) - font.get_descent(size)) * 0.5
	var x: float = rect.position.x + pad_x
	overlay.draw_string(font, Vector2(x, baseline), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, size, icon_color)
	x += icon_w + 8.0 * s
	overlay.draw_string(font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, TEXT)
	x += text_w + 14.0 * s
	if not action_text.is_empty():
		overlay.draw_string(font, Vector2(x, baseline), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ACTION_COLOR)
		spots.append({"rect": Rect2(x - 6.0 * s, y, action_w + 6.0 * s, height), "call": CsgBlockoutStatus.trigger})
	return rect

## Gives keyboard focus to the 3D viewport of `camera` (or the first one) and returns
## it: Godot's viewport surface, the focusable sibling of the SubViewportContainer.
static func focus_viewport(camera: Camera3D = null) -> Control:
	var vp: Viewport = camera.get_viewport() if is_instance_valid(camera) else EditorInterface.get_editor_viewport_3d(0)
	var container: Control = vp.get_parent() as Control if vp != null else null
	if container == null or container.get_parent() == null:
		return null
	for child: Node in container.get_parent().get_children():
		if child is Control and child != container and (child as Control).focus_mode == Control.FOCUS_ALL:
			(child as Control).grab_focus()
			return child as Control
	return null

## `text`, shortened with "…" until it fits in `max_width`.
static func _fit(font: Font, text: String, size: int, max_width: float) -> String:
	if max_width <= 0.0 or font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
		return text
	var lo: int = 0
	var hi: int = text.length()
	while lo < hi:
		var mid: int = (lo + hi + 1) / 2
		if font.get_string_size(text.left(mid) + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			lo = mid
		else:
			hi = mid - 1
	return text.left(lo) + "…"

func _tag_width(font: Font, bold: Font, tag: Dictionary, size: int, s: float) -> float:
	var w: float = font.get_string_size(String(tag.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var key: String = String(tag.get("key", ""))
	if not key.is_empty():
		w += _keycap_width(bold, key, size, s) + 5.0 * s
	return w

## A key cap followed by its label; "on" tags are tinted with the accent.
func _draw_tag(overlay: Control, font: Font, bold: Font, tag: Dictionary, left_mid: Vector2, size: int, s: float, accent: Color) -> Rect2:
	var on: bool = bool(tag.get("on", false))
	var key: String = String(tag.get("key", ""))
	var label: String = String(tag.get("label", ""))
	var x: float = left_mid.x
	var rect: Rect2 = Rect2(left_mid, Vector2.ZERO)
	if not key.is_empty():
		var bg: Color = accent.darkened(0.15) if on else Color(1, 1, 1, 0.14)
		rect = _draw_keycap(overlay, bold, key, left_mid, size, s, bg, TEXT)
		x = rect.end.x + 5.0 * s
	var baseline: float = left_mid.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	overlay.draw_string(font, Vector2(x, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, accent.lerp(Color.WHITE, 0.45) if on else TEXT_DIM)
	var label_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return Rect2(Vector2(left_mid.x, left_mid.y - font.get_height(size) * 0.5), Vector2(x + label_w - left_mid.x, font.get_height(size)))

func _keycap_width(bold: Font, key: String, size: int, s: float) -> float:
	return bold.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 12.0 * s

func _draw_keycap(overlay: Control, bold: Font, key: String, left_mid: Vector2, size: int, s: float, bg: Color, fg: Color) -> Rect2:
	var w: float = _keycap_width(bold, key, size, s)
	var h: float = bold.get_height(size) + 4.0 * s
	var rect: Rect2 = Rect2(left_mid.x, left_mid.y - h * 0.5, w, h)
	overlay.draw_style_box(_box(bg, 4.0 * s, 0.0, Color(1, 1, 1, 0.22)), rect)
	var baseline: float = left_mid.y + (bold.get_ascent(size) - bold.get_descent(size)) * 0.5
	overlay.draw_string(bold, Vector2(left_mid.x + 6.0 * s, baseline), key, HORIZONTAL_ALIGNMENT_LEFT, -1, size, fg)
	return rect

static func _box(bg: Color, radius: float, shadow: float = 0.0, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(int(round(radius)))
	box.anti_aliasing = true
	if shadow > 0.0:
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = int(round(shadow))
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(1)
	return box

## Text with a dark rounded backdrop; `pos` is the left end of the baseline.
static func draw_label(overlay: Control, font: Font, font_size: int, pos: Vector2, text: String, accent: bool = false) -> Rect2:
	var scale: float = EditorInterface.get_editor_scale()
	var pad: Vector2 = Vector2(6.0, 3.0) * scale
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect: Rect2 = Rect2(pos + Vector2(-pad.x, -font.get_ascent(font_size) - pad.y), size + pad * 2.0)
	var bg: Color = Color(0.08, 0.1, 0.14, 0.82) if not accent else Color(0.12, 0.2, 0.34, 0.9)
	overlay.draw_rect(rect, bg, true)
	overlay.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.96, 1.0))
	return rect
