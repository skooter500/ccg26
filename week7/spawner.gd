extends Node2D

@export var enemy_scene:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var count = 8
	var theta_inc = PI * 2.0 / count 
	for i in range(count):
		var e = enemy_scene.instantiate()
		add_child(e)
		e.position.x = sin(i * theta_inc) * 100
		e.position.y = cos(i * theta_inc) * 100
		
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
