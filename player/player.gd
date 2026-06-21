@tool
@icon("res://icons/tank_icon.tres")
extends Node2D
class_name Player

@export var bullet_scene:PackedScene

## Magnitud máxima de la velocidad de disparo (reemplaza al Vector2 shot_velocity).
@export var shot_speed:float = 800.0
@export var shot_gravity:Vector2 = Vector2(0, 980)

@export_range(0,100) var max_shots:int = 3 :
	set(value):
		max_shots = value
		queue_redraw()

## Ángulo mínimo y máximo que el jugador puede seleccionar, en grados.
@export var min_angle_deg:float = 0.0
@export var max_angle_deg:float = 45.0

## Velocidad a la que cambia el ángulo mientras se mantiene presionada la flecha, en grados/segundo.
@export var angle_change_speed:float = 60.0

## Ángulo de disparo actualmente seleccionado por el jugador, en grados.
@export_range(0.0, 45.0) var current_angle_deg:float = 0.0 :
	set(value):
		current_angle_deg = clamp(value, min_angle_deg, max_angle_deg)
		queue_redraw()

## Cuántos puntos calculamos para dibujar la curva de trayectoria.
@export_range(2, 100) var trajectory_points:int = 40
## Cuánto tiempo (en segundos) de vuelo dibujamos para cada trayectoria.
@export var trajectory_time:float = 2.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Subir/bajar el ángulo mientras se mantiene presionada la flecha correspondiente.
	if Input.is_action_pressed(&"ui_up"):
		current_angle_deg += angle_change_speed * delta
	if Input.is_action_pressed(&"ui_down"):
		current_angle_deg -= angle_change_speed * delta

	if Input.is_action_just_pressed(&"Shoot"):
		var bullet:Bullet = bullet_scene.instantiate()
		bullet.shot_gravity = shot_gravity
		bullet.shot_velocity = _get_velocity_for_angle(current_angle_deg)
		bullet.position = %CannonPivot.global_position

		var container_node = self
		if has_node("%BulletContainer"):
			container_node = %BulletContainer
		container_node.add_child(bullet)


## Convierte un ángulo en grados (0 = derecha, 45 = arriba-derecha) en un
## Vector2 de velocidad con magnitud shot_speed.
## En Godot el eje Y crece hacia abajo, así que restamos el ángulo para que
## "positivo" suba en pantalla.
func _get_velocity_for_angle(angle_deg:float) -> Vector2:
	var rad := deg_to_rad(angle_deg)
	return Vector2(cos(rad), -sin(rad)) * shot_speed


## Calcula los puntos de la trayectoria curva (con gravedad) para un ángulo dado,
## en coordenadas locales del Player, empezando desde origin_local.
func _get_trajectory_points(angle_deg:float, origin_local:Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var velocity := _get_velocity_for_angle(angle_deg)
	var pos := origin_local
	var dt := trajectory_time / float(trajectory_points)

	points.append(pos)
	for i in range(trajectory_points):
		velocity += shot_gravity * dt
		pos += velocity * dt
		points.append(pos)

	return points


func _draw() -> void:
	# Punto de origen: usamos el pivote del cañón si existe, si no, el origen local.
	var origin_local := Vector2.ZERO
	if has_node("%CannonPivot"):
		origin_local = %CannonPivot.position

	# Curvas límite (referencia tenue), para que se vea el rango disponible.
	var limit_color := Color(1, 1, 1, 0.35)
	for limit_angle in [min_angle_deg, max_angle_deg]:
		var limit_pts := _get_trajectory_points(limit_angle, origin_local)
		draw_polyline(limit_pts, limit_color, 1.0)
		draw_string(ThemeDB.get_default_theme().default_font,
					limit_pts[limit_pts.size() - 1] + Vector2(4, 0),
					str(snapped(limit_angle, 0.1), "°"),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, limit_color)

	# Curva del ángulo actual (destacada).
	var pts := _get_trajectory_points(current_angle_deg, origin_local)
	draw_polyline(pts, Color.YELLOW, 2.0)
	draw_string(ThemeDB.get_default_theme().default_font,
				pts[pts.size() - 1] + Vector2(4, 0),
				str(snapped(current_angle_deg, 0.1), "°"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)

	if Engine.is_editor_hint():
		draw_string(ThemeDB.get_default_theme().default_font,Vector2(-40,20),
					str("max shots: ",max_shots),HORIZONTAL_ALIGNMENT_LEFT)
