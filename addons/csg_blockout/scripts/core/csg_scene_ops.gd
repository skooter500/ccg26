@tool
class_name CsgBlockoutSceneOps
extends RefCounted
## Undoable scene edits shared by the pie menu, sidebar and viewport tools.
## Build an Action, queue operations, then commit() once: every queued change
## becomes a single entry in the edited scene's undo history.

static var _impl: CsgBlockoutSceneOps

static func _target() -> CsgBlockoutSceneOps:
	if _impl == null:
		_impl = CsgBlockoutSceneOps.new()
	return _impl

static func edited_root() -> Node:
	return EditorInterface.get_edited_scene_root() if Engine.is_editor_hint() else null

## Returns `base` if no sibling under `parent` uses it, else base_02, base_03, ...
static func unique_child_name(parent: Node, base: String) -> String:
	if parent == null or not parent.has_node(NodePath(base)):
		return base
	var i: int = 2
	while parent.has_node(NodePath("%s_%02d" % [base, i])):
		i += 1
	return "%s_%02d" % [base, i]

## Sets owner on `node` and every descendant to `scene_owner`.
static func own_subtree(node: Node, scene_owner: Node) -> void:
	if node != scene_owner:
		node.owner = scene_owner
	for child: Node in node.get_children():
		own_subtree(child, scene_owner)

## Gives `copy` the same ownership layout as `original`: nodes the scene owns stay
## owned, generated preview children (Repeater/Spreader) stay unowned, and nodes
## inside an instanced sub-scene keep the owner duplicate() gave them.
static func own_like(original: Node, copy: Node, scene_owner: Node) -> void:
	if original.owner == scene_owner:
		copy.owner = scene_owner
	var count: int = mini(original.get_child_count(), copy.get_child_count())
	for i: int in count:
		own_like(original.get_child(i), copy.get_child(i), scene_owner)


class Action:
	extends RefCounted

	var name: String
	var merge_mode: UndoRedo.MergeMode = UndoRedo.MERGE_DISABLE
	var _ops: Array[Dictionary] = []
	var _select_after: Array[Node] = []
	var _has_selection: bool = false

	func _init(action_name: String) -> void:
		name = action_name

	## Adds `node` (not yet in the tree) under `parent` at `index` (-1 = append).
	## `global_xform` (Transform3D or null) is applied after insertion.
	## own_mode: "subtree" owns every descendant, "self" only the node.
	func add_node(parent: Node, node: Node, index: int = -1, global_xform: Variant = null, own_mode: String = "subtree") -> Action:
		_ops.append({"kind": "add", "parent": parent, "node": node, "index": index, "xform": global_xform, "own": own_mode})
		return self

	## Adds a duplicate made with Node.duplicate(); ownership mirrors `original`.
	func add_copy(parent: Node, copy: Node, original: Node, index: int = -1, global_xform: Variant = null) -> Action:
		_ops.append({"kind": "add", "parent": parent, "node": copy, "index": index, "xform": global_xform, "own": "like", "original": original})
		return self

	func remove_node(node: Node) -> Action:
		_ops.append({"kind": "remove", "node": node, "parent": node.get_parent(), "index": node.get_index()})
		return self

	## Moves `node` under `new_parent` at `index`, keeping its global transform.
	func reparent(node: Node, new_parent: Node, index: int = -1) -> Action:
		_ops.append({"kind": "reparent", "node": node, "old_parent": node.get_parent(), "old_index": node.get_index(), "new_parent": new_parent, "index": index})
		return self

	func set_property(obj: Object, property: StringName, value: Variant) -> Action:
		_ops.append({"kind": "prop", "obj": obj, "prop": property, "new": value, "old": obj.get(property)})
		return self

	## Like set_property(), but with an explicit undo value (for chained changes queued
	## in the same action, e.g. renaming through a temporary name).
	func set_property_from(obj: Object, property: StringName, old_value: Variant, value: Variant) -> Action:
		_ops.append({"kind": "prop", "obj": obj, "prop": property, "new": value, "old": old_value})
		return self

	## Sets (or with null removes) metadata through set_meta(), so undo really removes
	## entries that didn't exist (assigning "metadata/x" = null would leave a Nil entry).
	func assign_meta(obj: Object, meta_name: StringName, value: Variant) -> Action:
		var old: Variant = obj.get_meta(meta_name) if obj.has_meta(meta_name) else null
		_ops.append({"kind": "meta", "obj": obj, "name": meta_name, "new": value, "old": old})
		return self

	func rename(node: Node, new_name: String) -> Action:
		return set_property(node, &"name", new_name)

	func select(nodes: Array[Node]) -> Action:
		_select_after = nodes
		_has_selection = true
		return self

	## MERGE_ENDS folds repeated actions (e.g. holding a nudge key) into one undo step.
	func merging(mode: UndoRedo.MergeMode) -> Action:
		merge_mode = mode
		return self

	func is_empty() -> bool:
		return _ops.is_empty()

	func commit() -> void:
		if _ops.is_empty():
			return
		var target: CsgBlockoutSceneOps = CsgBlockoutSceneOps._target()
		var root: Node = CsgBlockoutSceneOps.edited_root()
		var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		var previous_selection: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
		# Undo runs the queued operations in reverse (backward_undo_ops), so compound
		# edits unwind like a stack: e.g. a wrapped wall moves back out of its new
		# combiner before that combiner is removed, keeping the wall's owner.
		ur.create_action(name, merge_mode, root, true)
		if _has_selection:
			# Registered first so that, reversed, it runs after everything is restored.
			ur.add_undo_method(target, &"_do_select", previous_selection)
		for op: Dictionary in _ops:
			match op["kind"]:
				"add":
					ur.add_do_method(target, &"_do_add", op["parent"], op["node"], op["index"], op["xform"], op["own"], op.get("original"))
					ur.add_do_reference(op["node"])
					ur.add_undo_method(target, &"_do_detach", op["node"])
				"remove":
					ur.add_do_method(target, &"_do_detach", op["node"])
					ur.add_undo_method(target, &"_do_add", op["parent"], op["node"], op["index"], null, "keep", null)
					ur.add_undo_reference(op["node"])
				"reparent":
					ur.add_do_method(target, &"_do_reparent", op["node"], op["new_parent"], op["index"])
					ur.add_undo_method(target, &"_do_reparent", op["node"], op["old_parent"], op["old_index"])
				"prop":
					ur.add_do_property(op["obj"], op["prop"], op["new"])
					ur.add_undo_property(op["obj"], op["prop"], op["old"])
				"meta":
					ur.add_do_method(op["obj"], &"set_meta", op["name"], op["new"])
					ur.add_undo_method(op["obj"], &"set_meta", op["name"], op["old"])
		if _has_selection:
			ur.add_do_method(target, &"_do_select", _select_after)
		ur.commit_action()


# --- undo/redo callbacks (instance methods: EditorUndoRedoManager needs an Object) ---

func _do_add(parent: Node, node: Node, index: int, xform: Variant, own_mode: String, original: Variant) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(node):
		return
	if node.get_parent() != parent:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		parent.add_child(node, true)
	if index >= 0:
		parent.move_child(node, mini(index, parent.get_child_count() - 1))
	var root: Node = edited_root()
	if root != null and node != root and _detached_owned.has(node.get_instance_id()):
		# Re-added after an undo/redo detach: restore exactly the previous ownership.
		own_mode = "keep"
	if root != null and node != root:
		match own_mode:
			"subtree":
				own_subtree(node, root)
			"self":
				node.owner = root
			"like":
				if original is Node and is_instance_valid(original):
					own_like(original, node, root)
				else:
					node.owner = root
			"packed":
				# Freshly instantiated from a PackedScene: nodes owned by the packed root
				# become scene-owned; nodes of nested instanced scenes keep their owners.
				var packed_root: Node = node
				_own_packed(node, packed_root, root)
				node.owner = root
			"keep":
				var owned: Array = _detached_owned.get(node.get_instance_id(), [])
				for n: Variant in owned:
					if is_instance_valid(n):
						(n as Node).owner = root
				_detached_owned.erase(node.get_instance_id())
	if xform is Transform3D and node is Node3D:
		(node as Node3D).global_transform = xform

## Ownership of detached subtrees, so undoing a removal restores it exactly
## (remove_child() clears owners that end up outside the subtree).
var _detached_owned: Dictionary = {}

func _do_detach(node: Node) -> void:
	if is_instance_valid(node) and node.get_parent() != null:
		var owned: Array[Node] = []
		_collect_owned(node, edited_root(), owned)
		_detached_owned[node.get_instance_id()] = owned
		_deselect(node)
		node.get_parent().remove_child(node)

func _do_reparent(node: Node, new_parent: Node, index: int) -> void:
	if not is_instance_valid(node) or not is_instance_valid(new_parent):
		return
	var keep: Variant = (node as Node3D).global_transform if node is Node3D and node.is_inside_tree() else null
	var root: Node = edited_root()
	# Remember owners of the moved subtree: remove_child() would otherwise clear them.
	var owned: Array[Node] = []
	_collect_owned(node, root, owned)
	if node.get_parent() != new_parent:
		node.get_parent().remove_child(node)
		new_parent.add_child(node, true)
	if index >= 0:
		new_parent.move_child(node, mini(index, new_parent.get_child_count() - 1))
	for n: Node in owned:
		n.owner = root
	if keep is Transform3D:
		(node as Node3D).global_transform = keep

func _own_packed(n: Node, packed_root: Node, scene_owner: Node) -> void:
	for child: Node in n.get_children():
		if child.owner == packed_root:
			child.owner = scene_owner
		_own_packed(child, packed_root, scene_owner)

func _collect_owned(node: Node, root: Node, out: Array[Node]) -> void:
	if node.owner == root:
		out.append(node)
	for child: Node in node.get_children():
		_collect_owned(child, root, out)

func _do_select(nodes: Array[Node]) -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	for n: Node in nodes:
		if is_instance_valid(n) and n.is_inside_tree():
			selection.add_node(n)

func _deselect(node: Node) -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	if node in selection.get_selected_nodes():
		selection.remove_node(node)
