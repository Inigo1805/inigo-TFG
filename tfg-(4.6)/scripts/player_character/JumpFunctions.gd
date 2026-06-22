# JumpFunctions.gd
extends Node
class_name JumpFunctions

static func procesar_salto(player: Character, is_pressing: bool, timer: Timer, jump_force: Vector2) -> bool:
	# Creamos una variable para registrar si se realiza un salto sin romper el flujo
	var salto_ejecutado = false

	# --- RESET AL TOCAR SUELO ---
	if player.grounded:
		player.saltos_realizados = 0
		player.is_fast_falling = false 

	# --- LÓGICA DE SALTO (Detección de flanco ascendente manual) ---
	var just_pressed = is_pressing and not player.saltando_pressed
	
	if just_pressed:
		if player.is_on_wall_only() and not player.is_attacking:
			# Obtenemos la dirección perpendicular a la pared (1.0 o -1.0)
			var direccion_muro: Vector2 = player.get_wall_normal()
			
			# Creamos un vector diagonal: 
			# En X: Empuja con fuerza en dirección opuesta al muro
			# En Y: Sube con la fuerza vertical normal del salto
			var fuerza_wall_jump = Vector2(direccion_muro.x * jump_force.y, jump_force.y)
			
			iniciar_salto(player, timer, fuerza_wall_jump)
			
			# Opcional: El wall jump suele resetear el doble salto para poder encadenarlos
			player.saltos_realizados = 1
			player.hizo_wall_jump = true
			salto_ejecutado = true
			#print("Wall Jump hacia: ", "DERECHA" if direccion_muro.x > 0 else "IZQUIERDA")
		
		# Caso A: Salto desde el suelo
		elif player.grounded and not player.is_attacking:
			iniciar_salto(player, timer, jump_force)
			player.saltos_realizados = 1
			salto_ejecutado = true
			
		# Caso B: Salto en el aire (Doble Salto)
		elif player.saltos_realizados < 2 and not player.is_attacking:
			# Multiplicamos el vector completo por 0.85 para suavizar el doble salto vertical
			iniciar_salto(player, timer, jump_force * 0.85) 
			player.saltos_realizados = 2
			player.is_fast_falling = false
			salto_ejecutado = true

	# --- INTERRUPCIÓN (Salto Variable) ---
	if not is_pressing and player.saltando_pressed:
		interrumpir_salto(player, timer)

	# --- FAST FALL ---
	if not player.grounded and player.velocity.y > 0 and player.is_fast_falling == false:
		pass
		
	return salto_ejecutado

static func iniciar_salto(player: CharacterBody2D, timer: Timer, jump_force: Vector2) -> bool:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "jump")
	timer.start()
	player.velocity.y = -jump_force.y
	
	if jump_force.x != 0:
		player.velocity.x = jump_force.x
		# Bloqueamos el flip visual momentáneamente para que el personaje mire hacia donde salta
		if player.can_flip:
			player.visuals.scale.x = -1 if jump_force.x > 0 else 1
			player.actualizar_direccion_hitboxes()

	player.saltando_pressed = true
	return true

static func interrumpir_salto(player: CharacterBody2D, timer: Timer) -> void:
	player.saltando_pressed = false
	if timer.is_stopped():
		corta_salto(player)

static func corta_salto(player: CharacterBody2D) -> void:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "fall")
	if player.velocity.y < 0:
		player.velocity.y *= 0.15

static func activar_fast_fall(player: CharacterBody2D) -> void:
	player.is_fast_falling = true
	
static func cancelar_fast_fall(player: CharacterBody2D) -> void:
	player.is_fast_falling = false
	
static func aplicar_gravedad(player: CharacterBody2D, delta: float, gravity: float) -> void:
	if not player.grounded:
		var mult_gravedad = Globals.GRAVITY_MULT
		var max_caida = Globals.MAX_FALL_SPEED
		
		if player.is_fast_falling:
			mult_gravedad = Globals.GRAVITY_MULT_FASTFALL
			max_caida = Globals.MAX_FALL_SPEED_FASTFALL
			
		player.velocity.y += gravity * mult_gravedad * delta
		player.velocity.y = min(player.velocity.y, max_caida)
