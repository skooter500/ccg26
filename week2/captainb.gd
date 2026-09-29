extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var t = create_tween()
	scale = Vector2.ZERO
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_SPRING)
	
	t.tween_property(self, "scale", Vector2.ONE, 1.5)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
