@tool
extends Area2D

func _ready() -> void:
	var t = create_tween()
	t.set_trans(Tween.TRANS_QUINT)	
	t.set_ease(Tween.EASE_OUT)

	t.set_ease(Tween.EASE_IN_OUT)
	scale = Vector2.ZERO
	var d = 200
	var target = position
	target.x += d
	t.tween_property(self, "scale", Vector2.ONE * 2, 5)
	t.tween_property(self, "position", target, 2)
	t.tween_property(self, "position", Vector2.UP * d, 2).as_relative()
	t.tween_property(self, "position", Vector2.LEFT * d, 2).as_relative()
	
	
	pass
@export var width = 100 
func _draw() -> void:
	var half_w = width / 2 
	# draw_polygon([Vector2(-half_w, half_w), Vector2(0, -half_w), Vector2(-half_w, half_w)], [Color.BLUE])
	draw_circle(Vector2.ZERO, half_w, Color.RED, false, 5)
	pass
	
func _process(delta: float) -> void:
	queue_redraw()
	


func _on_area_entered(area: Area2D) -> void:
	print("something hit me!!!!!")
	self.queue_free()
	pass # Replace with function body.
