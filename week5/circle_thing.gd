extends Node2D

func _process(delta: float) -> void:
	self.delta = delta
	queue_redraw()
	pass
	
var r:float = 0
var count:float = 12 
var theta:float = 0
var delta:float = 0
var small_r = 0
func _draw() -> void:
	var x = sin(theta) * r
	var y = cos(theta) * r
	draw_line(Vector2.ZERO, Vector2(x, y), Color.CRIMSON)
	draw_circle(Vector2(x, y), small_r, Color.AQUA)	
	print(theta)
	theta += delta
	small_r += 1
	r += delta * 100
	pass
	
