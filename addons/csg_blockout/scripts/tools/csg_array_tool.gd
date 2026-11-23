@tool
class_name CsgBlockoutArrayTool
extends CsgBlockoutTool
## Duplicate along an axis (Ctrl+Shift+D): move the mouse along X, Y or Z and the
## selection repeats with its own size as the step; + / - change the gap, X/Y/Z lock
## the axis, click creates the copies as siblings in one undo step. The wheel stays
## with the camera. Faster than setting up a CSGRepeater3D; keep the Repeater for
## parametric layouts.

const MAX_COPIES: int = 100
const AXIS_PICK_PIXELS: float = 12.0
const ACCENT: Color = Color(0.45, 0.85, 0.55)
const GAP_KEYS_UP: Array[Key] = [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]
const GAP_KEYS_DOWN: Array[Key] = [KEY_MINUS, KEY_KP_SUBTRACT]

var _sources: Array[Node3D] = []
var _bounds: AABB = AABB()
var _start_mouse: Vector2 = Vector2.ZERO
var _axis: int = -1
var _locked: bool = false
var _sign: float = 1.0
var _gap: float = 0.0
var _count: int = 0
var _ghost: CsgBlockoutGhost = CsgBlockoutGhost.new()

func get_id() -> StringName:
	return &"array"

func activate() -> void:
	_sources = CsgBlockoutSelection.top_level_nodes()
	_axis = -1
	_locked = false
	_gap = 0.0
	_count = 0
	_start_mouse = manager.mouse_pos
	if _sources.is_empty():
		manager.deactivate.call_deferred(self)
		return
	_bounds = CsgBlockoutSelection.world_aabb(_sources[0])
	for i: int in range(1, _sources.size()):
		_bounds = _bounds.merge(CsgBlockoutSelection.world_aabb(_sources[i]))

func deactivate() -> void:
	_ghost.clear()
	_sources.clear()
	_count = 0

func cancel() -> void:
	manager.deactivate(self)

func _step() -> float:
	if _axis < 0:
		return 0.0
	return maxf(_bounds.size[_axis] + _gap, CsgBlockoutGrid.get_grid().size * 0.25)

func input(camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseMotion:
		_update(camera, (event as InputEventMouseMotion).position)
		return STOP
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_commit()
				return STOP
	if event is InputEventKey and event.is_pressed():
		var k: Key = (event as InputEventKey).keycode
		if k in GAP_KEYS_UP or k in GAP_KEYS_DOWN:
			var grid: CsgBlockoutGrid = CsgBlockoutGrid.get_grid()
			_gap += grid.size * (1.0 if k in GAP_KEYS_UP else -1.0)
			if _axis >= 0:
				_gap = maxf(_gap, -_bounds.size[_axis] + grid.size * 0.25)
			_update(camera, manager.mouse_pos)
			return STOP
		if event.is_echo():
			return PASS
		if k in [KEY_X, KEY_Y, KEY_Z]:
			var axis: int = [KEY_X, KEY_Y, KEY_Z].find(k)
			_locked = not (_locked and _axis == axis)
			_axis = axis
			_update(camera, manager.mouse_pos)
			return STOP
	return PASS

func _update(camera: Camera3D, pos: Vector2) -> void:
	if camera == null or _sources.is_empty():
		return
	var center: Vector3 = _bounds.get_center()
	var drag: Vector2 = pos - _start_mouse
	if not _locked:
		if drag.length() < AXIS_PICK_PIXELS:
			_axis = -1
		else:
			# Axis whose on-screen direction best matches the mouse movement.
			var c2: Vector2 = camera.unproject_position(center)
			var best: float = 0.0
			for a: int in 3:
				var dir3: Vector3 = Vector3.ZERO
				dir3[a] = 1.0
				var s: Vector2 = camera.unproject_position(center + dir3) - c2
				if s.length() < 0.001:
					continue
				var score: float = absf(s.normalized().dot(drag.normalized()))
				if score > best:
					best = score
					_axis = a
	if _axis < 0:
		_count = 0
		_ghost.clear()
		manager.refresh()
		return
	var axis_dir: Vector3 = Vector3.ZERO
	axis_dir[_axis] = 1.0
	# Distance along the axis: closest point between the axis line and the mouse ray.
	var rp: Vector2 = manager.ray_pos(pos)
	var o: Vector3 = camera.project_ray_origin(rp)
	var d: Vector3 = camera.project_ray_normal(rp)
	var w0: Vector3 = center - o
	var b: float = axis_dir.dot(d)
	var denom: float = 1.0 - b * b
	var t: float = 0.0
	if denom > 0.0001:
		t = (b * d.dot(w0) - axis_dir.dot(w0)) / denom
	_sign = 1.0 if t >= 0.0 else -1.0
	var step: float = _step()
	_count = clampi(int(floor(absf(t) / step + 0.5)), 0, MAX_COPIES)
	_show_ghost()
	manager.refresh()

func _offset(k: int) -> Vector3:
	var v: Vector3 = Vector3.ZERO
	v[_axis] = _sign * _step() * float(k)
	return v

func _show_ghost() -> void:
	var entries: Array[Dictionary] = []
	for k: int in range(1, _count + 1):
		var offset: Vector3 = _offset(k)
		for src: Node3D in _sources:
			if src is CSGShape3D:
				for prim: CSGShape3D in CsgBlockoutShapeInfo.primitives_under(src):
					if prim.operation == CSGShape3D.OPERATION_SUBTRACTION:
						continue
					var xf: Transform3D = prim.global_transform.translated_local(CsgBlockoutShapeInfo.preview_offset(prim))
					entries.append({"mesh": CsgBlockoutShapeInfo.preview_mesh(prim), "xform": xf.translated(offset)})
			else:
				var box: AABB = CsgBlockoutSelection.world_aabb(src)
				var mesh: BoxMesh = BoxMesh.new()
				mesh.size = box.size.max(Vector3.ONE * 0.1)
				entries.append({"mesh": mesh, "xform": Transform3D(Basis.IDENTITY, box.get_center() + offset)})
	if entries.is_empty():
		_ghost.clear()
	else:
		_ghost.show_meshes(entries, CsgBlockoutGhost.Style.UNION)

func _commit() -> void:
	if _count <= 0 or _axis < 0:
		manager.deactivate(self)
		return
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("ARRAY_ACTION"))
	var created: Array[Node] = []
	for src: Node3D in _sources:
		var parent: Node = src.get_parent()
		var index: int = src.get_index()
		var base: String = String(src.name).rstrip("0123456789").trim_suffix("_")
		var taken: Dictionary = {}
		for k: int in range(1, _count + 1):
			var copy: Node3D = src.duplicate() as Node3D
			var name_candidate: String = CsgBlockoutSceneOps.unique_child_name(parent, base)
			var n: int = 2
			while taken.has(name_candidate) or parent.has_node(NodePath(name_candidate)):
				name_candidate = "%s_%02d" % [base, n]
				n += 1
			taken[name_candidate] = true
			copy.name = name_candidate
			index += 1
			action.add_copy(parent, copy, src, index, src.global_transform.translated(_offset(k)))
			created.append(copy)
	action.select(created)
	action.commit()
	manager.deactivate(self)

func draw_overlay(overlay: Control, camera: Camera3D) -> void:
	if camera == null or _sources.is_empty():
		return
	var scale: float = EditorInterface.get_editor_scale()
	var font: Font = overlay.get_theme_font(&"font", &"Label")
	var anchor: Vector3 = _bounds.get_center() + (_offset(_count) if _axis >= 0 else Vector3.ZERO)
	if camera.is_position_behind(anchor):
		return
	if _axis < 0:
		return
	var text: String = CsgBlockoutI18n.tf("ARRAY_LABEL", [_count, CsgBlockoutDrawTool._fmt(_step()), ("[%s]" if _locked else "%s") % "XYZ"[_axis]])
	CsgBlockoutToolManager.draw_label(overlay, font, int(round(13 * scale)), camera.unproject_position(anchor) + Vector2(14, -14) * scale, text, true)

func chip() -> Dictionary:
	var step: String = CsgBlockoutI18n.t("STEP_ARRAY_AXIS") if _axis < 0 else CsgBlockoutI18n.tf("STEP_ARRAY_CLICK", [_count])
	return {
		"title": CsgBlockoutI18n.t("ARRAY_ACTION"),
		"step": step,
		"accent": ACCENT,
		"tags": [
			{"key": "X Y Z", "label": CsgBlockoutI18n.t("TAG_LOCK_AXIS"), "on": _locked},
			{"key": "+ −", "label": CsgBlockoutI18n.tf("TAG_GAP", [CsgBlockoutDrawTool._fmt(_gap)]), "on": not is_zero_approx(_gap)},
		],
	}
