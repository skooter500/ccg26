@tool
class_name CsgBlockoutTreeSelect
extends CsgBlockoutTool
## Double-click a CSG shape in the viewport to select its whole CSG tree (the room it
## belongs to). A single click keeps selecting just the primitive under the cursor, as
## in Godot, so both levels are one gesture away without the scene tree.

var _swallow_release: bool = false

func get_id() -> StringName:
	return &"tree_select"

func input(_camera: Camera3D, event: InputEvent) -> int:
	if manager.active != null or not (event is InputEventMouseButton):
		return PASS
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return PASS
	if not mb.pressed:
		if _swallow_release:
			_swallow_release = false
			return STOP
		return PASS
	if not mb.double_click or mb.shift_pressed or mb.ctrl_pressed or mb.alt_pressed:
		return PASS
	var hit: CsgBlockoutRaycast.Hit = manager.cast(mb.position, [], false)
	if not hit.is_valid() or not (hit.collider is CSGShape3D):
		return PASS
	var tree: CSGShape3D = CsgBlockoutShapeInfo.csg_root_of(hit.collider)
	if tree == null:
		return PASS
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(tree)
	_swallow_release = true
	CsgBlockoutStatus.show(CsgBlockoutI18n.tf("STATUS_TREE_SELECTED", [tree.name]), false, "", Callable(), 2.0)
	return STOP
