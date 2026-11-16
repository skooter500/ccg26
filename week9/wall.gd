extends Node2D

@export var block_scene:PackedScene
@export var block_count:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(block_count):
		var block = block_scene.instantiate()
		add_child(block)
		block.position = Vector2(0, - i * 50)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
