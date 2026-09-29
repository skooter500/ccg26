extends Node2D

var polygon = [Vector2(50, 10), Vector2(100, 110), Vector2(60, 90)]
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var x:float
var r:float = abs(sin(theta) * 100)
var theta:float

func _draw() -> void:
	var pos:Vector2 = get_local_mouse_position()
	var rect:Rect2 = get_viewport_rect()
	var c = rect.get_center()
	draw_line(Vector2(10, 10), Vector2(200, 200), Color.CHARTREUSE)
	
	draw_polygon([Vector2(10, 10), ], [Color.DARK_MAGENTA])
	draw_circle(Vector2(x, 100), 100, Color.BLUE)
	r = abs(sin(theta) * 100)
	draw_ellipse(c, 100, r, Color.BLANCHED_ALMOND)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	theta += delta
	pass
