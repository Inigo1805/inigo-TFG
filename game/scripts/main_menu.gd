extends Control

# Cambiamos la ruta para que apunte a la escena de selección de personajes
@export_file("*.tscn") var character_select_path: String = "res://escenas/character_select.tscn"

@export var parallax_strength: float = 40.0
@export var lerp_speed: float = 5.0

@onready var fondo: Node2D = $Fondo

# Referencias a los botones de modo de juego y salida
@onready var vs_player_button: Button = $VBoxContainer/VersusPlayerButton
@onready var vs_ai_button: Button = $VBoxContainer/VersusAIButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var controles: TextureRect = $Controles
@onready var showing_controls: bool = false

func _ready() -> void:
	get_tree().paused = false
	controles.hide()
	
	# Conectamos las señales de los botones
	vs_player_button.pressed.connect(_on_vs_player_button_pressed)
	vs_ai_button.pressed.connect(_on_vs_ai_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	vs_player_button.grab_focus()
	
	$Fondo/Fondo_2/Estrellas.play()
	$Fondo/Fondo_1/Planetas.play()

func _process(delta: float) -> void:
	_actualizar_paralaje_fondo(delta)

func _actualizar_paralaje_fondo(delta: float) -> void:
	if not fondo:
		return
		
	var viewport_size = get_viewport_rect().size
	if viewport_size.x > 0 and viewport_size.y > 0:
		var mouse_pos = get_viewport().get_mouse_position()
		var center = viewport_size / 2.0
		
		# Normalizamos la posición del ratón entre -1.0 y 1.0 desde el centro
		var offset = (mouse_pos - center) / center
		var target_offset = -offset * parallax_strength
		
		# Recorremos cada capa Parallax2D hija de Fondo
		for layer in fondo.get_children():
			if layer is Parallax2D:
				var layer_target = target_offset * layer.scroll_scale
				layer.scroll_offset = layer.scroll_offset.lerp(layer_target, lerp_speed * delta)

# Modos de juego
func _on_vs_player_button_pressed() -> void:
	Globals.is_vs_ai = false
	get_tree().change_scene_to_file(character_select_path)

func _on_vs_ai_button_pressed() -> void:
	Globals.is_vs_ai = true
	get_tree().change_scene_to_file(character_select_path)

func _on_exit_button_pressed() -> void:
	get_tree().quit()

signal any_key_pressed

func _unhandled_input(event: InputEvent) -> void:
	# Si la pantalla de controles está activa y se detecta una pulsación (teclado, ratón o mando)
	if showing_controls and event.is_pressed() and not event.is_echo():
		any_key_pressed.emit()
		get_viewport().set_input_as_handled() # Consume el evento para que no interactúe con el menú

func _on_controls_button_pressed() -> void:
	if not showing_controls:
		showing_controls = true
		controles.show()
		
		# Esperamos un fotograma/pequeña pausa para evitar que el mismo clic que abrió el menú lo cierre
		await get_tree().create_timer(0.1).timeout
		
		# Espera a que se emita la señal al pulsar cualquier tecla/botón
		await any_key_pressed
		
		controles.hide()
		showing_controls = false
