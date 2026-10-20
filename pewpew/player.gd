extends CharacterBody2D

@export var bullet_scene:PackedScene
@export var bullet_spawn_point:Node2D

const SPEED = 500.0
const JUMP_VELOCITY = -400.0

const TURN_RATE = 180

func print_stuff():
	var s = ""
	s += "pos"+ str(position) + "\n"
	s += "global position" + str(global_position) + "\n"
	s += "rotation" + str(rotation) + "\n"
	s += "rotation deg" + str(rad_to_deg(rotation)) + "\n"
	s += "transform.x" + str(transform.x) + "\n"
	s += "transfrom.y" + str(transform.y) + "\n"
	s += "global_transform.x" + str(global_transform.x) + "\n"
	s += "glbal_transfrom.y" + str(global_transform.y) + "\n"
	s += "global_transform.x" + str(global_transform.x) + "\n"
	s += "global_transform.y" + str(global_transform.y) + "\n"
	s += "vel" + str(velocity)
	
	
func _process(delta: float) -> void:
	print_stuff()
	pass

func _physics_process(delta: float) -> void:
	# position = position + transform.x
	var r = Input.get_axis("turn_left", "turn_right")
	print(r)

	var rot = deg_to_rad(r * TURN_RATE * delta)
	rotate(rot)
	
	var f = Input.get_axis("move_backwards", "move_forwards")

	var vel = - transform.y * f * SPEED
	print(transform.y)
	velocity = vel
	
	
	if Input.is_action_pressed("fire"):
		var b = bullet_scene.instantiate()
		b.global_position = bullet_spawn_point.global_position
		b.global_rotation = bullet_spawn_point.global_rotation
		get_parent().add_child(b)
	
	move_and_slide()
