# JumpFunctions.gd
extends Node
class_name JumpFunctions

static func procesar_salto(player: CharacterBody2D, jump_action: String, timer: Timer, jump_force: float) -> void:
	if Input.is_action_pressed(jump_action) and player.ground_check.is_colliding():
		iniciar_salto(player, timer, jump_force)
	if not Input.is_action_pressed(jump_action) and player.saltando:
		interrumpir_salto(player, timer)

static func iniciar_salto(player: CharacterBody2D, timer: Timer, jump_force: float) -> void:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "jump")
	timer.start()
	player.velocity.y = -jump_force
	player.saltando = true

static func interrumpir_salto(player: CharacterBody2D, timer: Timer) -> void:
	player.saltando = false
	if timer.is_stopped():
		corta_salto(player)

static func corta_salto(player: CharacterBody2D) -> void:
	AnimationFunctions.change_movimiento_state(player.movimiento_playback, player.idle_playback, "fall")
	if player.velocity.y < 0:
		player.velocity.y *= 0.15
