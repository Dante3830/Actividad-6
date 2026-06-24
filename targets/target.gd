extends Area2D

signal target_destroyed

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		target_destroyed.emit()
		queue_free()
