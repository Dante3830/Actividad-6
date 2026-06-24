@tool
extends Node2D

## Escena a instanciar (arrastrá tu target.tscn acá desde el FileSystem).
@export var target_scene:PackedScene

## Nombre que debe tener el Area2D hijo (en cualquier nivel de Game) que define la región de spawn.
const SPAWN_REGION_NAME := "SpawnRegion"

## Botón real de inspector (Godot 4.4+). Al presionarlo, agrega un target.
@export_tool_button("Agregar Target", "Node2D") var add_random_target_action = _spawn_random_target

func _spawn_random_target() -> void:
	if not Engine.is_editor_hint():
		return

	var instance := _create_target_instance()
	if instance == null:
		return

	# CLAVE: asignar el owner a la raíz de la escena editada es lo que hace
	# que el nodo quede guardado junto con la escena al presionar Ctrl+S.
	var edited_root := get_tree().edited_scene_root
	if edited_root == null:
		push_warning("Target Spawner: no se pudo determinar la raíz de la escena editada (edited_scene_root es null). El nodo NO va a guardarse. ¿Estás corriendo esto fuera del editor o con una escena no guardada todavía?")
		return

	_set_owner_recursive(instance, edited_root)

	# Verificación: si Game está anidado dentro de una escena instanciada
	# (no es la raíz), Godot solo guarda hijos nuevos si esa instancia
	# está marcada como "Editable Children". Avisamos si detectamos el caso.
	if self != edited_root and get_scene_file_path() != "":
		push_warning(str("Target Spawner: 'Game' parece ser una instancia de escena (", get_scene_file_path(), ") dentro de otra escena. Para que el nuevo target se guarde, hacé click derecho sobre 'Game' en el árbol → 'Editable Children'."))

	notify_property_list_changed()


## Llamar a esto durante el juego (no en editor) para crear un nuevo target
## en una posición aleatoria dentro de SpawnRegion. Pensado para usarse
## cuando un target existente es destruido, así siempre queda la misma
## cantidad de targets activos.
## Se llama típicamente desde la señal target_destroyed, que se emite dentro
## de un callback de física (area_entered) — por eso usamos call_deferred,
## ya que modificar el árbol de nodos en ese momento no está permitido.
func spawn_target_runtime() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_create_target_instance")


## Lógica común: crea la instancia, calcula posición aleatoria dentro de
## SpawnRegion, y la agrega como hija de Game. Devuelve la instancia creada,
## o null si algo faltó (con un push_warning explicando qué).
func _create_target_instance() -> Node2D:
	if target_scene == null:
		push_warning("Target Spawner: asigná primero una escena en 'target_scene'.")
		return null

	var spawn_region := find_child(SPAWN_REGION_NAME, true, false) as Area2D
	if spawn_region == null:
		push_warning(str("Target Spawner: no se encontró un Area2D llamado '", SPAWN_REGION_NAME, "' dentro de Game."))
		return null

	var rect = _get_region_rect(spawn_region)
	if rect == null:
		push_warning("Target Spawner: 'SpawnRegion' necesita un CollisionShape2D con RectangleShape2D.")
		return null

	var instance:Node2D = target_scene.instantiate()
	if instance == null:
		push_warning("Target Spawner: la escena asignada no pudo instanciarse.")
		return null

	var spawn_pos := Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)

	add_child(instance)
	instance.global_position = spawn_pos

	# Si estamos jugando (no en editor), nos conectamos a la señal del target
	# para poder crear un reemplazo automáticamente cuando lo destruyan.
	if not Engine.is_editor_hint() and instance.has_signal("target_destroyed"):
		instance.target_destroyed.connect(spawn_target_runtime)

	return instance


## Devuelve el Rect2 global de la región definida por el RectangleShape2D
## del primer CollisionShape2D hijo del Area2D. Devuelve null si no existe.
func _get_region_rect(area:Area2D) -> Variant:
	var collision_shape:CollisionShape2D = null
	for child in area.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break

	if collision_shape == null or collision_shape.shape == null:
		return null

	var shape := collision_shape.shape
	if not (shape is RectangleShape2D):
		return null

	var rect_shape:RectangleShape2D = shape
	var half_size := rect_shape.size * 0.5
	var global_pos := collision_shape.global_position

	return Rect2(global_pos - half_size, rect_shape.size)


## Asigna el owner a un nodo y a todos sus descendientes, para que la
## instancia completa (incluidos sus hijos internos) se guarde con la escena.
func _set_owner_recursive(node:Node, new_owner:Node) -> void:
	if node != new_owner:
		node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Los targets colocados a mano en el editor (con el botón "Agregar Target")
	# ya existen al arrancar el juego, así que los conectamos acá para que
	# también disparen un respawn cuando los destruyan.
	for child in get_children():
		if child.has_signal("target_destroyed"):
			child.target_destroyed.connect(spawn_target_runtime)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
