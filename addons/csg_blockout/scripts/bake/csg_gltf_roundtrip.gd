@tool
class_name CsgBlockoutGltfRoundTrip
extends RefCounted
## glTF round trip for frozen blockout. "Export" writes the frozen mesh as a .glb next
## to the scene (<scene>_blockout/<node>.glb) for refinement in Blender or another DCC
## tool; once the edited file is saved over it and Godot has re-imported it, "Use
## refined mesh" swaps it in (one undo step). The CSG source stays in the node, so
## unfreezing still works: it drops the refined mesh (after asking), the .glb stays.
##
## Material names survive the trip: every surface is exported with a named material,
## and surfaces that come back with one of those names get the original Godot material
## again (shader materials included); materials made in the DCC tool stay as imported.
## Collision stays the blockout's.

const META_GLTF: StringName = &"_csg_blockout_gltf"
const META_REFINED: StringName = &"_csg_blockout_refined"
const FOLDER_SUFFIX: String = "_blockout"
## Shader parameters tried, in order, for the color a shader material is exported with.
const COLOR_PARAMS: PackedStringArray = ["albedo", "albedo_color", "color", "color_a", "base_color"]

# --- paths and state ----------------------------------------------------------------

## res://<scene dir>/<scene>_blockout/<node>.glb, or "" while the scene is unsaved.
static func default_path(frozen: Node) -> String:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null or scene_root.scene_file_path.is_empty():
		return ""
	var scene_path: String = scene_root.scene_file_path
	var folder: String = scene_path.get_base_dir().path_join(scene_path.get_file().get_basename() + FOLDER_SUFFIX)
	return folder.path_join(String(frozen.name).validate_filename() + ".glb")

## Where the node was exported before, otherwise the default path.
static func path_for(frozen: Node) -> String:
	var recorded: String = String((frozen.get_meta(META_GLTF, {}) as Dictionary).get("path", ""))
	return recorded if not recorded.is_empty() else default_path(frozen)

## True when the .glb was saved by something else after Godot exported it.
static func is_changed_externally(frozen: Node) -> bool:
	var info: Dictionary = frozen.get_meta(META_GLTF, {})
	var path: String = String(info.get("path", ""))
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	return FileAccess.get_modified_time(path) != int(info.get("time", 0))

static func uses_refined(frozen: Node) -> bool:
	return frozen.has_meta(META_REFINED)

## True when the refined mesh in use is older than the file (edited again since).
static func refined_outdated(frozen: Node) -> bool:
	if not uses_refined(frozen):
		return false
	var info: Dictionary = frozen.get_meta(META_REFINED, {})
	var path: String = String(info.get("path", ""))
	return FileAccess.file_exists(path) and FileAccess.get_modified_time(path) != int(info.get("time", 0))

## Status line for the inspector panel.
static func status_text(frozen: Node) -> String:
	var path: String = path_for(frozen)
	if path.is_empty():
		return CsgBlockoutI18n.t("GLTF_STATUS_UNSAVED")
	if not FileAccess.file_exists(path):
		return CsgBlockoutI18n.t("GLTF_STATUS_NONE")
	var file: String = path.get_file()
	if uses_refined(frozen) and not refined_outdated(frozen):
		return CsgBlockoutI18n.tf("GLTF_STATUS_APPLIED", [file])
	if refined_outdated(frozen) or (not uses_refined(frozen) and is_changed_externally(frozen)):
		return CsgBlockoutI18n.tf("GLTF_STATUS_READY", [file])
	return CsgBlockoutI18n.tf("GLTF_STATUS_EXPORTED", [file])

static func selected_frozen() -> Array[MeshInstance3D]:
	return CsgBlockoutFreeze.selection_targets()["frozen"]

# --- export -------------------------------------------------------------------------

static func export_selection() -> void:
	var nodes: Array[MeshInstance3D] = selected_frozen()
	if nodes.is_empty():
		CsgBlockoutStatus.report(CsgBlockoutI18n.t("WARN_GLTF_FREEZE_FIRST"), EditorToaster.SEVERITY_WARNING)
		return
	export_nodes(nodes)

## Writes each node's current mesh to its .glb. Files that were edited outside Godot
## since the last export (refinement work) are only overwritten after confirmation.
## Returns the written paths (empty while waiting for that confirmation).
static func export_nodes(nodes: Array[MeshInstance3D], confirmed: bool = false) -> PackedStringArray:
	var written: PackedStringArray = []
	if nodes.is_empty():
		return written
	if default_path(nodes[0]).is_empty():
		CsgBlockoutStatus.report(CsgBlockoutI18n.t("WARN_GLTF_SAVE_SCENE"), EditorToaster.SEVERITY_WARNING)
		return written
	if not confirmed:
		var edited: PackedStringArray = []
		for n: MeshInstance3D in nodes:
			if is_changed_externally(n):
				edited.append(path_for(n).get_file())
		if not edited.is_empty():
			confirm(CsgBlockoutI18n.tf("GLTF_OVERWRITE_CONFIRM", [", ".join(edited)]), func() -> void: export_nodes(nodes, true))
			return written
	for n: MeshInstance3D in nodes:
		if n.mesh == null:
			continue
		var path: String = path_for(n)
		var materials: Dictionary = {}
		var err: Error = _write_glb(n, path, materials)
		if err != OK:
			CsgBlockoutStatus.report("%s: %s" % [path, error_string(err)], EditorToaster.SEVERITY_ERROR)
			continue
		# A record of the export, not a scene edit: no undo step, but the scene must be
		# saved to keep it.
		n.set_meta(META_GLTF, {"path": path, "time": FileAccess.get_modified_time(path), "materials": materials})
		written.append(path)
	if not written.is_empty():
		EditorInterface.mark_scene_as_unsaved()
		EditorInterface.get_resource_filesystem().scan()
		var folder: String = ProjectSettings.globalize_path(written[0].get_base_dir())
		CsgBlockoutStatus.report(CsgBlockoutI18n.tf("GLTF_EXPORTED", [written.size(), written[0].get_base_dir()]), EditorToaster.SEVERITY_INFO, false,
			CsgBlockoutI18n.t("ACTION_OPEN_FOLDER"), func() -> void: OS.shell_open(folder))
	return written

## Exports `frozen`'s mesh as a single glTF node named after it. Fills `materials`
## with name -> original material for the trip back.
static func _write_glb(frozen: MeshInstance3D, path: String, materials: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var mesh: Mesh = frozen.mesh.duplicate() as Mesh
	var proxies: Dictionary = {}
	for s: int in mesh.get_surface_count():
		var original: Material = frozen.get_active_material(s)
		var key: int = original.get_instance_id() if original != null else 0
		if not proxies.has(key):
			var mat_name: String = _material_name(original, materials)
			materials[mat_name] = original
			proxies[key] = _export_material(original, mat_name)
		mesh.surface_set_material(s, proxies[key])
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = frozen.name
	node.mesh = mesh
	var doc: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err: Error = doc.append_from_scene(node, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(path))
	node.free()
	return err

## Readable, unique name for a material: its resource name, else its file name.
static func _material_name(mat: Material, taken: Dictionary) -> String:
	var base: String = "default"
	if mat != null:
		if not mat.resource_name.is_empty():
			base = mat.resource_name
		elif not mat.resource_path.is_empty() and not mat.resource_path.contains("::"):
			base = mat.resource_path.get_file().get_basename()
		else:
			base = "material"
	var candidate: String = base
	var i: int = 2
	while taken.has(candidate):
		candidate = "%s_%d" % [base, i]
		i += 1
	return candidate

## A glTF-friendly stand-in: standard materials are exported as they are (renamed),
## anything else as a flat color taken from its shader parameters.
static func _export_material(mat: Material, mat_name: String) -> Material:
	if mat is BaseMaterial3D:
		var copy: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
		copy.resource_name = mat_name
		return copy
	var proxy: StandardMaterial3D = StandardMaterial3D.new()
	proxy.resource_name = mat_name
	proxy.albedo_color = Color(0.8, 0.8, 0.8)
	if mat is ShaderMaterial:
		for param: String in COLOR_PARAMS:
			var value: Variant = (mat as ShaderMaterial).get_shader_parameter(param)
			if value is Color:
				proxy.albedo_color = value
				break
	return proxy

# --- use refined mesh ---------------------------------------------------------------

static func apply_selection() -> void:
	var nodes: Array[MeshInstance3D] = selected_frozen()
	if nodes.is_empty():
		CsgBlockoutStatus.report(CsgBlockoutI18n.t("WARN_GLTF_FREEZE_FIRST"), EditorToaster.SEVERITY_WARNING)
		return
	apply_refined(nodes)

## Swaps in the re-imported mesh of each node's .glb, as one undo step.
static func apply_refined(nodes: Array[MeshInstance3D]) -> void:
	var action: CsgBlockoutSceneOps.Action = CsgBlockoutSceneOps.Action.new(CsgBlockoutI18n.t("GLTF_APPLY_ACTION"))
	for frozen: MeshInstance3D in nodes:
		var path: String = path_for(frozen)
		if path.is_empty() or not ResourceLoader.exists(path):
			CsgBlockoutStatus.report(CsgBlockoutI18n.tf("WARN_GLTF_NOT_IMPORTED", [path if not path.is_empty() else String(frozen.name)]), EditorToaster.SEVERITY_WARNING)
			continue
		var materials: Dictionary = (frozen.get_meta(META_GLTF, {}) as Dictionary).get("materials", {})
		var lod: bool = bool(CsgBlockoutBakePipeline.normalized(frozen.get_meta(CsgBlockoutFreeze.META_BAKE, {}))["lod"])
		var mesh: ArrayMesh = load_refined_mesh(path, materials, lod)
		if mesh == null:
			CsgBlockoutStatus.report(CsgBlockoutI18n.tf("WARN_GLTF_NO_MESH", [path]), EditorToaster.SEVERITY_WARNING)
			continue
		action.set_property(frozen, &"mesh", mesh)
		action.assign_meta(frozen, META_REFINED, {"path": path, "time": FileAccess.get_modified_time(path)})
	if not action.is_empty():
		action.commit()

## All meshes of the imported scene merged into one (in the scene root's space), with
## the exported material names mapped back to their Godot materials.
static func load_refined_mesh(path: String, materials: Dictionary, lod: bool = false) -> ArrayMesh:
	var packed: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return null
	var scene: Node = packed.instantiate()
	if scene == null:
		return null
	var parts: Array[Dictionary] = []
	_collect_meshes(scene, Transform3D.IDENTITY, true, parts)
	var out: ArrayMesh = null
	if parts.size() == 1 and (parts[0]["xform"] as Transform3D).is_equal_approx(Transform3D.IDENTITY) and parts[0]["mesh"] is ArrayMesh:
		out = (parts[0]["mesh"] as ArrayMesh).duplicate() as ArrayMesh
		var inst: MeshInstance3D = parts[0]["node"]
		for s: int in out.get_surface_count():
			out.surface_set_material(s, inst.get_active_material(s))
	elif not parts.is_empty():
		out = _merge(parts)
		if lod and out != null:
			out = CsgBlockoutBakePipeline._with_lods(out)
	scene.free()
	if out == null or out.get_surface_count() == 0:
		return null
	for s: int in out.get_surface_count():
		var mat: Material = out.surface_get_material(s)
		var found: Variant = _original_material(mat, materials)
		if found is bool:
			continue
		out.surface_set_material(s, found as Material)
	return out

static func _collect_meshes(n: Node, xform: Transform3D, is_root: bool, out: Array[Dictionary]) -> void:
	var here: Transform3D = xform
	if n is Node3D and not is_root:
		here = xform * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).visible:
		out.append({"node": n, "mesh": (n as MeshInstance3D).mesh, "xform": here})
	for c: Node in n.get_children():
		_collect_meshes(c, here, false, out)

## One surface per material.
static func _merge(parts: Array[Dictionary]) -> ArrayMesh:
	var tools: Dictionary = {}
	var mats: Dictionary = {}
	for part: Dictionary in parts:
		var mesh: Mesh = part["mesh"]
		var inst: MeshInstance3D = part["node"]
		for s: int in mesh.get_surface_count():
			if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var mat: Material = inst.get_active_material(s)
			var key: int = mat.get_instance_id() if mat != null else 0
			if not tools.has(key):
				tools[key] = SurfaceTool.new()
				mats[key] = mat
			(tools[key] as SurfaceTool).append_from(mesh, s, part["xform"])
	var out: ArrayMesh = ArrayMesh.new()
	for key: int in tools:
		(tools[key] as SurfaceTool).commit(out)
		out.surface_set_material(out.get_surface_count() - 1, mats[key])
	return out

## The Godot material exported under this material's name (also matching Blender's
## ".001" duplicates), or false when it's a new material.
static func _original_material(mat: Material, materials: Dictionary) -> Variant:
	if mat == null:
		return false
	var mat_name: String = mat.resource_name
	if materials.has(mat_name):
		return materials[mat_name]
	var dot: int = mat_name.rfind(".")
	if dot > 0 and mat_name.substr(dot + 1).is_valid_int():
		var base: String = mat_name.substr(0, dot)
		if materials.has(base):
			return materials[base]
	return false

# --- unfreeze guard -----------------------------------------------------------------

## Unfreezes, asking first when a node uses a refined mesh (unfreezing drops it).
static func unfreeze_with_confirm(nodes: Array[MeshInstance3D]) -> void:
	var refined: PackedStringArray = []
	for n: MeshInstance3D in nodes:
		if uses_refined(n):
			refined.append(String(n.name))
	if refined.is_empty():
		CsgBlockoutFreeze.unfreeze(nodes)
		return
	confirm(CsgBlockoutI18n.tf("GLTF_UNFREEZE_CONFIRM", [", ".join(refined)]), func() -> void: CsgBlockoutFreeze.unfreeze(nodes))

static func confirm(text: String, on_ok: Callable) -> ConfirmationDialog:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.name = "CsgBlockoutConfirm"
	dialog.title = "CSG Blockout"
	dialog.dialog_text = text
	dialog.dialog_autowrap = true
	dialog.min_size = Vector2i(roundi(420 * EditorInterface.get_editor_scale()), 0)
	dialog.confirmed.connect(func() -> void:
		on_ok.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	return dialog
