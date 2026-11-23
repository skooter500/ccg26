@tool
class_name CsgBlockoutSelection
extends RefCounted
## Selection queries shared by tools.

## Selected Node3Ds inside the edited scene, without nodes whose ancestor is also
## selected (moving a parent already moves its children).
static func top_level_nodes() -> Array[Node3D]:
	var root: Node = EditorInterface.get_edited_scene_root()
	var selected: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	var out: Array[Node3D] = []
	for n: Node in selected:
		if not (n is Node3D) or n == root or root == null or not root.is_ancestor_of(n):
			continue
		var covered: bool = false
		for other: Node in selected:
			if other != n and other.is_ancestor_of(n):
				covered = true
				break
		if not covered:
			out.append(n as Node3D)
	return out

## True when the selection contains a node CSG Blockout edits (CSG shape or ruler).
static func has_blockout_node() -> bool:
	for n: Node in EditorInterface.get_selection().get_selected_nodes():
		if n is CSGShape3D or n is CSGRuler3D:
			return true
	return false

static func csg_shapes() -> Array[CSGShape3D]:
	var out: Array[CSGShape3D] = []
	for n: Node in EditorInterface.get_selection().get_selected_nodes():
		if n is CSGShape3D:
			out.append(n as CSGShape3D)
	return out

## World-space bounds of a node (CSG nodes use their primitive bounds).
static func world_aabb(n: Node3D) -> AABB:
	if n is CSGShape3D:
		return CsgBlockoutShapeInfo.transform_aabb(n.global_transform, CsgBlockoutShapeInfo.local_aabb(n))
	if n is VisualInstance3D:
		return CsgBlockoutShapeInfo.transform_aabb(n.global_transform, (n as VisualInstance3D).get_aabb())
	return AABB(n.global_position, Vector3.ZERO)
