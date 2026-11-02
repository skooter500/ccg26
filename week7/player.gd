
extends CharacterBody2D

func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0, -50), Color.WHITE)
	draw_line(Vector2(0, -50), Vector2(-20, -30) , Color.WHITE)
	draw_line(Vector2(0, -50), Vector2(20, -30) , Color.WHITE)
	
func _physics_process(delta: float) -> void:
	pass
	
func _process(delta: float) -> void:
	queue_redraw()
	var s = "{0}\n{1}\n{2}\n{3}" \
		.format([position, rotation, global_position, global_rotation])
	
	$"../Label".text = s
	# global_position.x += 1
	# global_position.y += 1
	# rotation += delta
	global_position = get_viewport().get_mouse_position()
