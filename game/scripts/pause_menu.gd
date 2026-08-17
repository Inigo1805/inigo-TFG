extends Control

var pauseMenuShows = false
@export_file("*.tscn") var main_menu_path: String = "res://main_menu.tscn"

# Referencias a los botones principales para la gestión del foco
@onready var resume_button: Button = $PanelContainer/ColorRect/VBoxContainer/ResumeButton
@onready var quit_button: Button =  $PanelContainer/ColorRect/VBoxContainer/QuitButton

func _ready() -> void:
	$AnimationPlayer.play("RESET")
	_configurar_foco_vecinos()

func _process(_delta: float) -> void:
	listener()

func _configurar_foco_vecinos() -> void:
	if resume_button and quit_button:
		resume_button.focus_neighbor_bottom = resume_button.get_path_to(quit_button)
		quit_button.focus_neighbor_top = quit_button.get_path_to(resume_button)

# Pausa el juego y muestra el menú
func pause() -> void:
	pauseMenuShows = true
	$AnimationPlayer.play("fade_in")
	$SFX/pause_sfx.play()
	get_tree().paused = true
	
	# Asignamos el foco al primer botón para permitir la navegación con mando inmediatamente
	if resume_button:
		resume_button.grab_focus()

# Despausa el juego y oculta el menú
func resume() -> void:
	pauseMenuShows = false
	get_tree().paused = false
	$AnimationPlayer.play_backwards("fade_in")

func listener() -> void:
	if Input.is_action_just_pressed("pause"):
		if not pauseMenuShows:
			pause()
		else:
			resume()

func _on_resume_pressed() -> void:
	if pauseMenuShows:
		$SFX/resume_sfx.play()
		resume()

func _on_quit_pressed() -> void:
	if pauseMenuShows:
		get_tree().change_scene_to_file(main_menu_path)
