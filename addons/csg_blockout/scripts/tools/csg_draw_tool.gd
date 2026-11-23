@tool
class_name CsgBlockoutDrawTool
extends CsgBlockoutTool
## Draw in the viewport with one gesture: drag a rectangle on any surface or the
## ground and release, done.
##   BOX  adds a block, as tall as the last box you adjusted (1 m at first);
##   ROOM adds a hollow room as its own CSG tree, as tall as Project Settings say;
##   CUT  carves into the surface it starts on, through the solid behind it.
## The result is selected with arrows on its faces, so the height is one drag away.
## A click without dragging leaves the tool and selects what's under the cursor. The
## tool ends after one shape unless it was started locked (double-click its button).

enum Mode { BOX, ROOM, CUT }
enum State { IDLE, PRESSED, BASE }

## Mouse travel (px) before a press becomes a drag.
const DRAG_THRESHOLD: float = 5.0
## Cutters reach this far past the faces they cut through, avoiding coplanar faces.
const CUT_EPSILON: float = 0.01
const MAX_CUT_DEPTH: float = 20.0
const DEFAULT_BOX_HEIGHT: float = 1.0
const META_BOX_HEIGHT: String = "draw_box_height"
const ACCENT_ADD: Color = Color(0.35, 0.62, 1.0)
const ACCENT_CUT: Color = Color(1.0, 0.42, 0.36)

## The last box drawn: giving it a new height makes that the next default.
static var _last_box: WeakRef = null

var mode: Mode = Mode.BOX
var state: State = State.IDLE

var _hover: CsgBlockoutRaycast.Hit
var _start_hit: CsgBlockoutRaycast.Hit
var _press_pos: Vector2 = Vector2.ZERO
var _origin: Vector3 = Vector3.ZERO
var _basis: Basis = Basis.IDENTITY
var _u: Vector2 = Vector2.ZERO # rectangle extent along _basis.x (min, max)
var _v: Vector2 = Vector2.ZERO # rectangle extent along _basis.z (min, max)
var _cut_depth: float = 0.0
## Shift while drawing a box: its own object instead of joining the tree below.
var _separate: bool = false
var _ghost: CsgBlockoutGhost = CsgBlockoutGhost.new()

func get_id() -> StringName:
	match mode:
		Mode.ROOM:
			return &"draw_room"
		Mode.CUT:
			return &"draw_cut"
	return &"draw_box"

func activate() -> void:
	_reset()

func deactivate() -> void:
	_reset()
	_hover = null

func _reset() -> void:
	state = State.IDLE
	_separate = false
	_ghost.clear()

static func box_height() -> float:
	var v: Variant = EditorInterface.get_editor_settings().get_project_metadata(CsgBlockoutGrid.META_SECTION, META_BOX_HEIGHT, DEFAULT_BOX_HEIGHT)
	return maxf(float(v), 0.01) if (v is float or v is int) else DEFAULT_BOX_HEIGHT

## Called when a box gets a new size from the face arrows or a dimension label: a new
## height on the box just drawn becomes the height of the next one.
static func note_resized(node: Node, size: Vector3) -> void:
	if _last_box == null or _last_box.get_ref() != node:
		return
	EditorInterface.get_editor_settings().set_project_metadata(CsgBlockoutGrid.META_SECTION, META_BOX_HEIGHT, size.y)

func input(camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_SHIFT and mode == Mode.BOX and _separate != key.pressed:
			_separate = key.pressed
			if state == State.BASE:
				_show_ghost()
			manager.refresh()
		return PASS
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		match state:
			State.IDLE:
				_hover = manager.cast(mm.position)
				manager.refresh()
				return PASS
			State.PRESSED:
				if mm.position.distance_to(_press_pos) < DRAG_THRESHOLD:
					return STOP
				_start_base()
				_update_base(camera, mm.position, mm)
				return STOP
			State.BASE:
				if mode == Mode.BOX:
					_separate = mm.shift_pressed
				_update_base(camera, mm.position, mm)
				return STOP
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return PASS
		if mb.pressed:
			if state == State.IDLE:
				var hit: CsgBlockoutRaycast.Hit = manager.cast(mb.position)
				if hit.is_valid():
					_start_hit = hit
					_press_pos = mb.position
					state = State.PRESSED
			return STOP
		match state:
			State.PRESSED:
				# A click, not a drag: leave the tool and select what was clicked.
				_reset()
				manager.deactivate(self)
				manager.select_at(mb.position)
			State.BASE:
				if mode == Mode.BOX:
					_separate = mb.shift_pressed
				var fp: Vector2 = _footprint()
				if fp.x < 0.0001 or fp.y < 0.0001:
					# Too thin to be a shape: stay, so the next drag can try again.
					_reset()
				elif mode == Mode.CUT and not _cut_valid():
					_reset()
					CsgBlockoutStatus.show(CsgBlockoutI18n.t("STEP_CUT_NEEDS_SURFACE"), true)
				else:
					_commit()
					_reset()
					manager.finish(self)
		return STOP
	return PASS

func _start_base() -> void:
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	_basis = CsgBlockoutNodeFactory.basis_from_normal(_start_hit.normal)
	_origin = grid.snap_in_plane(_start_hit.position, Vector3.ZERO, _basis, grid.snap_enabled)
	_u = Vector2.ZERO
	_v = Vector2.ZERO
	_cut_depth = _measure_cut_depth() if mode == Mode.CUT else 0.0
	state = State.BASE

## A cut has to start on a CSG surface: there is nothing to cut in empty space.
func _cut_valid() -> bool:
	return _start_hit != null and _start_hit.is_valid() and not _start_hit.on_plane and _start_hit.collider is CSGShape3D

## How thick the solid under the cut's start is: from just inside its surface to where
## a ray through it comes out again.
func _measure_cut_depth() -> float:
	var fallback: float = CsgBlockoutGrid.get_grid().size
	if not _cut_valid():
		return fallback
	var n: Vector3 = _start_hit.normal
	var through: CsgBlockoutRaycast.Hit = CsgBlockoutRaycast.cast_ray(_start_hit.position - n * 0.002, -n, [], false)
	if through.is_valid() and through.distance < MAX_CUT_DEPTH:
		return through.distance + 0.002
	return fallback

## Point on the drawing plane under the cursor, snapped, as plane (u, v).
func _plane_uv(camera: Camera3D, pos: Vector2, event: InputEvent) -> Variant:
	var rp: Vector2 = manager.ray_pos(pos)
	var plane: Plane = Plane(_basis.y, _origin)
	var p: Variant = plane.intersects_ray(camera.project_ray_origin(rp), camera.project_ray_normal(rp))
	if not (p is Vector3):
		return null
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	var active: bool = grid.is_active(event)
	var rel: Vector3 = (p as Vector3) - _origin
	return Vector2(grid.snap_value(rel.dot(_basis.x), active), grid.snap_value(rel.dot(_basis.z), active))

func _update_base(camera: Camera3D, pos: Vector2, event: InputEvent) -> void:
	var uv: Variant = _plane_uv(camera, pos, event)
	if uv == null:
		return
	var c: Vector2 = uv
	_u = Vector2(minf(0.0, c.x), maxf(0.0, c.x))
	_v = Vector2(minf(0.0, c.y), maxf(0.0, c.y))
	_show_ghost()

## Signed extrusion along the surface normal (negative: into the surface).
func _height() -> float:
	match mode:
		Mode.ROOM:
			return CsgBlockoutConfig.get_config().get_room_height()
		Mode.CUT:
			return -_cut_depth
	return box_height()

func _rect_center() -> Vector3:
	return _origin + _basis.x * ((_u.x + _u.y) * 0.5) + _basis.z * ((_v.x + _v.y) * 0.5)

func _footprint() -> Vector2:
	return Vector2(_u.y - _u.x, _v.y - _v.x)

## Final box in world space: {"xform": Transform3D (basis unscaled), "size": Vector3}.
func _box() -> Dictionary:
	var fp: Vector2 = _footprint()
	var h: float = _height()
	var size: Vector3 = Vector3(fp.x, absf(h), fp.y)
	var center: Vector3 = _rect_center() + _basis.y * (h * 0.5)
	if mode == Mode.CUT:
		# Reach past both faces it cuts through.
		size.y += CUT_EPSILON * 2.0
	return {"xform": Transform3D(_basis, center), "size": size}

func _show_ghost() -> void:
	if state != State.BASE:
		_ghost.clear()
		return
	var box: Dictionary = _box()
	var xf: Transform3D = box["xform"]
	var boxes: Array[Transform3D] = [Transform3D(xf.basis.scaled_local(box["size"]), xf.origin)]
	if mode == Mode.ROOM:
		var inner: Dictionary = _room_inner(box["size"])
		boxes.append(Transform3D(xf.basis.scaled_local(inner["size"]), xf * (inner["offset"] as Vector3)))
	_ghost.show_boxes(boxes, CsgBlockoutGhost.Style.SUBTRACT if mode == Mode.CUT else CsgBlockoutGhost.Style.UNION)
	manager.refresh()

## Hollow part of a room, relative to the room center: {"size", "offset"}.
func _room_inner(outer: Vector3) -> Dictionary:
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	var wall: float = config.get_room_wall_thickness()
	var floor_t: float = config.get_room_floor_thickness()
	var open_top: bool = config.get_room_open_top()
	var inner: Vector3 = Vector3(maxf(outer.x - wall * 2.0, 0.01), 0.0, maxf(outer.z - wall * 2.0, 0.01))
	var bottom: float = -outer.y * 0.5 + floor_t
	var top: float = outer.y * 0.5 + (CUT_EPSILON if open_top else -floor_t)
	inner.y = maxf(top - bottom, 0.01)
	return {"size": inner, "offset": Vector3(0.0, (bottom + top) * 0.5, 0.0)}

## Where the shape goes: {"parent", "index", "wrap"}. Rooms are always their own tree;
## boxes join the tree they're drawn on (Shift: their own object); cuts go into the
## tree of the surface they cut.
func _target() -> Dictionary:
	var root: Node = CsgBlockoutSceneOps.edited_root()
	if mode == Mode.ROOM or (mode == Mode.BOX and _separate):
		return {"parent": root, "index": -1, "wrap": null}
	var op: CSGShape3D.Operation = CSGShape3D.OPERATION_SUBTRACTION if mode == Mode.CUT else CSGShape3D.OPERATION_UNION
	return CsgBlockoutNodeFactory.parent_for_hit(_start_hit, op)

## Name of the CSG tree the shape will join, for the chip ("" for a new tree).
func _target_tree_name() -> String:
	if _start_hit == null or not (_start_hit.collider is CSGShape3D):
		return ""
	if mode == Mode.ROOM or (mode == Mode.BOX and _separate):
		return ""
	var surface: Node = _start_hit.solid_shape if _start_hit.solid_shape != null else _start_hit.collider
	var tree: CSGShape3D = CsgBlockoutShapeInfo.csg_root_of(surface)
	return String(tree.name) if tree != null else ""

func _commit() -> void:
	var box: Dictionary = _box()
	var xf: Transform3D = box["xform"]
	var size: Vector3 = box["size"]
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.tf("CREATE_NODE", [_title()]))
	var target: Dictionary = _target()
	var parent: Node = target["parent"]
	if target["wrap"] != null:
		parent = CsgBlockoutNodeFactory.wrap_in_combiner(action, target["wrap"])
	var config: CsgBlockoutConfig = CsgBlockoutConfig.get_config()
	var material: Material = config.get_active_material() if config else null
	var created: Node3D
	if mode == Mode.ROOM:
		var room: CSGCombiner3D = CSGCombiner3D.new()
		room.name = CsgBlockoutSceneOps.unique_child_name(parent, "Room")
		var shell: CSGBox3D = CSGBox3D.new()
		shell.name = "Shell"
		shell.size = size
		shell.material = material
		room.add_child(shell)
		var inner: Dictionary = _room_inner(size)
		var hollow: CSGBox3D = CSGBox3D.new()
		hollow.name = "Hollow"
		hollow.operation = CSGShape3D.OPERATION_SUBTRACTION
		hollow.size = inner["size"]
		hollow.position = inner["offset"]
		hollow.material = material
		room.add_child(hollow)
		created = room
	else:
		var op: CSGShape3D.Operation = CSGShape3D.OPERATION_SUBTRACTION if mode == Mode.CUT else CSGShape3D.OPERATION_UNION
		var shape: CSGBox3D = CSGBox3D.new()
		shape.size = size
		shape.operation = op
		shape.material = material
		shape.name = CsgBlockoutSceneOps.unique_child_name(parent, _box_name(size, op))
		created = shape
	CsgBlockoutNodeFactory.init_collision(created, parent)
	action.add_node(parent, created, target["index"], xf)
	action.select([created])
	action.commit()
	if mode == Mode.BOX:
		_last_box = weakref(created)

## Readable default name from the box proportions (refined by the outliner later).
func _box_name(size: Vector3, op: CSGShape3D.Operation) -> String:
	if op == CSGShape3D.OPERATION_SUBTRACTION:
		return "Cut"
	var flat: bool = size.y <= 0.5 and size.y < minf(size.x, size.z) * 0.5
	if flat and _basis.y.dot(Vector3.UP) > 0.7:
		return "Floor"
	var thin: float = minf(size.x, size.z)
	if thin <= 0.5 and size.y >= 1.5:
		return "Wall"
	return "Block"

func _title() -> String:
	match mode:
		Mode.ROOM:
			return CsgBlockoutI18n.t("TOOL_ROOM")
		Mode.CUT:
			return CsgBlockoutI18n.t("TOOL_CUT")
	return CsgBlockoutI18n.t("TOOL_BOX")

func chip() -> Dictionary:
	var accent: Color = ACCENT_CUT if mode == Mode.CUT else ACCENT_ADD
	var step: String
	var warn: bool = false
	var tags: Array = []
	if state == State.BASE:
		if mode == Mode.CUT and not _cut_valid():
			step = CsgBlockoutI18n.t("STEP_CUT_NEEDS_SURFACE")
			warn = true
		else:
			step = CsgBlockoutI18n.t("STEP_RELEASE")
			var tree: String = _target_tree_name()
			if not tree.is_empty():
				step += "  → " + tree
			if mode == Mode.BOX and (_separate or not tree.is_empty()):
				tags.append({"key": "Shift", "label": CsgBlockoutI18n.t("TAG_SEPARATE"), "on": _separate})
	else:
		match mode:
			Mode.ROOM:
				step = CsgBlockoutI18n.t("STEP_DRAW_ROOM")
			Mode.CUT:
				step = CsgBlockoutI18n.t("STEP_DRAW_CUT")
			_:
				step = CsgBlockoutI18n.t("STEP_DRAW_BOX")
	return {"title": _title(), "step": step, "accent": accent, "warn": warn, "tags": tags}

func draw_overlay(overlay: Control, camera: Camera3D) -> void:
	if camera == null:
		return
	var scale: float = EditorInterface.get_editor_scale()
	var color: Color = ACCENT_CUT if mode == Mode.CUT else ACCENT_ADD
	if state != State.BASE:
		if _hover != null and _hover.is_valid() and not camera.is_position_behind(_hover.position):
			var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
			var b: Basis = CsgBlockoutNodeFactory.basis_from_normal(_hover.normal)
			var p: Vector3 = grid.snap_in_plane(_hover.position, Vector3.ZERO, b, grid.snap_enabled)
			var sp: Vector2 = camera.unproject_position(p)
			overlay.draw_arc(sp, 6.0 * scale, 0.0, TAU, 24, color, 2.0 * scale, true)
			overlay.draw_line(sp - Vector2(10, 0) * scale, sp + Vector2(10, 0) * scale, color, 1.0 * scale)
			overlay.draw_line(sp - Vector2(0, 10) * scale, sp + Vector2(0, 10) * scale, color, 1.0 * scale)
		return
	var box: Dictionary = _box()
	var center: Vector3 = (box["xform"] as Transform3D).origin
	if camera.is_position_behind(center):
		return
	var size: Vector3 = box["size"]
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var text: String = "%s × %s × %s m" % [_fmt(size.x), _fmt(size.z), _fmt(absf(_height()))]
	CsgBlockoutToolManager.draw_label(overlay, font, int(round(13 * scale)), camera.unproject_position(center) + Vector2(12, -12) * scale, text, true)

static func _fmt(v: float) -> String:
	return String.num(v, 2).trim_suffix(".00") if absf(v - roundf(v)) < 0.005 else String.num(v, 2)
