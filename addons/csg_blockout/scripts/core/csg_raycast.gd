@tool
class_name CsgBlockoutRaycast
extends RefCounted
## Mouse picking against the edited scene without physics: RenderingServer culls
## instances along the ray, then each CSG root (or MeshInstance3D, e.g. frozen
## blockout) is tested precisely through a cached triangle BVH.

const RAY_LENGTH: float = 4000.0

class Hit:
	extends RefCounted
	var position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.UP
	var distance: float = INF
	## CSG root or MeshInstance3D that was hit; null when the work plane was hit.
	var collider: Node3D
	## Primitive whose surface is closest to the hit point (CSG hits only).
	var shape: CSGShape3D
	## Closest union/intersection primitive (useful when the hit lands on a cut face).
	var solid_shape: CSGShape3D
	var on_plane: bool = false
	var ray_origin: Vector3 = Vector3.ZERO
	var ray_dir: Vector3 = Vector3.FORWARD

	func is_valid() -> bool:
		return distance < INF

## node instance id -> {"mesh": mesh instance id, "tri": TriangleMesh}
static var _cache: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()

## Casts from the camera through `screen_pos` (viewport coordinates).
## exclude: nodes whose subtree is ignored. use_plane: fall back to y = plane_height.
static func cast(camera: Camera3D, screen_pos: Vector2, exclude: Array = [], use_plane: bool = true, plane_height: float = 0.0) -> Hit:
	var origin: Vector3 = camera.project_ray_origin(screen_pos)
	var dir: Vector3 = camera.project_ray_normal(screen_pos)
	return cast_ray(origin, dir, exclude, use_plane, plane_height)

static func cast_ray(origin: Vector3, dir: Vector3, exclude: Array = [], use_plane: bool = true, plane_height: float = 0.0) -> Hit:
	var best: Hit = Hit.new()
	best.ray_origin = origin
	best.ray_dir = dir
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null or not (root is Node3D) or not root.is_inside_tree():
		return best
	var scenario: RID = (root as Node3D).get_world_3d().scenario
	var ids: PackedInt64Array = RenderingServer.instances_cull_ray(origin, origin + dir * RAY_LENGTH, scenario)
	for id: int in ids:
		var obj: Object = instance_from_id(id)
		if not (obj is GeometryInstance3D):
			continue
		var node: Node3D = obj as Node3D
		if not _pickable(node, root, exclude):
			continue
		var tri: TriangleMesh = _triangles_for(node)
		if tri == null:
			continue
		var to_local: Transform3D = node.global_transform.affine_inverse()
		var res: Dictionary = tri.intersect_ray(to_local * origin, to_local.basis * dir)
		if res.is_empty():
			continue
		var world_pos: Vector3 = node.global_transform * (res["position"] as Vector3)
		var d: float = origin.distance_to(world_pos)
		if d >= best.distance:
			continue
		var n: Vector3 = (node.global_transform.basis.inverse().transposed() * (res["normal"] as Vector3)).normalized()
		if n.dot(dir) > 0.0:
			n = -n
		best.position = world_pos
		best.normal = n
		best.distance = d
		best.collider = node
	if best.is_valid():
		if best.collider is CSGShape3D:
			_resolve_primitives(best)
		return best
	if use_plane and absf(dir.y) > 0.0001:
		var t: float = (plane_height - origin.y) / dir.y
		if t > 0.0 and t < RAY_LENGTH:
			best.position = origin + dir * t
			best.normal = Vector3.UP
			best.distance = t
			best.on_plane = true
	return best

static func _pickable(node: Node3D, root: Node, exclude: Array) -> bool:
	if node != root and not root.is_ancestor_of(node):
		return false
	if not node.is_visible_in_tree():
		return false
	for ex: Variant in exclude:
		if ex is Node and is_instance_valid(ex) and (ex == node or (ex as Node).is_ancestor_of(node)):
			return false
	if node is CSGShape3D:
		return (node as CSGShape3D).is_root_shape()
	return node is MeshInstance3D and (node as MeshInstance3D).mesh != null

static func _triangles_for(node: Node3D) -> TriangleMesh:
	var mesh: Mesh = null
	if node is CSGShape3D:
		var meshes: Array = (node as CSGShape3D).get_meshes()
		if meshes.size() >= 2 and meshes[1] is Mesh:
			mesh = meshes[1]
	elif node is MeshInstance3D:
		mesh = (node as MeshInstance3D).mesh
	if mesh == null:
		return null
	var key: int = node.get_instance_id()
	var cached: Dictionary = _cache.get(key, {})
	if cached.get("mesh", 0) == mesh.get_instance_id():
		return cached["tri"]
	var faces: PackedVector3Array = mesh.get_faces()
	if faces.is_empty():
		return null
	var tri: TriangleMesh = TriangleMesh.new()
	if not tri.create_from_faces(faces):
		return null
	_cache[key] = {"mesh": mesh.get_instance_id(), "tri": tri}
	return tri

static func _resolve_primitives(hit: Hit) -> void:
	var best_any: float = INF
	var best_solid: float = INF
	for prim: CSGShape3D in CsgBlockoutShapeInfo.primitives_under(hit.collider):
		if not prim.is_visible_in_tree():
			continue
		var d: float = CsgBlockoutShapeInfo.surface_distance(prim, hit.position)
		if d < best_any:
			best_any = d
			hit.shape = prim
		if prim.operation != CSGShape3D.OPERATION_SUBTRACTION and d < best_solid:
			best_solid = d
			hit.solid_shape = prim
