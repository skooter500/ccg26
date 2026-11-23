@tool
class_name CsgBlockoutGhost
extends RefCounted
## Translucent previews drawn straight through the RenderingServer: nothing is
## added to the scene tree, so previews never get saved or show up in undo.

enum Style { UNION, SUBTRACT, NEUTRAL, WARNING }

const FILL_COLORS: Dictionary = {
	Style.UNION: Color(0.35, 0.62, 1.0, 0.22),
	Style.SUBTRACT: Color(1.0, 0.32, 0.3, 0.26),
	Style.NEUTRAL: Color(1.0, 1.0, 1.0, 0.16),
	Style.WARNING: Color(1.0, 0.72, 0.2, 0.28),
}
const EDGE_COLORS: Dictionary = {
	Style.UNION: Color(0.55, 0.78, 1.0, 0.95),
	Style.SUBTRACT: Color(1.0, 0.5, 0.45, 0.95),
	Style.NEUTRAL: Color(1.0, 1.0, 1.0, 0.8),
	Style.WARNING: Color(1.0, 0.8, 0.3, 0.95),
}

static var _materials: Dictionary = {}
static var _unit_box: BoxMesh
static var _unit_edges: ArrayMesh

var _instances: Array[RID] = []
var _meshes: Array[Mesh] = []

static func _material(style: Style, edges: bool) -> StandardMaterial3D:
	var key: String = "%d_%s" % [style, edges]
	if _materials.has(key):
		return _materials[key]
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = EDGE_COLORS[style] if edges else FILL_COLORS[style]
	mat.no_depth_test = edges
	mat.render_priority = 1 if edges else 0
	_materials[key] = mat
	return mat

static func _get_unit_box() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box

static func _get_unit_edges() -> ArrayMesh:
	if _unit_edges == null:
		var pts: PackedVector3Array = PackedVector3Array()
		var c: Array[Vector3] = []
		for i: int in 8:
			c.append(Vector3(-0.5 if (i & 1) == 0 else 0.5, -0.5 if (i & 2) == 0 else 0.5, -0.5 if (i & 4) == 0 else 0.5))
		for i: int in 8:
			for bit: int in [1, 2, 4]:
				if (i & bit) == 0:
					pts.append(c[i])
					pts.append(c[i | bit])
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pts
		_unit_edges = ArrayMesh.new()
		_unit_edges.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return _unit_edges

static func _scenario() -> RID:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root is Node3D and root.is_inside_tree():
		return (root as Node3D).get_world_3d().scenario
	return RID()

func _add_instance(mesh: Mesh, xform: Transform3D, mat: Material, scenario: RID) -> void:
	var rid: RID = RenderingServer.instance_create2(mesh.get_rid(), scenario)
	RenderingServer.instance_set_transform(rid, xform)
	RenderingServer.instance_geometry_set_material_override(rid, mat.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(rid, RenderingServer.SHADOW_CASTING_SETTING_OFF)
	_instances.append(rid)
	_meshes.append(mesh)

## Draws boxes; each transform maps the unit cube (-0.5..0.5) onto a box.
func show_boxes(xforms: Array[Transform3D], style: Style = Style.UNION) -> void:
	clear()
	var scenario: RID = _scenario()
	if not scenario.is_valid():
		return
	for x: Transform3D in xforms:
		_add_instance(_get_unit_box(), x, _material(style, false), scenario)
		_add_instance(_get_unit_edges(), x, _material(style, true), scenario)

## Draws arbitrary meshes: entries are {"mesh": Mesh, "xform": Transform3D}.
func show_meshes(entries: Array[Dictionary], style: Style = Style.UNION) -> void:
	clear()
	var scenario: RID = _scenario()
	if not scenario.is_valid():
		return
	for e: Dictionary in entries:
		var mesh: Mesh = e.get("mesh")
		if mesh == null:
			continue
		_add_instance(mesh, e.get("xform", Transform3D.IDENTITY), _material(style, false), scenario)
		var box: AABB = mesh.get_aabb()
		var edge_xform: Transform3D = (e.get("xform", Transform3D.IDENTITY) as Transform3D) * Transform3D(Basis.from_scale(box.size.max(Vector3.ONE * 0.001)), box.get_center())
		_add_instance(_get_unit_edges(), edge_xform, _material(style, true), scenario)

func is_visible() -> bool:
	return not _instances.is_empty()

func clear() -> void:
	for rid: RID in _instances:
		RenderingServer.free_rid(rid)
	_instances.clear()
	_meshes.clear()
