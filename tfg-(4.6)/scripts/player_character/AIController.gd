# =====================================================================
# IAControler.gd (REESTRUCTURADO CON CONTEXTO GEOGRÁFICO)
# =====================================================================
extends Node

@onready var controlled_character: Character = get_parent().get_parent()
var target: CharacterBody2D = null 

@export var agresividad: float = 0.8
@export var distancia_ataque: float = 80.0
@export var distancia_correr: float = 300.0

func _ready() -> void:
	if not self.get_parent().get_parent().is_in_group("cpu"):
		set_physics_process(false)
		return
	target = _buscar_oponente_valido()

func _buscar_oponente_valido() -> CharacterBody2D:
	var todos_los_personajes = get_tree().get_nodes_in_group("character")
	for p in todos_los_personajes:
		if p != controlled_character:
			return p
	return null

func _quedarse_quieto() -> void:
	controlled_character.input_x = 0
	controlled_character.input_salto = false
	controlled_character.input_fast_fall = false
	controlled_character.is_running = false

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = _buscar_oponente_valido()
		
	if not target:
		_quedarse_quieto()
		return
	
	var dist_vector = target.global_position - controlled_character.global_position
	var dist_x = dist_vector.x
	var abs_dist_x = abs(dist_x)
	var diff_y = dist_vector.y
	
	# =====================================================================
	# REACCIÓN BASADA EN GEOGRAFÍA (Prioridad sobre persecución estándar)
	# =====================================================================
	match controlled_character.zona_actual:
		
		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_DANGER:
			# ¡ALERTA MÁXIMA! Fuera de rango de salvación simple.
			# Forzamos regreso al centro (0.0) y gastamos dobles saltos desesperadamente.
			var direccion_a_salvo = -sign(controlled_character.global_position.x)
			controlled_character.input_x = direccion_a_salvo if direccion_a_salvo != 0 else 1.0
			controlled_character.is_running = true
			
			if controlled_character.velocity.y > 0 and controlled_character.saltos_realizados < 2:
				_presionar_salto_virtual(0.2)
			return

		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_SAFE:
			# VACÍO SEGURO: El bot sabe que el borde está ahí mismo.
			# Dirige su movimiento hacia el escenario para aterrizar, 
			# pero NO malgasta su doble salto todavía. Puede flotar de vuelta de forma eficiente.
			var direccion_a_salvo = -sign(controlled_character.global_position.x)
			controlled_character.input_x = direccion_a_salvo if direccion_a_salvo != 0 else 1.0
			controlled_character.is_running = false # No necesita correr descontrolado
			
			# Opcional: Si el rival está también cerca del borde, ¡incluso podría intentar un ataque aéreo!
			if abs_dist_x < distancia_ataque:
				_decidir_ataque(dist_x, diff_y)
				
		controlled_character.ZonaEscenario.AIR_NEAR_WALL:
			_presionar_salto_virtual(0.15)
			return
			
		controlled_character.ZonaEscenario.AIR_ABOVE_PLATFORM:
			# Lógica de persecución aérea estándar
			controlled_character.input_x = sign(dist_x)
			controlled_character.is_running = (abs_dist_x > distancia_correr)
			
			if controlled_character.velocity.y > 0 and diff_y < -50:
				if controlled_character.saltos_realizados < 2:
					_presionar_salto_virtual(0.2)
					
			if controlled_character.velocity.y > 0 and diff_y > 150:
				controlled_character.input_fast_fall = true
			else:
				controlled_character.input_fast_fall = false
				
			# Permite tirar ataques aéreos si está cerca
			if abs_dist_x < distancia_ataque:
				_decidir_ataque(dist_x, diff_y)

		controlled_character.ZonaEscenario.ON_PLATFORM:
			# Lógica clásica en suelo que ya tenías programada
			controlled_character.input_fast_fall = false
			
			if abs_dist_x > distancia_ataque:
				controlled_character.input_x = sign(dist_x)
				if abs_dist_x > distancia_correr:
					controlled_character.is_running = true
				elif abs_dist_x < 150:
					controlled_character.is_running = false
			else:
				controlled_character.input_x = 0
				controlled_character.is_running = false
				_decidir_ataque(dist_x, diff_y)

			# Saltos condicionales en el suelo
			if randf() < agresividad:
				if diff_y < -160:
					_presionar_salto_virtual(0.25)
				elif diff_y < -60 and abs_dist_x < 200:
					_presionar_salto_virtual(0.08)
				elif abs_dist_x < 150 and controlled_character.is_running:
					_presionar_salto_virtual(0.12)

# ... (Mantén tus funciones _presionar_salto_virtual y _decidir_ataque intactas) ...

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
