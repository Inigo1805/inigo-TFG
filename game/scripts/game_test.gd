extends Node2D

@onready var player_1: Character = $Character
@onready var player_2_humano: Character = $Character2
@onready var player_2_ia: Character = $Character2_IA

@onready var hud: HUD = $HUD
@onready var camera: CameraBrawler = $Camera2D

@onready var start_timer: Timer = $StartTimer
@onready var countdown_label: Label = $CanvasLayer/CountdownLabel
@onready var music: AudioStreamPlayer = $"Music/Music1-BattleArcade"

@export_file("*.tscn") var main_menu_path: String = "res://main_menu.tscn"

var player_2: Character = null
var muertes_jugadores: Dictionary = {}
var partida_finalizada: bool = false
var partida_iniciada: bool = false

func _ready() -> void:
	get_tree().paused = false
	
	# Determinamos cuál nodo de P2 mantener
	if Globals.is_vs_ai:
		player_2 = player_2_ia
		player_2_humano.queue_free()
	else:
		player_2 = player_2_humano
		player_2_ia.queue_free()
	
	player_1.set_sprite(Globals.player_1_color)
	player_2.set_sprite(Globals.player_2_color)
	
	hud.inicializar_partida(player_1, player_2)
	camera.asignar_objetivos(player_1, player_2)
	
	muertes_jugadores[player_1] = 0
	muertes_jugadores[player_2] = 0
	
	player_1.muerto.connect(_on_jugador_muerto.bind(player_1))
	player_2.muerto.connect(_on_jugador_muerto.bind(player_2))
	
	# --- Congelar personajes al inicio sin pausar el árbol ---
	_toggle_movimiento_personajes(false)
	
	start_timer.timeout.connect(_on_start_timer_timeout)
	start_timer.start()

func _process(_delta: float) -> void:
	#print("FPS: %s" % [Engine.get_frames_per_second()])
	# Como el árbol NO está pausado, esto se ejecutará perfectamente cada frame
	if not partida_iniciada and not start_timer.is_stopped():
		var segundos = ceil(start_timer.time_left)
		if segundos > 1:
			countdown_label.text = str(segundos - 1)
		else:
			countdown_label.text = "FIGHT!"
	else:
		countdown_label.text = ""

func _on_start_timer_timeout() -> void:
	partida_iniciada = true
	_toggle_movimiento_personajes(true)
	music.play()
	# Damos un pequeño respiro para que se vea el "FIGHT!" y borramos el texto
	await get_tree().create_timer(0.6).timeout
	countdown_label.text = ""

func _toggle_movimiento_personajes(activar: bool) -> void:
	# Apagamos/encendemos las físicas y la IA de ambos combatientes
	player_1.set_physics_process(activar)
	player_2.set_physics_process(activar)

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
