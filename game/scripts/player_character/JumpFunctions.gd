# JumpFunctions.gd
extends Node
class_name JumpFunctions

static func procesar_salto(player: CharacterBody2D, is_pressing: bool, timer: Timer, jump_force: float) -> bool:
	# Creamos una variable para registrar si se realiza un salto sin romper el flujo
	var salto_ejecutado = false

	# --- RESET AL TOCAR SUELO ---
	if player.grounded:
		player.saltos_realizados = 0
		player.is_fast_falling = false 

	# --- LÓGICA DE SALTO (Detección de flanco ascendente manual) ---
	var just_pressed = is_pressing and not player.saltando_pressed
	
	if just_pressed:
		# Caso A: Salto desde el suelo
		if player.grounded and not player.is_attacking:
			iniciar_salto(player, timer, jump_force)
			player.saltos_realizados = 1
			salto_ejecutado = true # Registramos el éxito, pero NO frenamos la función
			
		# Caso B: Salto en el aire (Doble Salto)
		elif player.saltos_realizados < 2 and not player.is_attacking:
			iniciar_salto(player, timer, jump_force * 0.85) 
			player.saltos_realizados = 2
			player.is_fast_falling = false
			salto_ejecutado = true # Registramos el éxito, pero NO frenamos la función

	# --- INTERRUPCIÓN (Salto Variable) ---
	# Esta parte SIEMPRE se ejecutará ahora, garantizando el comportamiento original
	if not is_pressing and player.saltando_pressed:
		interrumpir_salto(player, timer)

	# --- FAST FALL ---
	if not player.grounded and player.velocity.y > 0 and player.is_fast_falling == false:
		pass
		
	# Devolvemos el resultado al final del todo, tras haber procesado todo el script
	return salto_ejecutado

static func iniciar_salto(player: CharacterBody2D, timer: Timer, jump_force: float) -> bool:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "jump")
	timer.start()
	player.velocity.y = -jump_force
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
	#player.velocity.y += 300.0 
	#print("Fast Fall activado")
	
static func cancelar_fast_fall(player: CharacterBody2D) -> void:
	player.is_fast_falling = false
	#player.velocity.y += -300.0
	#print("Fast Fall desactivado")
	
static func aplicar_gravedad(player: CharacterBody2D, delta: float, gravity: float) -> void:
	if not player.grounded:
		var mult_gravedad = Globals.GRAVITY_MULT
		var max_caida = Globals.MAX_FALL_SPEED
		
		if player.is_fast_falling:
			mult_gravedad = Globals.GRAVITY_MULT_FASTFALL
			max_caida = Globals.MAX_FALL_SPEED_FASTFALL
			
		player.velocity.y += gravity * mult_gravedad * delta
		player.velocity.y = min(player.velocity.y, max_caida)
