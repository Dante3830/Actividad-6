extends Area2D
class_name Bullet

var shot_velocity := Vector2.ZERO
var shot_gravity := Vector2.ZERO

func _process(delta: float) -> void:
	shot_velocity += shot_gravity * delta 
	position += shot_velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
