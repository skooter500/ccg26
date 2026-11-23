extends Node
## Entry scene for "Play From Here". The editor writes a request (scene, spawn point,
## facing, player metrics) to user://csg_blockout/play_here.json and runs this scene.
## The launcher loads the requested scene as the current scene, gives blockout without
## collision a collision for this run, adds a default sun and sky when the scene has no
## lighting, and spawns the test pawn.
## Runtime script: must not reference editor classes.

const REQUEST_PATH: String = "user://csg_blockout/play_here.json"
const REPORT_PATH: String = "user://csg_blockout/play_here_report.json"
const SCREENSHOT_PATH: String = "user://csg_blockout/play_here.png"
const PawnScript = preload("res://addons/csg_blockout/scripts/runtime/csg_test_pawn.gd")
## Metadata that marks a frozen blockout node (CsgBlockoutFreeze.META_SOURCE).
const META_FROZEN_SOURCE: StringName = &"_csg_blockout_source"

var _collision_added: int = 0

func _ready() -> void:
	var request: Dictionary = _read_request()
	if request.is_empty():
		push_error("CSG Blockout: no Play From Here request found at %s." % REQUEST_PATH)
		get_tree().quit(1)
		return
	var packed: PackedScene = load(String(request.get("scene", ""))) as PackedScene
	if packed == null:
		push_error("CSG Blockout: can't load scene %s." % request.get("scene", ""))
		get_tree().quit(1)
		return
	var scene: Node = packed.instantiate()
	var root: Window = get_tree().root
	root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = scene
	_collision_added = _ensure_collision(scene)
	if _collision_added > 0:
		# CSG builds its collision on its next update; let it happen before the pawn falls.
		await get_tree().process_frame
		await get_tree().physics_frame
	_ensure_lighting(scene)
	var pos: Array = request.get("position", [0.0, 0.0, 0.0])
	var spawn: Transform3D = Transform3D(Basis(Vector3.UP, float(request.get("yaw", 0.0))), Vector3(float(pos[0]), float(pos[1]), float(pos[2])))
	var test_mode: bool = bool(request.get("test_mode", false))
	var pawn: CSGBlockoutTestPawn = PawnScript.new()
	pawn.name = "CSGBlockoutTestPawn"
	pawn.capture_mouse = not test_mode
	pawn.hud_text = String(request.get("hud", ""))
	pawn.setup(request.get("metrics", {}), spawn)
	scene.add_child(pawn)
	if test_mode:
		# Stay alive until the report is written (a freed node's coroutine never resumes).
		await _report_later(pawn)
	else:
		queue_free()

func _read_request() -> Dictionary:
	if not FileAccess.file_exists(REQUEST_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REQUEST_PATH))
	return parsed if parsed is Dictionary else {}

## Turns on collision for visible CSG trees without it and gives frozen blockout
## without a collision body a trimesh one, so the pawn can stand on everything it
## sees. Only this run changes; the scene file doesn't. Returns how many were fixed.
## Counts like CsgBlockoutPlayHere.count_without_collision() in the editor.
func _ensure_collision(scene: Node) -> int:
	var count: int = 0
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CSGShape3D and (n as CSGShape3D).is_root_shape():
			if (n as CSGShape3D).is_visible_in_tree() and not (n as CSGShape3D).use_collision:
				(n as CSGShape3D).use_collision = true
				count += 1
			continue
		if n is MeshInstance3D and n.has_meta(META_FROZEN_SOURCE) and (n as Node3D).is_visible_in_tree() \
				and not n.get_children().any(func(c: Node) -> bool: return c is CollisionObject3D):
			(n as MeshInstance3D).create_trimesh_collision()
			count += 1
		stack.append_array(n.get_children())
	return count

## Adds a sun and a procedural sky when the scene has no light or environment of
## its own (blockout scenes usually rely on the editor's preview lighting).
func _ensure_lighting(scene: Node) -> void:
	var has_light: bool = not scene.find_children("*", "DirectionalLight3D", true, false).is_empty()
	var has_env: bool = not scene.find_children("*", "WorldEnvironment", true, false).is_empty()
	if not has_light:
		var sun: DirectionalLight3D = DirectionalLight3D.new()
		sun.name = "CSGBlockoutPreviewSun"
		sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(150.0), 0.0)
		sun.shadow_enabled = true
		scene.add_child(sun)
	if not has_env:
		var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.385, 0.454, 0.55)
		sky_mat.ground_bottom_color = Color(0.2, 0.169, 0.133)
		var sky: Sky = Sky.new()
		sky.sky_material = sky_mat
		var env: Environment = Environment.new()
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		var world_env: WorldEnvironment = WorldEnvironment.new()
		world_env.name = "CSGBlockoutPreviewEnvironment"
		world_env.environment = env
		scene.add_child(world_env)

## Test mode (used by automated checks): after the pawn settles, write its state and
## a screenshot, then quit.
func _report_later(pawn: CharacterBody3D) -> void:
	var tree: SceneTree = get_tree()
	await tree.create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var img: Image = tree.root.get_texture().get_image()
	img.save_png(SCREENSHOT_PATH)
	var report: Dictionary = {
		"position": [pawn.global_position.x, pawn.global_position.y, pawn.global_position.z],
		"on_floor": pawn.is_on_floor(),
		"camera_current": tree.root.get_camera_3d() != null and pawn.is_ancestor_of(tree.root.get_camera_3d()),
		"current_scene": String(tree.current_scene.name) if tree.current_scene != null else "",
		"floor_max_angle": rad_to_deg(pawn.floor_max_angle),
		"walk_speed": float(pawn.get(&"_walk_speed")),
		"sprint_speed": float(pawn.get(&"_sprint_speed")),
		"jump_velocity": float(pawn.get(&"_jump_velocity")),
		"has_sun": not tree.current_scene.find_children("CSGBlockoutPreviewSun", "DirectionalLight3D", true, false).is_empty(),
		"collision_added": _collision_added,
	}
	var f: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()
	tree.quit()
