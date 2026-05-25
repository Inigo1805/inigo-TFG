# En tu script del Gestor de la Partida / Escena Principal
extends Node2D

@onready var player_1: Character = $Character
@onready var player_2: Character = $Character2
@onready var hud: HUD = $HUD # O instanciada por código

func _ready() -> void:
	# Pasamos las referencias de los personajes a la HUD para que se conecte a sus señales
	hud.inicializar_partida(player_1, player_2)
