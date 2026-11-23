@tool
class_name CsgPieMenu extends Control
## Radial menu at the cursor. Every item is a pill (icon + label) around the center,
## sized to its text and pushed outward until no two pills overlap, so labels never
## spill out of their slot. The pointer's direction from the center picks an item (its
## whole sector, not only the pill); in a submenu the center goes back. The first item
## sits at the top, the rest follow clockwise.
## Item: {"label", "type": "action"|"submenu"|"create_csg", "icon": Texture2D,
##        "disabled": bool, "reason": String (why it's disabled), ...type-specific keys}.
## Colors follow the editor theme, so the editor's icons stay readable on the pills.

signal action_triggered(item: Dictionary)
signal close_requested()

const BASE_DEADZONE: float = 22.0
const BASE_RADIUS: float = 88.0
const BASE_FONT_SIZE: int = 14
const BASE_ICON_SIZE: float = 16.0
const BASE_PAD: Vector2 = Vector2(11.0, 6.0)
const BASE_GAP: float = 8.0
const START_ANGLE: float = -PI / 2.0

# Fallbacks when the editor theme doesn't provide a color.
const PILL_BG: Color = Color(0.13, 0.15, 0.18)
const PILL_ACCENT: Color = Color(0.44, 0.73, 0.98)
const TEXT: Color = Color(0.88, 0.88, 0.88)

var editor_scale: float = 1.0
var items: Array = [] # Array[Dictionary]
var menu_stack: Array = [] # Array[Array]
## Deadzone radius, and the distance from the center to the farthest pill edge.
var inner_radius: float = BASE_DEADZONE
var outer_radius: float = BASE_RADIUS
var active_item_index: int = -1
var is_in_deadzone: bool = true
var font_size: int = BASE_FONT_SIZE

# Animation state
var anim_progress: float = 0.0
var popup_tween: Tween
var item_hover_progress: Array[float] = []

## Pill rects for the current items, relative to the center.
var _pills: Array[Rect2] = []

# Pointer in root-window coordinates, fed from the viewport events the plugin forwards
# (more reliable than querying the OS cursor, and drivable by tests).
var _pointer_global: Vector2 = Vector2.ZERO
var _has_pointer: bool = false

func set_pointer_global(pos: Vector2) -> void:
	_pointer_global = pos
	_has_pointer = true

func _ready() -> void:
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func apply_editor_scale(scale: float) -> void:
	editor_scale = maxf(scale, 0.1)
	inner_radius = BASE_DEADZONE * editor_scale
	font_size = int(round(BASE_FONT_SIZE * editor_scale))
	if not items.is_empty():
		_pills = _layout(items)
	queue_redraw()

func setup(menu_items: Array, p_scale: float = -1.0) -> void:
	if p_scale > 0.0:
		apply_editor_scale(p_scale)
	items = menu_items
	menu_stack.clear()
	active_item_index = -1
	_pills = _layout(items)
	_play_popup_anim()

## How far pills reach from the center for these items and all their submenus (the
## caller keeps that much room around the menu inside the window).
func max_extent(menu_items: Array) -> float:
	var extent: float = _extent(_layout(menu_items))
	for item: Dictionary in menu_items:
		if item.get("type") == "submenu":
			extent = maxf(extent, max_extent(item.get("children", [])))
	return extent

## Center of item `index`'s pill in global (root window) coordinates.
func item_position(index: int) -> Vector2:
	if index < 0 or index >= _pills.size():
		return global_position
	return get_global_transform() * _pills[index].get_center()

func _direction(index: int, count: int) -> Vector2:
	return Vector2.from_angle(START_ANGLE + TAU * float(index) / float(count))

func _font() -> Font:
	return get_theme_font(&"font", &"Label")

func _pill_size(item: Dictionary) -> Vector2:
	var s: float = editor_scale
	var text_w: float = _font().get_string_size(_label(item), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var icon_w: float = (BASE_ICON_SIZE * s + 6.0 * s) if item.get("icon") is Texture2D else 0.0
	var h: float = maxf(_font().get_height(font_size), BASE_ICON_SIZE * s) + BASE_PAD.y * 2.0 * s
	return Vector2(BASE_PAD.x * 2.0 * s + icon_w + text_w, h)

static func _label(item: Dictionary) -> String:
	var text: String = String(item.get("label", ""))
	return text + "  ›" if item.get("type") == "submenu" else text

## Pill rects around the center: start at the base radius and push all pills out until
## neighbors stop overlapping.
func _layout(menu_items: Array) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var count: int = menu_items.size()
	if count == 0:
		return rects
	var sizes: Array[Vector2] = []
	for item: Dictionary in menu_items:
		sizes.append(_pill_size(item))
	var gap: float = BASE_GAP * editor_scale
	var radius: float = BASE_RADIUS * editor_scale
	for attempt: int in 60:
		rects.clear()
		for i: int in count:
			var dir: Vector2 = _direction(i, count)
			# Place the pill so its inner edge, not its center, sits at the radius.
			var half: Vector2 = sizes[i] * 0.5
			var reach: float = absf(dir.x) * half.x + absf(dir.y) * half.y
			var center: Vector2 = dir * (radius + reach)
			rects.append(Rect2(center - half, sizes[i]))
		var overlap: bool = false
		for i: int in count:
			var a: Rect2 = rects[i].grow(gap * 0.5)
			var b: Rect2 = rects[(i + 1) % count].grow(gap * 0.5)
			if count > 1 and a.intersects(b):
				overlap = true
				break
		if not overlap:
			break
		radius += 6.0 * editor_scale
	return rects

static func _extent(rects: Array[Rect2]) -> float:
	var extent: float = 0.0
	for r: Rect2 in rects:
		for corner: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)]:
			extent = maxf(extent, corner.length())
	return extent

func _play_popup_anim() -> void:
	item_hover_progress.resize(items.size())
	item_hover_progress.fill(0.0)
	outer_radius = _extent(_pills)
	anim_progress = 0.0
	if popup_tween and popup_tween.is_valid():
		popup_tween.kill()
	popup_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	popup_tween.tween_property(self, "anim_progress", 1.0, 0.18)
	queue_redraw()

func _process(delta: float) -> void:
	if items.is_empty():
		return
	var mouse_pos: Vector2 = get_global_transform().affine_inverse() * _pointer_global if _has_pointer else get_local_mouse_position()
	var distance: float = mouse_pos.length()
	var new_active_index: int = -1
	is_in_deadzone = distance < inner_radius
	if not is_in_deadzone:
		var sector: float = TAU / items.size()
		var rel: float = wrapf(mouse_pos.angle() - START_ANGLE + sector * 0.5, 0.0, TAU)
		new_active_index = int(rel / sector) % items.size()
	if new_active_index != active_item_index:
		active_item_index = new_active_index
	var needs_redraw: bool = popup_tween != null and popup_tween.is_running()
	for i: int in range(items.size()):
		var target: float = 1.0 if i == active_item_index else 0.0
		if absf(item_hover_progress[i] - target) > 0.01:
			item_hover_progress[i] = lerpf(item_hover_progress[i], target, minf(25.0 * delta, 1.0))
			needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _theme_color(color_name: StringName, theme_type: StringName, fallback: Color) -> Color:
	return get_theme_color(color_name, theme_type) if has_theme_color(color_name, theme_type) else fallback

func _draw() -> void:
	if items.is_empty() or _pills.size() != items.size():
		return
	var t: float = clampf(anim_progress, 0.0, 1.2)
	if t <= 0.01:
		return
	var s: float = editor_scale
	var font: Font = _font()
	var alpha: float = clampf(t, 0.0, 1.0)
	var base: Color = _theme_color(&"base_color", &"Editor", PILL_BG)
	var accent: Color = _theme_color(&"accent_color", &"Editor", PILL_ACCENT)
	var text: Color = _theme_color(&"font_color", &"Label", TEXT)
	# Center: deadzone disc with a pointer toward the hovered item.
	draw_circle(Vector2.ZERO, inner_radius, Color(base, 0.9 * alpha))
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 40, Color(text, 0.25 * alpha), 1.5 * s, true)
	if active_item_index >= 0:
		var a: float = START_ANGLE + TAU * float(active_item_index) / float(items.size())
		draw_arc(Vector2.ZERO, inner_radius, a - 0.5, a + 0.5, 16, Color(accent, alpha), 3.0 * s, true)
	elif not menu_stack.is_empty():
		var back: String = "‹"
		var bs: Vector2 = font.get_string_size(back, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(-bs.x * 0.5, font.get_ascent(font_size) * 0.5), back, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(text, alpha))
	for i: int in items.size():
		var item: Dictionary = items[i]
		var rect: Rect2 = _pills[i]
		# Grow out of the center on open.
		rect.position *= minf(t, 1.0) * 0.25 + 0.75
		var hover: float = item_hover_progress[i]
		var disabled: bool = bool(item.get("disabled", false))
		var bg: Color = base.lerp(accent, 0.4 * hover * (0.3 if disabled else 1.0))
		bg.a = 0.96 * alpha
		var border: Color = Color(text, 0.15 * alpha)
		if not disabled:
			border = border.lerp(Color(accent, alpha), hover)
		draw_style_box(_style(bg, border, s), rect)
		var x: float = rect.position.x + BASE_PAD.x * s
		var icon: Variant = item.get("icon")
		var fg: Color = Color(text, alpha * (0.4 if disabled else 1.0))
		if icon is Texture2D:
			var size: float = BASE_ICON_SIZE * s
			draw_texture_rect(icon, Rect2(Vector2(x, rect.get_center().y - size * 0.5), Vector2(size, size)), false, Color(1, 1, 1, fg.a))
			x += size + 6.0 * s
		var baseline: float = rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(font, Vector2(x, baseline), _label(item), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fg)

static func _style(bg: Color, border: Color, s: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(int(round(7.0 * s)))
	box.border_color = border
	box.set_border_width_all(maxi(1, int(round(1.5 * s))))
	box.anti_aliasing = true
	box.shadow_color = Color(0, 0, 0, 0.3 * bg.a)
	box.shadow_size = int(round(3.0 * s))
	return box

func execute_active_item(trigger_close_on_empty: bool = false) -> void:
	if is_in_deadzone:
		if not menu_stack.is_empty():
			go_back()
		elif trigger_close_on_empty:
			close_requested.emit()
		return
	if active_item_index >= 0 and active_item_index < items.size():
		var item: Dictionary = items[active_item_index]
		if bool(item.get("disabled", false)):
			# Stays open; the status line says what's missing.
			var reason: String = String(item.get("reason", ""))
			if not reason.is_empty():
				CsgBlockoutStatus.show(reason, true)
			return
		if item.get("type") == "submenu":
			action_triggered.emit(item)
			menu_stack.push_back(items)
			items = item.get("children", [])
			active_item_index = -1
			_pills = _layout(items)
			_play_popup_anim()
		else:
			action_triggered.emit(item)
			close_requested.emit()
	elif trigger_close_on_empty:
		close_requested.emit()

func execute_back() -> void:
	if not menu_stack.is_empty():
		go_back()
	else:
		close_requested.emit()

func go_back() -> void:
	if not menu_stack.is_empty():
		items = menu_stack.pop_back()
		active_item_index = -1
		_pills = _layout(items)
		_play_popup_anim()
