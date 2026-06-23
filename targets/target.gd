extends Area2D

## Se emite justo antes de que este target se elimine, para que quien
## maneje el spawn (Game) pueda crear un reemplazo.
signal target_destroyed

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		target_destroyed.emit()
		queue_free()
