extends Node2D

func _ready() -> void:
	await get_tree().create_timer(2).timeout
	self.queue_free()

func _draw() -> void:
	draw_line(Vector2(0, -10), Vector2(0, 10), Color.WHITE, 5)

var speed:float = 200

func  _physics_process(delta: float) -> void:
	translate(- transform.y * speed * delta)
	
func _process(delta: float) -> void:
	queue_redraw()
