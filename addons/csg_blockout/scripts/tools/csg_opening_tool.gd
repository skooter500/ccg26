@tool
class_name CsgBlockoutOpeningTool
extends CsgBlockoutTool
## Click a wall to cut a door or a window. The cutter is aligned to the wall face,
## measured through the wall thickness, dropped to the floor (doors) or the sill
## height (windows), and appended to the combiner that owns the wall. An optional
## frame (F, or its tag in the chip) is added after the cutter so it isn't cut away.
## Sizes come from Project Settings; the cut is selected afterwards, so its face
## arrows and dimension labels adjust it. The wheel stays with the camera. The tool
## ends after one opening unless it was started locked; clicking off a wall leaves
## it and selects what was clicked.

enum Mode { DOOR, WINDOW }

## Walls are surfaces whose normal is closer to horizontal than this (|n.y| below).
const WALL_MAX_NORMAL_Y: float = 0.5
## How far the cutter reaches past each wall face.
const CUT_MARGIN: float = 0.02
## Frame pieces stick out of the wall faces by this much.
const FRAME_PROTRUSION: float = 0.04
const MAX_WALL_THICKNESS: float = 5.0
const FALLBACK_THICKNESS: float = 0.5
const ACCENT: Color = Color(1.0, 0.62, 0.25)

var mode: Mode = Mode.DOOR
var _size: Vector2 = Vector2.ZERO
var _frame: bool = false
var _placement: Dictionary = {}
var _ghost: CsgBlockoutGhost = CsgBlockoutGhost.new()

func get_id() -> StringName:
	return &"opening_window" if mode == Mode.WINDOW else &"opening_door"

func activate() -> void:
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	_size = config.get_window_size() if mode == Mode.WINDOW else config.get_door_size()
	_frame = config.get_opening_frame()
	_placement = {}

func deactivate() -> void:
	_ghost.clear()
	_placement = {}

func input(camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseMotion:
		_update((event as InputEventMouseMotion).position, event)
		return PASS
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return PASS
		if not mb.pressed:
			return STOP
		_update(mb.position, event)
		if _placement.is_empty():
			# Not on a wall: leave the tool and select what was clicked.
			manager.deactivate(self)
			manager.select_at(mb.position)
		else:
			_commit()
			manager.finish(self)
		return STOP
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and (event as InputEventKey).keycode == KEY_F:
		_toggle_frame()
		return STOP
	return PASS

func _toggle_frame() -> void:
	_frame = not _frame
	CsgBlockoutConfig.get_config().set_opening_frame(_frame)
	_update(manager.mouse_pos, null)

## Recomputes where the opening would go for the cursor at `pos`.
func _update(pos: Vector2, event: InputEvent) -> void:
	_placement = _compute(manager.cast(pos, [], false), event)
	_show_ghost()
	manager.refresh()

func _compute(hit: CsgBlockoutRaycast.Hit, event: InputEvent) -> Dictionary:
	if hit == null or not hit.is_valid() or not (hit.collider is CSGShape3D):
		return {}
	if absf(hit.normal.y) > WALL_MAX_NORMAL_Y:
		return {}
	var n: Vector3 = Vector3(hit.normal.x, 0.0, hit.normal.z).normalized()
	var t: Vector3 = Vector3.UP.cross(n).normalized()
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	var active: bool = grid.is_active(event)
	# Wall thickness: from just inside the face to where the ray leaves the wall.
	var thickness: float = FALLBACK_THICKNESS
	var through: CsgBlockoutRaycast.Hit = CsgBlockoutRaycast.cast_ray(hit.position - n * 0.002, -n, [], false)
	if through.is_valid() and through.distance < MAX_WALL_THICKNESS:
		thickness = through.distance + 0.002
	elif hit.solid_shape is CSGBox3D:
		thickness = absf(CsgBlockoutShapeInfo.world_size(hit.solid_shape).dot(n.abs()))
	# Floor under the wall face (in front of it).
	var floor_y: float = hit.position.y - _size.y * 0.5
	var down: CsgBlockoutRaycast.Hit = CsgBlockoutRaycast.cast_ray(hit.position + n * 0.05, Vector3.DOWN, [], true, 0.0)
	if down.is_valid():
		floor_y = down.position.y
	var bottom: float = floor_y
	if mode == Mode.WINDOW:
		bottom = floor_y + CsgBlockoutConfig.get_config().get_window_sill_height()
	# Slide along the wall in half-grid steps so even widths land on grid lines.
	var along: float = grid.snap_value(hit.position.dot(t), active, grid.size * 0.5)
	var across: float = hit.position.dot(n) - thickness * 0.5
	var center: Vector3 = t * along + n * across + Vector3.UP * (bottom + _size.y * 0.5)
	return {
		"hit": hit,
		"basis": Basis(t, Vector3.UP, n),
		"center": center,
		"thickness": thickness,
	}

## Cutter + optional frame pieces in the opening's local space: [{size, offset, op}].
func _pieces() -> Array[Dictionary]:
	var thickness: float = _placement["thickness"]
	var out: Array[Dictionary] = [{"size": Vector3(_size.x, _size.y, thickness + CUT_MARGIN * 2.0), "offset": Vector3.ZERO, "op": CSGShape3D.OPERATION_SUBTRACTION, "name": "Cutter"}]
	if not _frame:
		return out
	var fw: float = CsgBlockoutConfig.get_config().get_frame_width()
	var depth: float = thickness + FRAME_PROTRUSION * 2.0
	var hw: float = _size.x * 0.5
	var hh: float = _size.y * 0.5
	out.append({"size": Vector3(fw, _size.y, depth), "offset": Vector3(-hw + fw * 0.5, 0, 0), "op": CSGShape3D.OPERATION_UNION, "name": "JambLeft"})
	out.append({"size": Vector3(fw, _size.y, depth), "offset": Vector3(hw - fw * 0.5, 0, 0), "op": CSGShape3D.OPERATION_UNION, "name": "JambRight"})
	out.append({"size": Vector3(_size.x, fw, depth), "offset": Vector3(0, hh - fw * 0.5, 0), "op": CSGShape3D.OPERATION_UNION, "name": "Head"})
	if mode == Mode.WINDOW:
		out.append({"size": Vector3(_size.x, fw, depth), "offset": Vector3(0, -hh + fw * 0.5, 0), "op": CSGShape3D.OPERATION_UNION, "name": "Sill"})
	return out

func _show_ghost() -> void:
	if _placement.is_empty():
		_ghost.clear()
		return
	var xf: Transform3D = Transform3D(_placement["basis"], _placement["center"])
	var cut_boxes: Array[Transform3D] = []
	var frame_boxes: Array[Transform3D] = []
	for piece: Dictionary in _pieces():
		var box: Transform3D = Transform3D(xf.basis.scaled_local(piece["size"]), xf * (piece["offset"] as Vector3))
		if piece["op"] == CSGShape3D.OPERATION_SUBTRACTION:
			cut_boxes.append(box)
		else:
			frame_boxes.append(box)
	_ghost.show_boxes(cut_boxes + frame_boxes, CsgBlockoutGhost.Style.SUBTRACT)

func _commit() -> void:
	var hit: CsgBlockoutRaycast.Hit = _placement["hit"]
	var xf: Transform3D = Transform3D(_placement["basis"], _placement["center"])
	var base_name: String = "Window" if mode == Mode.WINDOW else "Door"
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.tf("CREATE_NODE", [CsgBlockoutI18n.t("WINDOW" if mode == Mode.WINDOW else "DOOR")]))
	var target: Dictionary = CsgBlockoutNodeFactory.parent_for_hit(hit, CSGShape3D.OPERATION_SUBTRACTION)
	var parent: Node = target["parent"]
	if target["wrap"] != null:
		parent = CsgBlockoutNodeFactory.wrap_in_combiner(action, target["wrap"])
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	var material: Material = config.get_active_material() if config else null
	var pieces: Array[Dictionary] = _pieces()
	var cutter: CSGBox3D = CSGBox3D.new()
	cutter.name = CsgBlockoutSceneOps.unique_child_name(parent, base_name)
	cutter.size = pieces[0]["size"]
	cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
	cutter.material = material
	action.add_node(parent, cutter, -1, xf)
	if pieces.size() > 1:
		var frame: CSGCombiner3D = CSGCombiner3D.new()
		frame.name = CsgBlockoutSceneOps.unique_child_name(parent, cutter.name + "_Frame")
		for i: int in range(1, pieces.size()):
			var piece: CSGBox3D = CSGBox3D.new()
			piece.name = pieces[i]["name"]
			piece.size = pieces[i]["size"]
			piece.position = pieces[i]["offset"]
			piece.material = material
			frame.add_child(piece)
		action.add_node(parent, frame, -1, xf)
	action.select([cutter])
	action.commit()

func draw_overlay(overlay: Control, camera: Camera3D) -> void:
	if _placement.is_empty() or camera == null:
		return
	var center: Vector3 = _placement["center"]
	if camera.is_position_behind(center):
		return
	var scale: float = EditorInterface.get_editor_scale()
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var text: String = "%s × %s m" % [CsgBlockoutDrawTool._fmt(_size.x), CsgBlockoutDrawTool._fmt(_size.y)]
	CsgBlockoutToolManager.draw_label(overlay, font, int(round(13 * scale)), camera.unproject_position(center) + Vector2(14, -14) * scale, text, true)

func chip() -> Dictionary:
	var window: bool = mode == Mode.WINDOW
	var step: String = CsgBlockoutI18n.t("STEP_OPENING_HOVER")
	if not _placement.is_empty():
		step = CsgBlockoutI18n.t("STEP_WINDOW_CLICK" if window else "STEP_DOOR_CLICK")
	return {
		"title": CsgBlockoutI18n.t("WINDOW" if window else "DOOR"),
		"step": step,
		"accent": ACCENT,
		"tags": [{"key": "F", "label": CsgBlockoutI18n.t("FRAME"), "on": _frame, "toggle": _toggle_frame}],
	}
