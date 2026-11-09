extends CharacterBody2D


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0, -50), Color.RED)
	draw_line(Vector2(0, -50), Vector2(-20, -30) , Color.RED)
	draw_line(Vector2(0, -50), Vector2(20, -30) , Color.RED)

var speed:float = 100

func _physics_process(delta: float) -> void:
	var player:CharacterBody2D = $"../../player"

	# move_and_slide()
	var to_player = player.global_position - global_position
	to_player = to_player.normalized()
	# position = position + (to_player * delta * speed)
	velocity = lerp(velocity, to_player * speed, delta * 5)
	# transform.x = velocity.normalized()
	#var t = Vector2.UP.angle_to(to_player)
	#rotation = t
	look_at(player.global_position)
	rotate(PI / 2.0)
	move_and_slide()
	
	
	pass
	
func _process(delta: float) -> void:
	queue_redraw()
