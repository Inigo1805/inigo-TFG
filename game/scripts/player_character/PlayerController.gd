extends Node

@onready var character: Character = get_parent().get_parent()

var last_tap_time_derecha: float = 0.0
var last_tap_time_izquierda: float = 0.0
const DOUBLE_TAP_DELAY: float = Globals.DOUBLE_TAP_DELAY

func _ready() -> void:
	if self.get_parent().get_parent().is_in_group("IA"): 
		set_process_unhandled_input(false)
		set_physics_process(false)

func _physics_process(_delta: float) -> void:
	var in_x = Input.get_axis("izquierda", "derecha")
	character.set_horizontal_input(in_x)
	character.set_jump_input(Input.is_action_pressed("salto"))
	character.set_fast_fall_input(Input.is_action_pressed("abajo"))
	_procesar_logica_correr(in_x)

func _unhandled_input(event: InputEvent) -> void:
	var in_x = Input.get_axis("izquierda", "derecha")
	var in_y = Input.get_axis("arriba", "abajo")
	
	if event.is_action_pressed("attack_a"):
		_decidir_ataque_a(in_x, in_y)
	elif event.is_action_pressed("attack_b"):
		_decidir_ataque_b(in_x, in_y)
	elif event.is_action_pressed("bloqueo"):
		character.bloquear()

func _procesar_logica_correr(in_x: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("derecha"):
		if current_time - last_tap_time_derecha < DOUBLE_TAP_DELAY: 
			character.set_running(true)
		last_tap_time_derecha = current_time
	if Input.is_action_just_pressed("izquierda"):
		if current_time - last_tap_time_izquierda < DOUBLE_TAP_DELAY: 
			character.set_running(true)
		last_tap_time_izquierda = current_time
	if in_x == 0: 
		character.set_running(false)

func _decidir_ataque_a(in_x: float, in_y: float) -> void:
	if character.grounded:
		if in_y < -0.5: character.atacar_tilt_up()
		elif in_y > 0.5: character.atacar_tilt_down()
		elif abs(in_x) > 0.5: character.atacar_tilt_side()
		else: character.atacar_jab()
	else:
		_decidir_ataque_aire(in_x, in_y)

func _decidir_ataque_b(in_x: float, in_y: float) -> void:
	if character.grounded:
		if in_y < -0.5: character.atacar_strong_up()
		elif in_y > 0.5: character.atacar_strong_down()
		else: character.atacar_strong_side()
	else:
		_decidir_ataque_aire(in_x, in_y)

func _decidir_ataque_aire(in_x: float, in_y: float) -> void:
	if in_y < -0.5: character.atacar_uair()
	elif in_y > 0.5: character.atacar_dair()
	elif abs(in_x) > 0.5:
		var mirando_derecha = character.visuals.scale.x < 0
		if (in_x > 0 and mirando_derecha) or (in_x < 0 and not mirando_derecha): character.atacar_fair()
		else: character.atacar_bair()
	else: character.atacar_nair()
