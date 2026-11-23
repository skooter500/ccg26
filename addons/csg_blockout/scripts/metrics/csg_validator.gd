@tool
class_name CsgBlockoutValidator
extends RefCounted
## Level checks against the player metrics, run on demand:
##  - walkable-looking surfaces steeper than max_slope_angle ("slope"),
##  - walkable surfaces with a ceiling lower than character_height ("crouch") or
##    lower than crouch_height ("blocked"), found by casting rays straight up.
## Reads every visible CSG root and frozen mesh; nothing in the scene is changed.
## Results are highlighted in the viewport through the RenderingServer.

const WALL_ANGLE: float = 80.0
const SAMPLE_SPACING: float = 0.5
const SURFACE_OFFSET: float = 0.02
const COLORS: Dictionary = {
	"slope": Color(1.0, 0.6, 0.15, 0.55),
	"crouch": Color(1.0, 0.9, 0.2, 0.5),
	"blocked": Color(1.0, 0.25, 0.2, 0.6),
}

static var issues: Array[Dictionary] = []
static var _instance: RID
static var _mesh: ArrayMesh
static var _material: StandardMaterial3D

## Every renderable blockout surface: [{"node": Node3D, "faces": PackedVector3Array (world)}].
static func gather(scene_root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var stack: Array[Node] = [scene_root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var mesh: Mesh = null
		if n is CSGShape3D and (n as CSGShape3D).is_root_shape():
			var meshes: Array = (n as CSGShape3D).get_meshes()
			if meshes.size() >= 2:
				mesh = meshes[1]
		elif n is MeshInstance3D and CsgBlockoutFreeze.is_frozen(n):
			mesh = (n as MeshInstance3D).mesh
		if mesh != null and (n as Node3D).is_visible_in_tree():
			var local: PackedVector3Array = mesh.get_faces()
			var xf: Transform3D = (n as Node3D).global_transform
			var world: PackedVector3Array = PackedVector3Array()
			world.resize(local.size())
			for i: int in local.size():
				world[i] = xf * local[i]
			out.append({"node": n, "faces": world})
			if n is CSGShape3D:
				continue
		stack.append_array(n.get_children())
	return out

## Runs every check on the edited scene, stores and highlights the results.
## `issues` holds one entry per (node, kind) with the worst value and a count;
## `marks` holds the highlighted patches (slope triangles, failing sample cells).
static func run() -> Array[Dictionary]:
	issues.clear()
	marks.clear()
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		show_results()
		return issues
	var m: Dictionary = CsgBlockoutConfig.get_config().get_player_metrics()
	var max_slope: float = m["max_slope_angle"]
	var stand: float = m["character_height"]
	var crouch: float = minf(m["crouch_height"], stand)
	# Ledges narrower than the capsule radius (window sills, wall tops) aren't checked.
	var footing: float = float(m["capsule_radius"]) * 0.5
	var footing_step: float = footing * tan(deg_to_rad(minf(max_slope, 80.0))) + 0.05
	var surfaces: Array[Dictionary] = gather(scene_root)
	var all_faces: PackedVector3Array = PackedVector3Array()
	var owners: Array[Dictionary] = []
	for s: Dictionary in surfaces:
		owners.append({"start": all_faces.size() / 3, "node": s["node"]})
		all_faces.append_array(s["faces"])
	var world_tri: TriangleMesh = TriangleMesh.new()
	if all_faces.is_empty() or not world_tri.create_from_faces(all_faces):
		show_results()
		return issues
	var grouped: Dictionary = {}
	for s: Dictionary in surfaces:
		var faces: PackedVector3Array = s["faces"]
		for i: int in range(0, faces.size() - 2, 3):
			var a: Vector3 = faces[i]
			var b: Vector3 = faces[i + 1]
			var c: Vector3 = faces[i + 2]
			if (b - a).cross(c - a).length() < 0.0002:
				continue
			var n: Vector3 = Plane(a, b, c).normal
			if n.y <= 0.0:
				continue
			var angle: float = rad_to_deg(acos(clampf(n.y, -1.0, 1.0)))
			if angle > WALL_ANGLE:
				continue
			if angle > max_slope + 0.5:
				marks.append({"kind": "slope", "tri": PackedVector3Array([a, b, c]), "normal": n})
				# Report the shape the slope belongs to (the ramp, not its whole tree).
				var centroid: Vector3 = (a + b + c) / 3.0
				_group(grouped, "slope", _closest_primitive(s["node"], centroid), angle, centroid, true)
				continue
			for sample: Vector3 in _grid_samples(a, b, c, n):
				var hit: Dictionary = world_tri.intersect_ray(sample + n * SURFACE_OFFSET, Vector3.UP)
				if hit.is_empty():
					continue
				# Hitting an upward-facing face from below means the sample sits inside
				# solid geometry (e.g. floor covered by a ramp): not walkable, skip it.
				# TriangleMesh's returned normal isn't winding-based, so rebuild it.
				var fi: int = int(hit.get("face_index", -1)) * 3
				if fi >= 0 and fi + 2 < all_faces.size() and Plane(all_faces[fi], all_faces[fi + 1], all_faces[fi + 2]).normal.y > 0.0:
					continue
				var clearance: float = (hit["position"] as Vector3).y - sample.y
				var kind: String = "blocked" if clearance < crouch else ("crouch" if clearance < stand else "")
				if kind.is_empty():
					continue
				if not _has_footing(world_tri, all_faces, sample, footing, footing_step, clearance):
					continue
				marks.append({"kind": kind, "tri": _cell(sample, n), "normal": n})
				# Report the shape that forms the low ceiling: that's what gets edited.
				var ceiling: Node = _ceiling_shape(owners, int(hit.get("face_index", -1)), hit["position"])
				_group(grouped, kind, ceiling if ceiling != null else s["node"], clearance, sample, false)
	for key: String in grouped:
		issues.append(grouped[key])
	issues.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return SEVERITY[x["kind"]] > SEVERITY[y["kind"]])
	show_results()
	return issues

const SEVERITY: Dictionary = {"blocked": 2, "slope": 1, "crouch": 0}

static var marks: Array[Dictionary] = []

## Primitive (or frozen node) owning triangle `face_index`, closest to `point`.
static func _ceiling_shape(owners: Array[Dictionary], face_index: int, point: Vector3) -> Node:
	var owner_node: Node = null
	for o: Dictionary in owners:
		if face_index >= int(o["start"]):
			owner_node = o["node"]
	return _closest_primitive(owner_node, point)

## The visible, non-cutting primitive of CSG tree `owner_node` whose surface is
## closest to `point`; a frozen node (or anything else) is returned as is.
static func _closest_primitive(owner_node: Node, point: Vector3) -> Node:
	if owner_node is CSGShape3D:
		var best: CSGShape3D = null
		var best_d: float = INF
		for prim: CSGShape3D in CsgBlockoutShapeInfo.primitives_under(owner_node):
			if prim.operation == CSGShape3D.OPERATION_SUBTRACTION or not prim.is_visible_in_tree():
				continue
			var d: float = CsgBlockoutShapeInfo.surface_distance(prim, point)
			if d < best_d:
				best_d = d
				best = prim
		if best != null:
			return best
	return owner_node

## Whether someone could stand at `p`: `reach` away along X and along Z, the floor
## goes on (on at least one side of each axis) within `step` of p's height. A sample
## on a ledge narrower than that, like a window sill, has nothing on either side
## across it. Rays start below the ceiling found above p (`clearance`).
static func _has_footing(tri: TriangleMesh, faces: PackedVector3Array, p: Vector3, reach: float, step: float, clearance: float) -> bool:
	var lift: float = minf(step + 0.1, clearance * 0.5)
	for axis: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var supported: bool = false
		for side: float in [-1.0, 1.0]:
			var hit: Dictionary = tri.intersect_ray(p + axis * (side * reach) + Vector3.UP * lift, Vector3.DOWN)
			if hit.is_empty():
				continue
			var fi: int = int(hit.get("face_index", -1)) * 3
			if fi < 0 or fi + 2 >= faces.size() or Plane(faces[fi], faces[fi + 1], faces[fi + 2]).normal.y <= 0.0:
				continue
			if absf((hit["position"] as Vector3).y - p.y) <= step:
				supported = true
				break
		if not supported:
			return false
	return true

## Aggregates findings per (node, kind): worst value and number of hits.
static func _group(grouped: Dictionary, kind: String, node: Node, value: float, point: Vector3, worst_is_max: bool) -> void:
	var key: String = "%d|%s" % [node.get_instance_id(), kind]
	if not grouped.has(key):
		grouped[key] = {"kind": kind, "node": node, "value": value, "point": point, "count": 0}
	var entry: Dictionary = grouped[key]
	entry["count"] = int(entry["count"]) + 1
	var worse: bool = value > float(entry["value"]) if worst_is_max else value < float(entry["value"])
	if worse:
		entry["value"] = value
		entry["point"] = point

## Points of the world XZ grid (SAMPLE_SPACING) that fall inside the triangle,
## lifted onto its plane (the centroid when the triangle is smaller than a cell).
static func _grid_samples(a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	var lo: Vector2 = Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z)))
	var hi: Vector2 = Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z)))
	var plane: Plane = Plane(n, a)
	var tri2: PackedVector2Array = PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)])
	var x: float = (floorf(lo.x / SAMPLE_SPACING) + 0.5) * SAMPLE_SPACING
	while x <= hi.x and out.size() < MAX_SAMPLES_PER_TRIANGLE:
		var z: float = (floorf(lo.y / SAMPLE_SPACING) + 0.5) * SAMPLE_SPACING
		while z <= hi.y and out.size() < MAX_SAMPLES_PER_TRIANGLE:
			if Geometry2D.point_is_inside_triangle(Vector2(x, z), tri2[0], tri2[1], tri2[2]):
				var y: float = (plane.d - plane.normal.x * x - plane.normal.z * z) / plane.normal.y
				out.append(Vector3(x, y, z))
			z += SAMPLE_SPACING
		x += SAMPLE_SPACING
	if out.is_empty():
		out.append((a + b + c) / 3.0)
	return out

const MAX_SAMPLES_PER_TRIANGLE: int = 4000

## Square patch (two triangles) centered on a sample, lying in the surface plane.
static func _cell(p: Vector3, n: Vector3) -> PackedVector3Array:
	var h: float = SAMPLE_SPACING * 0.48
	var t: Vector3 = n.cross(Vector3.FORWARD if absf(n.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var u: Vector3 = n.cross(t).normalized()
	var c0: Vector3 = p - t * h - u * h
	var c1: Vector3 = p + t * h - u * h
	var c2: Vector3 = p + t * h + u * h
	var c3: Vector3 = p - t * h + u * h
	return PackedVector3Array([c0, c1, c2, c0, c2, c3])

# --- stepping through issues ---------------------------------------------------------

## Index of the issue last shown on the status line.
static var cursor: int = -1

## After a check: "no issues", or the first issue with "Next ›".
static func report_results() -> void:
	cursor = -1
	if issues.is_empty():
		CsgBlockoutStatus.report(CsgBlockoutI18n.t("CHECKS_NONE"))
	else:
		show_issue(0)

## Selects the shape of issue `index` (wrapping around), frames it and says what's
## wrong on the status line, with "Next ›" while there are others.
static func show_issue(index: int) -> void:
	if issues.is_empty():
		return
	cursor = posmod(index, issues.size())
	var issue: Dictionary = issues[cursor]
	var node: Node = issue["node"]
	var shape_name: String = "?"
	if is_instance_valid(node) and node.is_inside_tree():
		shape_name = String(node.name)
		var sel: EditorSelection = EditorInterface.get_selection()
		sel.clear()
		sel.add_node(node)
		_frame_selection()
	var text: String = CsgBlockoutI18n.tf("STATUS_CHECK_ISSUE", [cursor + 1, issues.size(), shape_name, describe(issue)])
	var next_label: String = CsgBlockoutI18n.t("ACTION_NEXT") if issues.size() > 1 else ""
	CsgBlockoutStatus.report(text, EditorToaster.SEVERITY_WARNING, false, next_label, func() -> void: show_issue(cursor + 1))

## Frames the selection with the editor's own "Focus Selection" shortcut (whatever key
## the user bound), sent to the 3D viewport after giving it keyboard focus.
static func _frame_selection() -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if not settings.has_shortcut("spatial_editor/focus_selection"):
		return
	var shortcut: Shortcut = settings.get_shortcut("spatial_editor/focus_selection")
	var manager: CsgBlockoutToolManager = CsgBlockoutToolManager.current
	if shortcut == null or CsgBlockoutToolManager.focus_viewport(manager.camera if manager != null else null) == null:
		return
	for ev: InputEvent in shortcut.events:
		if ev is InputEventKey:
			var press: InputEventKey = (ev as InputEventKey).duplicate()
			press.pressed = true
			Input.parse_input_event(press)
			var release: InputEventKey = press.duplicate()
			release.pressed = false
			Input.parse_input_event(release)
			return

# --- highlight ---------------------------------------------------------------------

static func show_results() -> void:
	clear_highlight()
	if marks.is_empty():
		return
	var root: Node = EditorInterface.get_edited_scene_root()
	if not (root is Node3D) or not root.is_inside_tree():
		return
	var verts: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	for mark: Dictionary in marks:
		var off: Vector3 = (mark["normal"] as Vector3) * SURFACE_OFFSET
		for p: Vector3 in mark["tri"]:
			verts.append(p + off)
			colors.append(COLORS[mark["kind"]])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.vertex_color_use_as_albedo = true
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_instance = RenderingServer.instance_create2(_mesh.get_rid(), (root as Node3D).get_world_3d().scenario)
	RenderingServer.instance_geometry_set_material_override(_instance, _material.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(_instance, RenderingServer.SHADOW_CASTING_SETTING_OFF)

static func clear_highlight() -> void:
	if _instance.is_valid():
		RenderingServer.free_rid(_instance)
	_instance = RID()
	_mesh = null

static func clear() -> void:
	issues.clear()
	marks.clear()
	clear_highlight()

## Localized one-line description of an issue.
static func describe(issue: Dictionary) -> String:
	var m: Dictionary = CsgBlockoutConfig.get_config().get_player_metrics()
	var text: String = _describe_kind(issue, m)
	if int(issue.get("count", 1)) > 1:
		text += " (×%d)" % int(issue["count"])
	return text

static func _describe_kind(issue: Dictionary, m: Dictionary) -> String:
	match String(issue["kind"]):
		"slope":
			return CsgBlockoutI18n.tf("ISSUE_SLOPE", ["%.0f" % float(issue["value"]), "%.0f" % float(m["max_slope_angle"])])
		"crouch":
			return CsgBlockoutI18n.tf("ISSUE_CEILING_CROUCH", ["%.2f" % float(issue["value"])])
		_:
			return CsgBlockoutI18n.tf("ISSUE_CEILING_BLOCKED", ["%.2f" % float(issue["value"])])
