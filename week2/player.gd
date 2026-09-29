extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Hello")
	await get_tree().create_timer(2).timeout
	queue_free()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#position = get_global_mouse_position()
	position.y += delta * 50
	print("Hello: " + str(position))
	pass
func _draw() -> void:
	draw_ellipse(Vector2.ZERO, 10, 100, Color.RED)
