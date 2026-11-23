@tool
class_name CsgBlockoutGrid
extends RefCounted
## Grid size and snapping shared by every CSG Blockout tool.
## Stored per user in the project's editor metadata, so changing the grid never
## touches project.godot.

signal changed()

const SIZES: PackedFloat32Array = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0]
const DEFAULT_SIZE: float = 1.0
const ROTATION_STEP_DEG: float = 15.0
const META_SECTION: String = "csg_blockout"
const META_SIZE: String = "grid_size"
const META_SNAP: String = "grid_snap"

static var _instance: CsgBlockoutGrid

static func get_grid() -> CsgBlockoutGrid:
	if _instance == null:
		_instance = CsgBlockoutGrid.new()
		_instance._load()
	return _instance

var size: float = DEFAULT_SIZE
var snap_enabled: bool = true

func _load() -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings() if Engine.is_editor_hint() else null
	if settings == null:
		return
	var stored_size: Variant = settings.get_project_metadata(META_SECTION, META_SIZE, DEFAULT_SIZE)
	if stored_size is float or stored_size is int:
		size = _nearest_size(float(stored_size))
	var stored_snap: Variant = settings.get_project_metadata(META_SECTION, META_SNAP, true)
	if stored_snap is bool:
		snap_enabled = stored_snap

func _save() -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings() if Engine.is_editor_hint() else null
	if settings != null:
		settings.set_project_metadata(META_SECTION, META_SIZE, size)
		settings.set_project_metadata(META_SECTION, META_SNAP, snap_enabled)

func set_size(value: float) -> void:
	var snapped_value: float = _nearest_size(value)
	if is_equal_approx(snapped_value, size):
		return
	size = snapped_value
	_save()
	changed.emit()

func set_snap_enabled(value: bool) -> void:
	if value == snap_enabled:
		return
	snap_enabled = value
	_save()
	changed.emit()

## Moves one step through SIZES (-1 smaller, +1 bigger).
func step(direction: int) -> void:
	var idx: int = SIZES.find(size)
	if idx < 0:
		idx = SIZES.find(_nearest_size(size))
	idx = clampi(idx + direction, 0, SIZES.size() - 1)
	set_size(SIZES[idx])

func _nearest_size(value: float) -> float:
	var best: float = SIZES[0]
	for s: float in SIZES:
		if absf(s - value) < absf(best - value):
			best = s
	return best

## Snapping is active when enabled XOR Ctrl is held (same toggle Godot uses).
func is_active(event: InputEvent = null) -> bool:
	var ctrl: bool = false
	if event is InputEventWithModifiers:
		ctrl = (event as InputEventWithModifiers).ctrl_pressed
	return snap_enabled != ctrl

func snap_value(v: float, active: bool = true, step_size: float = -1.0) -> float:
	if not active:
		return v
	var s: float = size if step_size <= 0.0 else step_size
	return snappedf(v, s)

## Snaps a length so it never collapses to zero.
func snap_length(v: float, active: bool = true) -> float:
	if not active:
		return maxf(v, CsgBlockoutShapeInfo.MIN_SIZE)
	return maxf(snappedf(v, size), size)

func snap_point(p: Vector3, active: bool = true) -> Vector3:
	if not active:
		return p
	return p.snapped(Vector3.ONE * size)

## Snaps a point inside a plane: coordinates along `basis.x`/`basis.z` relative to
## `origin` are rounded, the offset along `basis.y` (the plane normal) is kept.
func snap_in_plane(p: Vector3, origin: Vector3, basis: Basis, active: bool = true) -> Vector3:
	if not active:
		return p
	var rel: Vector3 = p - origin
	var u: float = snappedf(rel.dot(basis.x), size)
	var v: float = snappedf(rel.dot(basis.z), size)
	var w: float = rel.dot(basis.y)
	return origin + basis.x * u + basis.z * v + basis.y * w

func snap_angle(radians: float, active: bool = true, step_deg: float = ROTATION_STEP_DEG) -> float:
	if not active:
		return radians
	return snappedf(radians, deg_to_rad(step_deg))

func label() -> String:
	if size >= 1.0:
		return "%d m" % int(size)
	return "%s m" % String.num(size, 3).trim_suffix("0").trim_suffix("0")
