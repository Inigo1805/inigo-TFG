extends Node2D

@onready var jump: AudioStreamPlayer2D = $Jump
@onready var land: AudioStreamPlayer2D = $Land
@onready var punch_hit: AudioStreamPlayer2D = $PunchHit
@onready var punch_woosh_1: AudioStreamPlayer2D = $PunchWoosh1
@onready var punch_woosh_2: AudioStreamPlayer2D = $PunchWoosh2

# Variables de exportación para activar los sonidos desde otras funciones
@export var playJump: bool = false
@export var playLand: bool = false
@export var playPunchHit: bool = false
@export var playPunchWoosh1: bool = false
@export var playPunchWoosh2: bool = false

func _process(_delta: float) -> void:
	if playJump:
		jump.play()
		playJump = false
		print("playing: jump")
		
	if playLand:
		playLand = false
		land.play()
		print("playing: land")
		
	if playPunchHit:
		playPunchHit = false
		punch_hit.play()
		print("playing: punch_hit")
		
	if playPunchWoosh1:
		playPunchWoosh1 = false
		punch_woosh_1.play()
		print("playing: punch_woosh_1")
		
	if playPunchWoosh2:
		playPunchWoosh2 = false
		punch_woosh_2.play()
		print("playing: punch_woosh_2")
