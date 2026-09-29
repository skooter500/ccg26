extends CharacterBody2D


@export var size:float = 200
@export var line_color:Color
@export var bullet_scene:PackedScene

func _draw() -> void:
	var h_size:float = size / 2
	draw_line(Vector2(-h_size, h_size), Vector2(0, - h_size), line_color, 5)
	draw_line(Vector2(0, - h_size), Vector2(h_size, + h_size), line_color, 5)
	draw_line(Vector2(h_size, + h_size), Vector2(0, 0), line_color, 5)
	draw_line(Vector2(0, 0), Vector2(-h_size, h_size), line_color, 5)
	pass

func _ready() -> void:
	pass
	
var speed = 500
var rot_speed:float = PI
func _physics_process(delta: float) -> void:
	var f = Input.get_axis("back", "forward")
	# print(f)
	print(transform.y)
	velocity = f * - transform.y * speed
	
	move_and_slide()
	var r = Input.get_axis("left", "right")
	rotate(r * rot_speed * delta)
	$"../down_direction".text = "Down: " + str(transform.y)
	
	if Input.is_action_pressed("fire"):
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)

		b.rotation = rotation
		b.global_position = global_position
		
func _process(delta: float) -> void:
	queue_redraw()
	pass
