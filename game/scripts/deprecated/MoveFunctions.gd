# MoveFunctions.gd
extends Node
class_name MoveFunctions

static func aplicar_gravedad(player: CharacterBody2D, delta: float, gravity: float) -> void:
	if not player.grounded:
		var mult_gravedad = 1.0
		var max_caida = 700.0 # Velocidad normal de caída
		
		if player.is_fast_falling:
			mult_gravedad = 2.5 # Cae mucho más rápido
			max_caida = 1300.0   # Límite de velocidad mucho mayor
			
		player.velocity.y += gravity * mult_gravedad * delta
		player.velocity.y = min(player.velocity.y, max_caida)

static func mover_horizontal(player: CharacterBody2D, speed: float, on_air: bool) -> void:
	var input_dir := Input.get_axis("izquierda", "derecha")
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# --- 0. Bloqueo de Movimiento ---
	if player.is_attacking and player.grounded:
		player.velocity.x = move_toward(player.velocity.x, 0, speed * 0.2)
		return

	# --- 1. Lógica de Carrera (Doble Toque) ---
	_gestionar_carrera(player, input_dir, current_time)

	# --- 2. Configuración de Inercia ---
	var target_speed = input_dir * speed
	var accel: float
	
	if on_air:
		# Velocidad máxima en aire (un poco más para compensar la inercia)
		target_speed *= 1.2 
		
		if input_dir != 0:
			# --- CONTROL ACTIVO ---
			# Si el jugador pulsa una dirección, aplicamos una aceleración muy alta.
			# Esto hace que el cambio de dirección sea casi instantáneo.
			accel = speed * 0.8  
		else:
			# --- INERCIA (SLIDE) ---
			# Si el jugador suelta el mando, la fricción es muy baja.
			# El personaje "patina" en el aire.
			accel = speed * 0.01
	else:
		# En el suelo el comportamiento es normal/reactivo
		if player.is_running: target_speed *= 2.0
		accel = speed * 0.2 if input_dir != 0 else speed * 0.3

	# --- 3. Aplicar Movimiento ---
	player.velocity.x = move_toward(player.velocity.x, target_speed, accel)

	# --- 4. Flip del personaje ---
	if player.can_flip and input_dir != 0:
		# Buscamos el nodo que agrupa lo visual
		var visuals = player.get_node("Visuals") 
		if input_dir > 0:
			visuals.scale.x = -1  # Mirar a la derecha (por defecto el personaje mira a la izquierda)
		elif input_dir < 0:
			visuals.scale.x = 1 # Mirar a la izquierda

# Función auxiliar para no ensuciar el código principal
static func _gestionar_carrera(player, input_dir, current_time):
	if Input.is_action_just_pressed("derecha"):
		if current_time - player.last_tap_time_derecha < player.DOUBLE_TAP_DELAY:
			player.is_running = true
		player.last_tap_time_derecha = current_time
	elif Input.is_action_just_pressed("izquierda"):
		if current_time - player.last_tap_time_izquierda < player.DOUBLE_TAP_DELAY:
			player.is_running = true
		player.last_tap_time_izquierda = current_time

	if input_dir != 0:
		player.stop_time = current_time
	else:
		if current_time - player.stop_time > player.RUN_GRACE_PERIOD:
			player.is_running = false
