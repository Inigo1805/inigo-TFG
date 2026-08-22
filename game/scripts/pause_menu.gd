extends Control

var pauseMenuShows = false
var showing_controls = false
@export_file("*.tscn") var main_menu_path: String = "res://escenas/main_menu.tscn"

# Referencias basadas exactamente en tu jerarquía de nodos
@onready var resume_button: Button = $PanelContainer/ColorRect/VBoxContainer/ResumeButton
@onready var controls_button: Button = $PanelContainer/ColorRect/VBoxContainer/ControlsButton
@onready var quit_button: Button = $PanelContainer/ColorRect/VBoxContainer/QuitButton
@onready var panel_container: Control = $PanelContainer
@onready var controles_panel: Control = $Controles # Apunta a tu nodo "Controles"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Fundamental para que responda con el juego pausado
	$AnimationPlayer.play("RESET")
	_configurar_foco_vecinos()
	if controles_panel:
		controles_panel.hide()

func _process(_delta: float) -> void:
	listener()

func _configurar_foco_vecinos() -> void:
	if resume_button and controls_button and quit_button:
		resume_button.focus_neighbor_bottom = resume_button.get_path_to(controls_button)
		controls_button.focus_neighbor_top = controls_button.get_path_to(resume_button)
		controls_button.focus_neighbor_bottom = controls_button.get_path_to(quit_button)
		quit_button.focus_neighbor_top = quit_button.get_path_to(controls_button)

# Pausa el juego y muestra el menú
func pause() -> void:
	pauseMenuShows = true
	showing_controls = false
	if controles_panel:
		controles_panel.hide()
	if panel_container:
		panel_container.show()
		
	$AnimationPlayer.play("fade_in")
	$SFX/pause_sfx.play()
	get_tree().paused = true
	
	if resume_button:
		resume_button.grab_focus()

# Despausa el juego y oculta el menú
func resume() -> void:
	pauseMenuShows = false
	showing_controls = false
	if controles_panel:
		controles_panel.hide()
	get_tree().paused = false
	$AnimationPlayer.play_backwards("fade_in")

func listener() -> void:
	if Input.is_action_just_pressed("pause"):
		if showing_controls:
			# Si estamos viendo los controles, al pulsar pausa volvemos al menú normal
			showing_controls = false
			if controles_panel: controles_panel.hide()
			if panel_container: panel_container.show()
			if resume_button: resume_button.grab_focus()
		else:
			if not pauseMenuShows:
				pause()
			else:
				resume()

# Detecta cualquier clic, tecla o botón de mando para cerrar los controles
func _unhandled_input(event: InputEvent) -> void:
	if pauseMenuShows and showing_controls and event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		showing_controls = false
		if controles_panel:
			controles_panel.hide()
		if panel_container:
			panel_container.show()
		if resume_button:
			resume_button.grab_focus()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	if pauseMenuShows and not showing_controls:
		$SFX/resume_sfx.play()
		resume()

# Conecta la señal "pressed" de tu ControlsButton a esta función
func _on_controls_button_pressed() -> void:
	if pauseMenuShows and not showing_controls:
		showing_controls = true
		if panel_container:
			panel_container.hide() # Oculta los botones de pausa
		if controles_panel:
			controles_panel.show() # Muestra tu imagen de controles

func _on_quit_pressed() -> void:
	if pauseMenuShows and not showing_controls:
		get_tree().change_scene_to_file(main_menu_path)
