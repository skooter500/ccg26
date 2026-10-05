extends Node2D

func _process(delta: float) -> void:
	var i = get_child_count()
	$bullets_label.text = "Bullets:" + str(i)
