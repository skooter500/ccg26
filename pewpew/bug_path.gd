extends Node2D

func _draw() -> void:
	draw_circle(Vector2.ZERO, 100, Color.WEB_GREEN)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var speed = 200

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var p:PathFollow2D = get_parent()
	queue_redraw()
	p.progress += delta * speed
	pass
