extends CharacterBody2D

var speed = 0
var gravity =980
var thrust = -10000
func _draw() -> void:
	draw_rect(Rect2(-50, -20, 100, 40), Color.BEIGE)
#
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		speed += gravity * delta
		print("apply gravity")
	if Input.is_key_pressed(KEY_SPACE):
		print(speed)
		speed += thrust * delta
	var l = Input.get_axis("left", "right")
	velocity = speed * Vector2.DOWN
	velocity += Vector2.RIGHT * speed * l
	move_and_slide()
	pass
func _process(delta: float) -> void:
	queue_redraw()
	pass
