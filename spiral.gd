extends Node2D

var delta:float
@export var count:float = 6
var theta:float = 0
@export var r:float = 100
var t:float = 0
func _draw() -> void:
	rotate(theta)
	var theta_inc = (PI * 2.0) / count
	r = $"../HSlider".value
	count = $"../VSlider".value
	draw_circle(Vector2.ZERO, 50, Color.BLUE)
	var x = 0
	position.y = sin(t * 10) * 200
	t += delta
	for j in range(5):
		for i in range(count):
			r = j * 50 * Input.get_axis("left", "right")
			var c = i / count
			theta = theta_inc * i
			x +=1 
			var y = cos(theta) * r
			draw_circle(Vector2(x, y), 20, Color.from_hsv(c,1,1))
	pass
	
func _process(delta: float) -> void:
	self.delta = delta
	queue_redraw()
	pass
