@tool
class_name CsgBlockoutMeshLibraryExport
extends RefCounted
## Exports CSG roots and frozen nodes as MeshLibrary items for GridMap. Each node
## becomes one item named after it, holding its baked mesh in the node's local space
## (so the node's origin is the tile's pivot), its collision shapes and a rendered
## preview. Exporting into an existing library updates the items whose names match and
## keeps all the others, so GridMaps already painted with it pick up the change.
##
## Collision follows the node's bake options, except that "auto" always means trimesh
## here: GridMap tiles nearly always need collision, while blockout CSG often has
## use_collision off. "none" still exports without collision.

const META_SECTION: String = "csg_blockout"
const META_LAST_PATH: String = "mesh_library_path"
const DEFAULT_FILE: String = "blockout_tiles.tres"
const DEFAULT_PREVIEW_SIZE: int = 64

## What the selection exports: selected CSG trees (by their root) and frozen nodes. A
## selected plain node (a "Tiles" group, the scene root) exports the CSG roots and
## frozen nodes directly under it.
static func selection_nodes() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n: Node in EditorInterface.get_selection().get_selected_nodes():
		var candidates: Array[Node] = [n]
		if not (n is CSGShape3D or CsgBlockoutFreeze.is_frozen(n)):
			candidates = n.get_children()
		for c: Node in candidates:
			var target: Node3D = null
			if CsgBlockoutFreeze.is_frozen(c):
				target = c as Node3D
			elif c is CSGShape3D:
				target = CsgBlockoutShapeInfo.csg_root_of(c)
			if target != null and not out.has(target):
				out.append(target)
	return out

static func last_path() -> String:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	return String(settings.get_project_metadata(META_SECTION, META_LAST_PATH, ""))

static func export_selection_with_dialog() -> void:
	var nodes: Array[Node3D] = selection_nodes()
	if nodes.is_empty():
		CsgBlockoutStatus.report(CsgBlockoutI18n.t("WARN_MESHLIB_NOTHING"), EditorToaster.SEVERITY_WARNING)
		return
	var dialog: EditorFileDialog = EditorFileDialog.new()
	dialog.name = "CsgBlockoutMeshLibraryDialog"
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray(["*.tres ; MeshLibrary", "*.res ; MeshLibrary"])
	dialog.title = CsgBlockoutI18n.tf("MESHLIB_DIALOG_TITLE", [nodes.size()])
	# Picking an existing library merges into it, so "overwrite?" would be misleading.
	CsgBlockoutCompat.disable_overwrite_warning(dialog)
	var last: String = last_path()
	if last.is_empty() or not DirAccess.dir_exists_absolute(last.get_base_dir()):
		dialog.current_file = DEFAULT_FILE
	else:
		dialog.current_path = last
	dialog.file_selected.connect(func(path: String) -> void:
		dialog.queue_free()
		export_items(nodes, path))
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_file_dialog()

## Exports `nodes` into the library at `path` (created if missing). Returns
## {"added", "updated", "skipped": PackedStringArray, "library": MeshLibrary, "error": Error}.
static func export_items(nodes: Array[Node3D], path: String) -> Dictionary:
	var added: int = 0
	var updated: int = 0
	var skipped: PackedStringArray = PackedStringArray()
	var lib: MeshLibrary = null
	if ResourceLoader.exists(path):
		# Reuse the cached instance so open GridMaps using it update right away.
		lib = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as MeshLibrary
		if lib == null:
			CsgBlockoutStatus.report(CsgBlockoutI18n.tf("WARN_MESHLIB_NOT_LIBRARY", [path]), EditorToaster.SEVERITY_ERROR)
			return {"added": 0, "updated": 0, "skipped": skipped, "library": null, "error": ERR_INVALID_DATA}
	else:
		lib = MeshLibrary.new()
	# CSG meshes update one frame after edits.
	await (Engine.get_main_loop() as SceneTree).process_frame
	var ids: Array[int] = []
	var meshes: Array[Mesh] = []
	for node: Node3D in nodes:
		if not is_instance_valid(node) or not node.is_inside_tree():
			continue
		var item_name: String = String(node.name)
		if ids.any(func(id: int) -> bool: return lib.get_item_name(id) == item_name):
			skipped.append(item_name)
			CsgBlockoutStatus.report(CsgBlockoutI18n.tf("WARN_MESHLIB_DUPLICATE", [item_name]), EditorToaster.SEVERITY_WARNING, true)
			continue
		var item: Dictionary = _item_for(node)
		if item.is_empty():
			skipped.append(item_name)
			CsgBlockoutStatus.report(CsgBlockoutI18n.tf("WARN_FREEZE_EMPTY", [item_name]), EditorToaster.SEVERITY_WARNING)
			continue
		var id: int = lib.find_item_by_name(item_name)
		if id < 0:
			id = lib.get_last_unused_item_id()
			lib.create_item(id)
			lib.set_item_name(id, item_name)
			added += 1
		else:
			updated += 1
		lib.set_item_mesh(id, item["mesh"])
		lib.set_item_mesh_transform(id, Transform3D.IDENTITY)
		lib.set_item_mesh_cast_shadow(id, int(item["cast_shadow"]) as RenderingServer.ShadowCastingSetting)
		lib.set_item_shapes(id, item["shapes"])
		ids.append(id)
		meshes.append(item["mesh"])
	var report: Dictionary = {"added": added, "updated": updated, "skipped": skipped, "library": lib, "error": OK}
	if ids.is_empty():
		return report
	var previews: Array[Texture2D] = EditorInterface.make_mesh_previews(meshes, _preview_size())
	for i: int in mini(ids.size(), previews.size()):
		lib.set_item_preview(ids[i], previews[i])
	if lib.resource_path.is_empty():
		lib.take_over_path(path)
	var err: Error = ResourceSaver.save(lib, path)
	report["error"] = err
	if err != OK:
		CsgBlockoutStatus.report("%s: %s" % [path, error_string(err)], EditorToaster.SEVERITY_ERROR)
		return report
	EditorInterface.get_resource_filesystem().update_file(path)
	EditorInterface.get_editor_settings().set_project_metadata(META_SECTION, META_LAST_PATH, path)
	CsgBlockoutStatus.report(CsgBlockoutI18n.tf("MESHLIB_EXPORTED", [added, updated, path]), EditorToaster.SEVERITY_INFO, false,
		CsgBlockoutI18n.t("ACTION_SHOW_IN_FILESYSTEM"), func() -> void: EditorInterface.get_file_system_dock().navigate_to_path(path))
	return report

## {"mesh", "shapes" (Shape3D/Transform3D pairs), "cast_shadow"} or {} without geometry.
static func _item_for(node: Node3D) -> Dictionary:
	if CsgBlockoutFreeze.is_frozen(node):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			return {}
		var shapes: Array = []
		for child: Node in mi.get_children():
			if child is StaticBody3D:
				shapes.append_array(_body_shapes(child as StaticBody3D))
		var mode: String = String(CsgBlockoutBakePipeline.normalized(mi.get_meta(CsgBlockoutFreeze.META_BAKE, {}))["collision"])
		if shapes.is_empty() and mode == "auto":
			shapes = [mi.mesh.create_trimesh_shape(), Transform3D.IDENTITY]
		return {"mesh": _mesh_with_overrides(mi), "shapes": shapes, "cast_shadow": mi.cast_shadow}
	var root: CSGShape3D = node as CSGShape3D
	if root == null:
		return {}
	var opts: Dictionary = CsgBlockoutFreeze.options_for(root)
	opts["occluder"] = false
	if String(opts["collision"]) == "auto":
		opts["collision"] = "trimesh"
	var baked: Dictionary = CsgBlockoutBakePipeline.build(root, opts)
	if baked.is_empty():
		return {}
	var shapes: Array = []
	for gen: Node in baked["generated"]:
		if gen is StaticBody3D:
			shapes.append_array(_body_shapes(gen as StaticBody3D))
		gen.free()
	return {"mesh": baked["mesh"], "shapes": shapes, "cast_shadow": root.cast_shadow}

## Shape3D/Transform3D pairs of a body's enabled CollisionShape3D children, relative
## to the body's parent.
static func _body_shapes(body: StaticBody3D) -> Array:
	var out: Array = []
	for c: Node in body.get_children():
		var col: CollisionShape3D = c as CollisionShape3D
		if col == null or col.disabled or col.shape == null:
			continue
		out.append(_own(col.shape))
		out.append(body.transform * col.transform)
	return out

## The frozen node's mesh, with its material overrides applied (as GridMap has no
## per-cell overrides).
static func _mesh_with_overrides(mi: MeshInstance3D) -> Mesh:
	var mesh: Mesh = _own(mi.mesh) as Mesh
	var overrides: bool = mi.material_override != null
	for s: int in mi.get_surface_override_material_count():
		overrides = overrides or mi.get_surface_override_material(s) != null
	if not overrides:
		return mesh
	if mesh == mi.mesh:
		mesh = mesh.duplicate() as Mesh
	for s: int in mesh.get_surface_count():
		var mat: Material = mi.material_override
		if mat == null and s < mi.get_surface_override_material_count():
			mat = mi.get_surface_override_material(s)
		if mat != null:
			mesh.surface_set_material(s, mat)
	return mesh

## Resources saved inside another file (a scene's sub-resources) are copied, so the
## library owns them; standalone resource files stay shared references.
static func _own(res: Resource) -> Resource:
	if res.resource_path.is_empty() or res.resource_path.contains("::"):
		return res.duplicate()
	return res

static func _preview_size() -> int:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings.has_setting("editors/grid_map/preview_size"):
		return maxi(int(settings.get_setting("editors/grid_map/preview_size")), 16)
	return DEFAULT_PREVIEW_SIZE
