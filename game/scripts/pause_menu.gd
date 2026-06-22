extends Control

var pauseMenuShows = false

func _ready() -> void:
	$AnimationPlayer.play("RESET")

func _process(_delta: float) -> void:
	listener()

# Despausa el juego y oculta el menú
func resume():
	pauseMenuShows = false
	get_tree().paused = false # 1. QUITAMOS LA PAUSA DEL JUEGO
	$AnimationPlayer.play_backwards("blur")

# Pausa el juego y muestra el menú
func pause():
	pauseMenuShows = true
	$AnimationPlayer.play("blur")
	$SFX/pause_sfx.play()
	get_tree().paused = true  # 2. PAUSAMOS EL JUEGO REALMENTE

func listener():
	# Si pulsas la tecla de pausa...
	if Input.is_action_just_pressed("pause"):
		if !pauseMenuShows:
			pause()
		else:
			resume()

func _on_resume_pressed() -> void:
	if pauseMenuShows:
		$SFX/resume_sfx.play()
		resume()

func _on_quit_pressed() -> void:
	if pauseMenuShows:
		get_tree().quit()
		
func _on_save_pressed() -> void:
	pass #TODO aquí se pueden hacer cosas
