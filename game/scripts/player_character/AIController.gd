extends Node

# Referencias
@onready var controlled_character: Character = get_parent().get_parent()
var target: CharacterBody2D = null 

# TODO Configuraciones de comportamiento, hay que mejorar
@export var agresividad: float = 0.8 # Probabilidad de realizar acciones
@export var distancia_ataque: float = 80.0
@export var distancia_correr: float = 300.0

func _ready() -> void:
	# Si este personaje no está marcado como CPU, desactivamos este cerebro
	if not self.get_parent().get_parent().is_in_group("cpu"):
		set_physics_process(false)
		return
	
	# Buscamos al oponente
	target = _buscar_oponente_valido()

func _buscar_oponente_valido() -> CharacterBody2D:
	var todos_los_personajes = get_tree().get_nodes_in_group("character")
	for p in todos_los_personajes:
		if p != controlled_character: # ¡Aquí está la clave! Ignora si es él mismo
			return p
	return null

func _quedarse_quieto() -> void:
	controlled_character.input_x = 0
	controlled_character.input_salto = false
	controlled_character.input_fast_fall = false
	controlled_character.is_running = false

func _physics_process(_delta: float) -> void:
	# Si no hay target, intentamos buscar uno válido
	if not is_instance_valid(target):
		target = _buscar_oponente_valido()
		
	# Si después de buscar seguimos sin target, nos quedamos quietos
	if not target:
		_quedarse_quieto()
		return
	
	var dist_vector = target.global_position - controlled_character.global_position
	var dist_x = dist_vector.x
	var abs_dist_x = abs(dist_x)
	var diff_y = dist_vector.y
	
	# --- LÓGICA DE MOVIMIENTO HORIZONTAL ---
	if abs_dist_x > distancia_ataque:
		controlled_character.input_x = sign(dist_x)
		
		# Decidir si corre o camina escribiendo en la variable de la entidad
		if abs_dist_x > distancia_correr:
			controlled_character.is_running = true
		elif abs_dist_x < 150:
			controlled_character.is_running = false
	else:
		controlled_character.input_x = 0
		controlled_character.is_running = false
		_decidir_ataque(dist_x, diff_y)

	# --- LÓGICA DE SALTO (Contextual) ---
	if controlled_character.grounded:
		if randf() < agresividad:
			if diff_y < -160:
				_presionar_salto_virtual(0.25) # Salto Máximo
			elif diff_y < -60 and abs_dist_x < 200:
				_presionar_salto_virtual(0.08) # Short Hop
			elif abs_dist_x < 150 and controlled_character.is_running:
				_presionar_salto_virtual(0.12) # Salto de aproximación
	
	# --- LÓGICA DE AIRE (Doble Salto y Fast Fall) ---
	if not controlled_character.grounded:
		# Doble salto: Si estamos cayendo y el rival sigue arriba
		if controlled_character.velocity.y > 0 and diff_y < -50:
			if controlled_character.saltos_realizados < 2:
				_presionar_salto_virtual(0.2)
		
		# Fast Fall: Usamos la nueva variable input_fast_fall
		if controlled_character.velocity.y > 0 and diff_y > 150:
			controlled_character.input_fast_fall = true
		else:
			controlled_character.input_fast_fall = false

# Simula la pulsación del botón de salto durante un tiempo determinado
func _presionar_salto_virtual(duracion: float) -> void:
	if controlled_character.input_salto: return # Si ya está saltando
	
	controlled_character.input_salto = true
	await get_tree().create_timer(duracion).timeout
	controlled_character.input_salto = false

func _decidir_ataque(dist_x: float, diff_y: float) -> void:
	# No atacar si ya estamos atacando o en hitstun
	if controlled_character.is_attacking or controlled_character.is_hitstun: return
	
	var abs_x = abs(dist_x)
	
	# Lógica simple de selección de ataques del padre
	if abs(diff_y) < 50:
		if abs_x < 40:
			controlled_character.atacar_jab()
		else:
			controlled_character.atacar_tilt_side()
	elif diff_y < -40 and abs_x < 30:
		controlled_character.atacar_tilt_up()
