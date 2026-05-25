# JumpFunctions.gd
extends Node
class_name JumpFunctions

static func procesar_salto(player: CharacterBody2D, is_pressing: bool, timer: Timer, jump_force: float) -> void:
	# --- RESET AL TOCAR SUELO ---
	if player.grounded:
		player.saltos_realizados = 0
		player.is_fast_falling = false 

	# --- LÓGICA DE SALTO (Detección de flanco ascendente manual) ---
	# Usamos una variable en el player para saber si el botón estaba presionado en el frame anterior
	var just_pressed = is_pressing and not player.saltando_pressed
	
	if just_pressed:
		# Caso A: Salto desde el suelo
		if player.grounded and not player.is_attacking:
			iniciar_salto(player, timer, jump_force)
			player.saltos_realizados = 1
			
		# Caso B: Salto en el aire (Doble Salto)
		elif player.saltos_realizados < 2 and not player.is_attacking:
			iniciar_salto(player, timer, jump_force * 0.85) 
			player.saltos_realizados = 2
			player.is_fast_falling = false

	# --- INTERRUPCIÓN (Salto Variable) ---
	# Si deja de presionar y el salto aún estaba marcado como activo
	if not is_pressing and player.saltando_pressed:
		interrumpir_salto(player, timer)

	# --- FAST FALL ---
	# Para la IA, el fast fall se activará si la velocidad es positiva y se pulsa abajo (lo gestionamos en el script principal)
	# Pero mantenemos la lógica aquí por si acaso
	if not player.grounded and player.velocity.y > 0 and player.is_fast_falling == false:
		# Nota: El Fast Fall suele requerir un input de "abajo". 
		# Si quieres que la IA haga fast fall, deberás setear player.is_fast_falling = true desde su lógica.
		pass

static func iniciar_salto(player: CharacterBody2D, timer: Timer, jump_force: float) -> void:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "jump")
	timer.start()
	player.velocity.y = -jump_force
	player.saltando_pressed = true # Esto ahora significa "botón presionado"

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
	player.velocity.y += 300.0 
	print("Fast Fall activado")
	
static func cancelar_fast_fall(player: CharacterBody2D) -> void:
	player.is_fast_falling = false
	player.velocity.y += -300.0
	print("Fast Fall desactivado")
