extends Node2D

@onready var player_1: Character = $Character
@onready var player_2_humano: Character = $Character2
@onready var player_2_ia: Character = $Character2_CPU
@onready var hud: HUD = $HUD

@export_file("*.tscn") var main_menu_path: String = "res://main_menu.tscn"

# Referencia dinámica al Jugador 2 activo
var player_2: Character = null

var muertes_jugadores: Dictionary = {}
var partida_finalizada: bool = false

func _ready() -> void:
	get_tree().paused = false
	
	# Determinamos cuál nodo de P2 mantener y cuál eliminar
	if Globals.is_vs_ai:
		player_2 = player_2_ia
		player_2_humano.queue_free()
	else:
		player_2 = player_2_humano
		player_2_ia.queue_free()
	
	# Cargamos los colores seleccionados
	player_1.set_sprite(Globals.player_1_color)
	player_2.set_sprite(Globals.player_2_color)
	
	hud.inicializar_partida(player_1, player_2)
	
	muertes_jugadores[player_1] = 0
	muertes_jugadores[player_2] = 0
	
	player_1.muerto.connect(_on_jugador_muerto.bind(player_1))
	player_2.muerto.connect(_on_jugador_muerto.bind(player_2))

func _on_jugador_muerto(jugador: Character) -> void:
	if partida_finalizada:
		return
		
	muertes_jugadores[jugador] += 1
	
	if muertes_jugadores[jugador] >= 3:
		partida_finalizada = true
		
		var mensaje: String = ""
		if jugador == player_1:
			mensaje = "Player 2 wins!"
		else:
			mensaje = "Player 1 wins!"
		
		finalizar_escena(mensaje)

func finalizar_escena(mensaje_ganador: String) -> void:
	await get_tree().create_timer(0.5).timeout
	
	hud.mostrar_game_over(mensaje_ganador)
	get_tree().paused = true
	
	await get_tree().create_timer(2.5, true).timeout
	
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_path)
