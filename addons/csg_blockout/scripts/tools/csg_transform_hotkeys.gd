@tool
class_name CsgBlockoutTransformHotkeys
extends CsgBlockoutTool
## Passive keyboard editing: grid size, grid-step nudging relative to the view,
## 15°/90° rotation about Y, and dropping the selection onto the surface below.
## Keys are only consumed while a CSG node / ruler is selected or a tool is active.

const FINE_DIVISOR: float = 4.0
const COARSE_ROTATION_DEG: float = 90.0
const DROP_EPSILON: float = 0.001

func get_id() -> StringName:
	return &"transform_hotkeys"

func input(camera: Camera3D, event: InputEvent) -> int:
	if not (event is InputEventKey) or not event.is_pressed():
		return PASS
	var key: InputEventKey = event as InputEventKey
	if not key.echo and manager.active == null and CsgBlockoutShortcuts.matches("play_here", key):
		CsgBlockoutPlayHere.launch(CsgBlockoutPlayHere.spawn_for(camera, manager.ray_pos(manager.mouse_pos)))
		return STOP
	var context: bool = manager.active != null or CsgBlockoutSelection.has_blockout_node()
	if not context:
		return PASS
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	if not key.echo:
		if CsgBlockoutShortcuts.matches("grid_smaller", key) or CsgBlockoutShortcuts.matches("grid_bigger", key):
			grid.step(-1 if CsgBlockoutShortcuts.matches("grid_smaller", key) else 1)
			CsgBlockoutStatus.show(CsgBlockoutI18n.tf("HUD_GRID", [grid.label()]), false, "", Callable(), 1.5)
			return STOP
	if manager.active != null:
		return PASS
	if not CsgBlockoutSelection.has_blockout_node():
		return PASS
	if not key.echo and CsgBlockoutShortcuts.matches("array_duplicate", key):
		var array_tool: CsgBlockoutTool = manager.get_tool(&"array")
		if array_tool != null and not CsgBlockoutSelection.top_level_nodes().is_empty():
			manager.activate(array_tool)
			return STOP
		return PASS
	var step: float = grid.size / FINE_DIVISOR if key.shift_pressed else grid.size
	var dirs: Dictionary = _view_axes(camera)
	if CsgBlockoutShortcuts.matches("nudge_forward", key, true):
		return _nudge(dirs["forward"] * step)
	if CsgBlockoutShortcuts.matches("nudge_back", key, true):
		return _nudge(-dirs["forward"] * step)
	if CsgBlockoutShortcuts.matches("nudge_right", key, true):
		return _nudge(dirs["right"] * step)
	if CsgBlockoutShortcuts.matches("nudge_left", key, true):
		return _nudge(-dirs["right"] * step)
	if CsgBlockoutShortcuts.matches("nudge_up", key, true):
		return _nudge(Vector3.UP * step)
	if CsgBlockoutShortcuts.matches("nudge_down", key, true):
		return _nudge(Vector3.DOWN * step)
	if key.echo:
		return PASS
	var angle: float = deg_to_rad(COARSE_ROTATION_DEG if key.shift_pressed else CsgBlockoutGrid.ROTATION_STEP_DEG)
	if CsgBlockoutShortcuts.matches("rotate_ccw", key, true):
		return _rotate(angle)
	if CsgBlockoutShortcuts.matches("rotate_cw", key, true):
		return _rotate(-angle)
	if CsgBlockoutShortcuts.matches("drop_to_surface", key):
		return _drop()
	return PASS

## Horizontal world axes closest to the camera's forward/right directions.
static func _view_axes(camera: Camera3D) -> Dictionary:
	if camera == null:
		return {"forward": Vector3.FORWARD, "right": Vector3.RIGHT}
	var b: Basis = camera.global_transform.basis
	var fwd: Vector3 = Vector3(-b.z.x, 0.0, -b.z.z)
	if fwd.length() < 0.2:
		# Looking straight down: "forward" is the screen's up direction.
		fwd = Vector3(b.y.x, 0.0, b.y.z)
	var right: Vector3 = Vector3(b.x.x, 0.0, b.x.z)
	return {"forward": _dominant_axis(fwd), "right": _dominant_axis(right)}

static func _dominant_axis(v: Vector3) -> Vector3:
	if absf(v.x) >= absf(v.z):
		return Vector3(signf(v.x), 0.0, 0.0) if v.x != 0.0 else Vector3.RIGHT
	return Vector3(0.0, 0.0, signf(v.z))

func _nudge(delta: Vector3) -> int:
	var nodes: Array[Node3D] = CsgBlockoutSelection.top_level_nodes()
	if nodes.is_empty():
		return PASS
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("NUDGE_ACTION")).merging(UndoRedo.MERGE_ENDS)
	for n: Node3D in nodes:
		action.set_property(n, &"global_position", n.global_position + delta)
	action.commit()
	return STOP

func _rotate(angle: float) -> int:
	var nodes: Array[Node3D] = CsgBlockoutSelection.top_level_nodes()
	if nodes.is_empty():
		return PASS
	var pivot: Vector3 = Vector3.ZERO
	for n: Node3D in nodes:
		pivot += n.global_position
	pivot /= float(nodes.size())
	var spin: Transform3D = Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO)
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("ROTATE_ACTION")).merging(UndoRedo.MERGE_ENDS)
	for n: Node3D in nodes:
		var xf: Transform3D = n.global_transform
		xf.origin -= pivot
		xf = spin * xf
		xf.origin += pivot
		action.set_property(n, &"global_transform", xf.orthonormalized() if n.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE) else xf)
	action.commit()
	return STOP

func _drop() -> int:
	var nodes: Array[Node3D] = CsgBlockoutSelection.top_level_nodes()
	if nodes.is_empty():
		return PASS
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("DROP_ACTION"))
	for n: Node3D in nodes:
		var box: AABB = CsgBlockoutSelection.world_aabb(n)
		var bottom: Vector3 = Vector3(box.get_center().x, box.position.y, box.get_center().z)
		var exclude: Array = [n] if (n is CSGShape3D and (n as CSGShape3D).is_root_shape()) or not (n is CSGShape3D) else []
		var hit: CsgBlockoutRaycast.Hit = CsgBlockoutRaycast.cast_ray(bottom - Vector3(0, DROP_EPSILON, 0), Vector3.DOWN, exclude, true, 0.0)
		if not hit.is_valid():
			continue
		var lift: float = hit.position.y - bottom.y
		if absf(lift) > 0.0001:
			action.set_property(n, &"global_position", n.global_position + Vector3(0, lift, 0))
	action.commit()
	return STOP

## Aligns the selection's bounds to grid lines: axis-aligned boxes get every face on
## a grid line (size and position), other nodes are moved so their bounds' minimum
## corner sits on the grid. Faces resting on a grid-aligned floor stay on it.
static func snap_selection_to_grid() -> void:
	var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("SNAP_SELECTION_TO_GRID"))
	for n: Node3D in CsgBlockoutSelection.top_level_nodes():
		var box: AABB = CsgBlockoutSelection.world_aabb(n)
		if n is CSGBox3D and _is_axis_aligned(n.global_transform.basis):
			var lo: Vector3 = grid.snap_point(box.position)
			var hi: Vector3 = grid.snap_point(box.end)
			for i: int in 3:
				if hi[i] - lo[i] < grid.size * 0.5:
					hi[i] = lo[i] + grid.size
			var world_size: Vector3 = hi - lo
			var b: Basis = n.global_transform.basis
			var local_size: Vector3 = Vector3(
				absf(b.x.normalized().dot(world_size)),
				absf(b.y.normalized().dot(world_size)),
				absf(b.z.normalized().dot(world_size))) / b.get_scale()
			var center_offset: Vector3 = (lo + hi) * 0.5 - box.get_center()
			if not local_size.is_equal_approx((n as CSGBox3D).size):
				action.set_property(n, &"size", local_size)
			if not center_offset.is_zero_approx():
				action.set_property(n, &"global_position", n.global_position + center_offset)
		else:
			var anchor: Vector3 = box.position if box.size != Vector3.ZERO else n.global_position
			var shift: Vector3 = grid.snap_point(anchor) - anchor
			if not shift.is_zero_approx():
				action.set_property(n, &"global_position", n.global_position + shift)
	action.commit()

## True when every basis axis is parallel to a world axis (rotations in 90° steps).
static func _is_axis_aligned(b: Basis) -> bool:
	for axis: Vector3 in [b.x.normalized(), b.y.normalized(), b.z.normalized()]:
		var a: Vector3 = axis.abs()
		if absf(maxf(a.x, maxf(a.y, a.z)) - 1.0) > 0.0001:
			return false
	return true
