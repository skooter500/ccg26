extends Node2D

# when the scene is loaded, assign these variables from the scene
@onready var ufo_spawner = $ufo_spawner
@onready var dude = $dude

var target = 0
var level = 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_tree().quit()	

func _ready() -> void:
	next_level()

func next_level():
	ufo_spawner.radius = randf_range(200, 250)
	ufo_spawner.count = 1
	ufo_spawner.rate  = level + 1
	ufo_spawner.position = dude.position
	ufo_spawner.spawn()	
	level = level + 1
	# next target
	target = target + ufo_spawner.count


func _process(delta):
	# if the dude reaches the target, advance to next level
	if dude.ufo_count == target:
		next_level()
	$CanvasLayer/target.text="target_count: " + str(target)
	$CanvasLayer/level.text="level: " + str(level)
	pass


func _on_gravity_well_body_entered(body: Node2D) -> void:
	if body.is_in_group("dude"):
		body.gravity = true
	pass # Replace with function body.


func _on_gravity_well_body_exited(body: Node2D) -> void:
	if body.is_in_group("dude"):
		body.gravity = false
	
	pass # Replace with function body.
