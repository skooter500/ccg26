extends  Node2D

func _ready() -> void:
	pass
	
var x = 0 # declaring
@export var speed:float = 100

func _process(delta: float) -> void:
	queue_redraw()
	x += delta * speed
	print(speed)
	pass
	
func _draw() -> void:
	draw_circle(Vector2(x, 500), 50, Color.RED)
	pass
