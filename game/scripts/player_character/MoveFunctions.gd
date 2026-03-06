# MoveFunctions.gd
extends Node
class_name MoveFunctions

static func aplicar_gravedad(player: CharacterBody2D, delta: float, gravity: float) -> void:
	if player.ground_check.is_colliding():
		player.velocity.y = 0
	else:
		player.velocity.y += gravity * delta

static func mover_horizontal(player: CharacterBody2D, speed: float, on_air: bool) -> void:
	var input_dir := Input.get_axis("izquierda", "derecha")
	var current_time = Time.get_ticks_msec() / 1000.0
	var current_speed = speed

	# 1. Detección de Doble Toque para INICIAR carrera
	if Input.is_action_just_pressed("derecha"):
		if current_time - player.last_tap_time_derecha < player.DOUBLE_TAP_DELAY:
			player.is_running = true
		player.last_tap_time_derecha = current_time
		
	elif Input.is_action_just_pressed("izquierda"):
		if current_time - player.last_tap_time_izquierda < player.DOUBLE_TAP_DELAY:
			player.is_running = true
		player.last_tap_time_izquierda = current_time

	# 2. Lógica de Mantenimiento de Carrera (El "Buffer")
	if input_dir != 0:
		# Si nos estamos moviendo, reseteamos el cronómetro de parada
		player.stop_time = current_time
	else:
		# Si no hay input, verificamos si ha pasado el tiempo de gracia
		if current_time - player.stop_time > player.RUN_GRACE_PERIOD:
			player.is_running = false

	# 3. Aplicar Velocidad
	if player.is_running: # Corriendo es el doble
		current_speed = speed * 2
	if on_air: # En el aire (corriendo o no) es un 150%
		current_speed = speed * 1.5

	player.velocity.x = input_dir * current_speed

	# 4. Flip del Sprite (solo si hay movimiento para no resetear el look_at)
	if input_dir < 0:
		player.sprite.flip_h = false
	elif input_dir > 0:
		player.sprite.flip_h = true
