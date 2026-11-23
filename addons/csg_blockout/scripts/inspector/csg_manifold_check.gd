@tool
class_name CsgBlockoutManifoldCheck
extends RefCounted
## Manifold check for meshes used by CSGMesh3D. Since Godot 4.4, CSG runs on the
## Manifold library: a mesh that isn't a closed, consistently oriented 2-manifold can
## silently give empty or wrong results, and the engine only warns when the result is
## completely empty. Vertices are welded by position first (Godot does the same, so
## e.g. BoxMesh with split normals is fine); zero-area triangles are ignored.

const WELD_SCALE: float = 10000.0
const MAX_TRIANGLES: int = 300000
const MAX_MARKED_EDGES: int = 5000

static var _cache: Dictionary = {}

## {"triangles", "open", "non_manifold", "flipped", "degenerate", "ok", "skipped",
##  "problem_edges": PackedVector3Array (pairs, mesh-local)}
static func analyze(mesh: Mesh) -> Dictionary:
	var faces: PackedVector3Array = mesh.get_faces()
	var tri_count: int = faces.size() / 3
	var result: Dictionary = {"triangles": tri_count, "open": 0, "non_manifold": 0, "flipped": 0, "degenerate": 0, "ok": true, "skipped": false, "problem_edges": PackedVector3Array()}
	if tri_count > MAX_TRIANGLES:
		result["skipped"] = true
		return result
	var ids: Dictionary = {}
	var positions: PackedVector3Array = PackedVector3Array()
	var edges: Dictionary = {}
	for t: int in tri_count:
		var tri: PackedInt32Array = PackedInt32Array()
		for k: int in 3:
			var p: Vector3 = faces[t * 3 + k]
			var key: Vector3i = Vector3i(roundi(p.x * WELD_SCALE), roundi(p.y * WELD_SCALE), roundi(p.z * WELD_SCALE))
			if not ids.has(key):
				ids[key] = positions.size()
				positions.append(p)
			tri.append(ids[key])
		if tri[0] == tri[1] or tri[1] == tri[2] or tri[0] == tri[2]:
			result["degenerate"] = int(result["degenerate"]) + 1
			continue
		for k: int in 3:
			var a: int = tri[k]
			var b: int = tri[(k + 1) % 3]
			var ek: Vector2i = Vector2i(mini(a, b), maxi(a, b))
			var entry: Vector2i = edges.get(ek, Vector2i.ZERO)
			# x: uses, y: uses going from the lower to the higher index.
			edges[ek] = Vector2i(entry.x + 1, entry.y + (1 if a < b else 0))
	var marked: PackedVector3Array = PackedVector3Array()
	for ek: Vector2i in edges:
		var e: Vector2i = edges[ek]
		var bad: bool = false
		if e.x == 1:
			result["open"] = int(result["open"]) + 1
			bad = true
		elif e.x > 2:
			result["non_manifold"] = int(result["non_manifold"]) + 1
			bad = true
		elif e.y != 1:
			# Two faces walking the edge the same way: one of them is flipped.
			result["flipped"] = int(result["flipped"]) + 1
			bad = true
		if bad and marked.size() < MAX_MARKED_EDGES * 2:
			marked.append(positions[ek.x])
			marked.append(positions[ek.y])
	result["problem_edges"] = marked
	result["ok"] = int(result["open"]) == 0 and int(result["non_manifold"]) == 0 and int(result["flipped"]) == 0
	return result

## Cached per mesh; the entry is dropped when the mesh emits `changed`.
static func analyze_cached(mesh: Mesh) -> Dictionary:
	var key: int = mesh.get_instance_id()
	if _cache.has(key):
		return _cache[key]
	var result: Dictionary = analyze(mesh)
	_cache[key] = result
	if not mesh.changed.is_connected(_forget.bind(key)):
		mesh.changed.connect(_forget.bind(key), CONNECT_ONE_SHOT)
	return result

static func _forget(key: int) -> void:
	_cache.erase(key)

static func describe(result: Dictionary) -> String:
	if bool(result["skipped"]):
		return CsgBlockoutI18n.tf("MANIFOLD_SKIPPED", [int(result["triangles"])])
	if bool(result["ok"]):
		return CsgBlockoutI18n.t("MANIFOLD_OK")
	return CsgBlockoutI18n.tf("MANIFOLD_BAD", [int(result["open"]), int(result["non_manifold"]), int(result["flipped"])])

# --- viewport highlight -------------------------------------------------------------

static var _instance: RID
static var _lines: ArrayMesh
static var _material: StandardMaterial3D

static func show_edges(node: Node3D, result: Dictionary) -> void:
	clear_edges()
	var pts: PackedVector3Array = result.get("problem_edges", PackedVector3Array())
	if pts.is_empty() or not node.is_inside_tree():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	_lines = ArrayMesh.new()
	_lines.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.albedo_color = Color(1.0, 0.2, 0.2)
		_material.no_depth_test = true
		_material.render_priority = 2
	_instance = RenderingServer.instance_create2(_lines.get_rid(), node.get_world_3d().scenario)
	RenderingServer.instance_set_transform(_instance, node.global_transform)
	RenderingServer.instance_geometry_set_material_override(_instance, _material.get_rid())

static func clear_edges() -> void:
	if _instance.is_valid():
		RenderingServer.free_rid(_instance)
	_instance = RID()
	_lines = null
