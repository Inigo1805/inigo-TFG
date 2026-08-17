extends Control

@export_file("*.tscn") var game_scene_path: String = "res://game_test.tscn"
@export_file("*.tscn") var main_menu_path: String = "res://main_menu.tscn"

@export var parallax_strength: float = 40.0
@export var lerp_speed: float = 5.0

@onready var fondo: Node2D = $Fondo
@onready var title_label: Label = $TitleLabel

@onready var row_1: HBoxContainer = $MainContainer/Row1
@onready var row_2: HBoxContainer = $MainContainer/Row2
@onready var row_3: HBoxContainer = $MainContainer/Row3
@onready var back_button: Button = $MainContainer/Row3/BackButton

@onready var loading_panel: ColorRect = $LoadingPanel
@onready var loading_label: Label = $LoadingPanel/LoadingLabel

var current_player: int = 1
var colors_order: Array[String] = ["dark", "green", "red", "white", "yellow"]
var color_buttons: Dictionary = {}

var is_loading: bool = false
var is_ai_selecting: bool = false
var progress_array: Array = []

func _ready() -> void:
	if loading_panel:
		loading_panel.visible = false
		
	_mapear_y_conectar_botones()
	_configurar_foco_vecinos()
	_actualizar_interfaz()
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	if fondo.has_node("Fondo_2/Estrellas"):
		$Fondo/Fondo_2/Estrellas.play()
	if fondo.has_node("Fondo_1/Planetas"):
		$Fondo/Fondo_1/Planetas.play()

func _process(delta: float) -> void:
	_actualizar_paralaje_fondo(delta)
	_procesar_carga_asincrona()

func _actualizar_paralaje_fondo(delta: float) -> void:
	if not fondo:
		return
		
	var viewport_size = get_viewport_rect().size
	if viewport_size.x > 0 and viewport_size.y > 0:
		var mouse_pos = get_viewport().get_mouse_position()
		var center = viewport_size / 2.0
		
		var offset = (mouse_pos - center) / center
		var target_offset = -offset * parallax_strength
		
		for layer in fondo.get_children():
			if layer is Parallax2D:
				var layer_target = target_offset * layer.scroll_scale
				layer.scroll_offset = layer.scroll_offset.lerp(layer_target, lerp_speed * delta)

func _procesar_carga_asincrona() -> void:
	if not is_loading:
		return
		
	var status = ResourceLoader.load_threaded_get_status(game_scene_path, progress_array)
	
	if progress_array.size() > 0 and loading_label:
		var porcentaje = int(progress_array[0] * 100)
		loading_label.text = "Loading game... %d%%" % porcentaje

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loading = false
		if loading_label:
			loading_label.text = "Loading game... 100%"
		
		await get_tree().create_timer(0.5).timeout
		var packed_scene = ResourceLoader.load_threaded_get(game_scene_path)
		get_tree().change_scene_to_packed(packed_scene)

func _mapear_y_conectar_botones() -> void:
	# Mapeamos SOLAMENTE las filas de personajes (Row1 y Row2)
	var character_buttons: Array[Button] = []
	for child in row_1.get_children():
		if child is Button: character_buttons.append(child)
	for child in row_2.get_children():
		if child is Button: character_buttons.append(child)
	
	for i in range(min(character_buttons.size(), colors_order.size())):
		var btn = character_buttons[i]
		var color_name = colors_order[i]
		color_buttons[color_name] = btn
		btn.pressed.connect(_on_character_selected.bind(color_name))

func _configurar_foco_vecinos() -> void:
	var row1_buttons: Array[Button] = []
	var row2_buttons: Array[Button] = []
	
	for child in row_1.get_children():
		if child is Button: row1_buttons.append(child)
	for child in row_2.get_children():
		if child is Button: row2_buttons.append(child)

	# Conexión vertical entre Row1 y Row2
	for i in range(row1_buttons.size()):
		if i < row2_buttons.size():
			row1_buttons[i].focus_neighbor_bottom = row1_buttons[i].get_path_to(row2_buttons[i])
			row2_buttons[i].focus_neighbor_top = row2_buttons[i].get_path_to(row1_buttons[i])

	# Conexión vertical desde Row2 hacia el BackButton en Row3
	if back_button:
		for btn in row2_buttons:
			btn.focus_neighbor_bottom = btn.get_path_to(back_button)
		# Desde BackButton, al pulsar 'arriba' volvemos al primer botón de Row2
		if row2_buttons.size() > 0:
			back_button.focus_neighbor_top = back_button.get_path_to(row2_buttons[0])

func _on_character_selected(color_name: String) -> void:
	if is_ai_selecting or is_loading:
		return

	if current_player == 1:
		Globals.player_1_color = color_name
		current_player = 2
		_actualizar_interfaz()
		
		if Globals.is_vs_ai:
			_iniciar_seleccion_ia()
			
	elif current_player == 2:
		Globals.player_2_color = color_name
		_iniciar_carga_asincrona()

func _on_back_button_pressed() -> void:
	if is_loading or is_ai_selecting:
		return

	if current_player == 2:
		# Cancelar la elección del Jugador 1 y regresar a su turno
		current_player = 1
		Globals.player_1_color = ""
		_actualizar_interfaz()
	else:
		# Si está en el turno del Jugador 1, regresar al menú principal
		get_tree().change_scene_to_file(main_menu_path)

func _iniciar_seleccion_ia() -> void:
	is_ai_selecting = true
	title_label.text = "IA: Choosing character..."
	title_label.modulate = Color.MAGENTA

	# La IA ignora completamente Row3 / BackButton porque filtra solo sobre colors_order
	var colores_disponibles: Array[String] = []
	for color_name in colors_order:
		if color_name != Globals.player_1_color:
			colores_disponibles.append(color_name)

	var saltos = 10
	var ultimo_btn: Button = null

	for i in range(saltos):
		if ultimo_btn and ultimo_btn != color_buttons[Globals.player_1_color]:
			ultimo_btn.scale = Vector2.ONE
			ultimo_btn.modulate = Color.WHITE

		var color_temp = colores_disponibles.pick_random()
		ultimo_btn = color_buttons[color_temp]

		ultimo_btn.scale = Vector2(1.15, 1.15)
		ultimo_btn.modulate = Color.YELLOW

		await get_tree().create_timer(0.2).timeout

	if ultimo_btn:
		ultimo_btn.scale = Vector2.ONE
		ultimo_btn.modulate = Color.WHITE

	var color_elegido = colores_disponibles.pick_random()
	var btn_elegido: Button = color_buttons[color_elegido]

	btn_elegido.scale = Vector2(1.2, 1.2)
	btn_elegido.modulate = Color.GREEN
	await get_tree().create_timer(0.5).timeout

	Globals.player_2_color = color_elegido
	is_ai_selecting = false
	_iniciar_carga_asincrona()

# Desactiva botones y retira el foco para evitar navegación durante la carga
func _desactivar_interaccion_ui() -> void:
	for button in color_buttons.values():
		if is_instance_valid(button):
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
	
	if back_button:
		back_button.disabled = true
		back_button.focus_mode = Control.FOCUS_NONE


func _iniciar_carga_asincrona() -> void:
	_desactivar_interaccion_ui()
	if loading_panel:
		loading_panel.visible = true
	
	ResourceLoader.load_threaded_request(game_scene_path)
	is_loading = true

func _actualizar_interfaz() -> void:
	if current_player == 1:
		title_label.text = "PLAYER 1: Choose your character"
		title_label.modulate = Color.CYAN
		for btn in color_buttons.values():
			btn.disabled = false
			btn.scale = Vector2.ONE
			btn.modulate = Color.WHITE
		
		if color_buttons.has(colors_order[0]):
			color_buttons[colors_order[0]].grab_focus()

	elif current_player == 2:
		if not Globals.is_vs_ai:
			title_label.text = "PLAYER 2: Choose your character"
			title_label.modulate = Color.ORANGE
		
		if color_buttons.has(Globals.player_1_color):
			var selected_btn: Button = color_buttons[Globals.player_1_color]
			selected_btn.disabled = true
			selected_btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		
		if not Globals.is_vs_ai:
			for color_name in colors_order:
				if color_name != Globals.player_1_color and color_buttons.has(color_name):
					color_buttons[color_name].grab_focus()
					break
