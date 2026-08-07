extends Node2D

@onready var player_1: Character = $Character
@onready var player_2: Character = $Character2
@onready var hud: HUD = $HUD

var muertes_jugadores: Dictionary = {}
var partida_finalizada: bool = false

func _ready() -> void:
	# Nos aseguramos de que el juego NO inicie pausado
	get_tree().paused = false
	
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
			mensaje = "¡Gana el Jugador 2!"
		else:
			mensaje = "¡Gana el Jugador 1!"
		
		finalizar_escena(mensaje)

func finalizar_escena(mensaje_ganador: String) -> void:
	# Esperamos 1 segundo con el juego normal para que transcurra el evento de la muerte
	await get_tree().create_timer(0.5).timeout
	
	# Mostramos la pantalla de Game Over
	hud.mostrar_game_over(mensaje_ganador)
	
	# Pausamos la partida
	get_tree().paused = true
	
	# Esperamos 2.5 segundos (ignora la pausa)
	await get_tree().create_timer(2.5, true).timeout
	
	# Quitamos la pausa y reiniciamos la escena
	get_tree().paused = false
	get_tree().reload_current_scene()
