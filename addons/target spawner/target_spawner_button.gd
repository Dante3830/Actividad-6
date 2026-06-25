@tool
extends VBoxContainer

@export var target_scene : PackedScene

const SPAWN_REGION_NAME := "SpawnRegion"

# Instanciar target
func _on_spawn_button_pressed() -> void:
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		if node is Area2D:
			var spawned_child = %AddonResourcePicker.edited_resource.instantiate()
			node.add_child(spawned_child)
			spawned_child.owner = get_tree().edited_scene_root
			
			# Elegir posición aleatoria de los targets
			var rect = _get_region_rect(node)
			var local_pos = Vector2(
				randf_range(rect.position.x, rect.position.x + rect.size.x),
				randf_range(rect.position.y, rect.position.y + rect.size.y)
			)
			spawned_child.position = local_pos

# Recibir RectangleShape2D para elegir la ubicación aleatoria
func _get_region_rect(area: Area2D) -> Variant:
	var collision_shape: CollisionShape2D = null
	for child in area.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	if collision_shape == null or collision_shape.shape == null:
		return null
	
	var shape = collision_shape.shape
	if not (shape is RectangleShape2D):
		return null
	
	var rect_shape: RectangleShape2D = shape
	var half_size = rect_shape.size * 0.5
	var local_center = collision_shape.position
	
	return Rect2(local_center - half_size, rect_shape.size)
