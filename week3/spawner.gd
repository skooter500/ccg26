extends Node2D

@export var thing:PackedScene

var count = 100

func _ready() -> void:
	var r = get_viewport_rect()
	for i in range(count):
		var x = randf_range(0, r.size.x)
		var y = randf_range(0, r.size.y)
		var t = thing.instantiate()
		t.position = Vector2(x,y)
		add_child(t)
		await get_tree().create_timer(0.1).timeout
