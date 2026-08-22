extends Node

@onready var controlled_character: Character = get_parent().get_parent()
var target: Character = null

@export_group("Configuración IA")
@export var agresividad: float = 0.85
@export var distancia_ataque: float = 85.0
@export var distancia_correr: float = 280.0
@export var umbral_porcentaje_kill: float = 60.0

@export_group("Simulación Humana")
@export var reaccion_min: float = 0.10
@export var reaccion_max: float = 0.18

@export_group("Gestión de Vidas y Psicología")
@export var vidas_iniciales: int = 3
@export var agresividad_base: float = 0.85

const DEBUG_INTERVALO: float = 0.5

const PSICOLOGIA_MULT_VENTAJA: float = 1.25
const PSICOLOGIA_MULT_DESVENTAJA: float = 0.65
const AGRESIVIDAD_MIN_VENTAJA: float = 0.5
const AGRESIVIDAD_MIN_DESVENTAJA: float = 0.2
const AGRESIVIDAD_MAX_DESVENTAJA: float = 0.8
const AGRESIVIDAD_MAX: float = 1.0
const KILL_PCT_VENTAJA: float = 50.0
const KILL_PCT_DESVENTAJA: float = 75.0
const KILL_PCT_BASE: float = 60.0

const DEF_DIST_X_MAX: float = 90.0
const DEF_DIST_Y_MAX: float = 60.0
const DEF_PROB_BLOQUEO: float = 0.70

const SALTO_VIRTUAL_CORTO: float = 0.18
const SALTO_VIRTUAL_MEDIO: float = 0.22
const SALTO_VIRTUAL_LARGO: float = 0.2

const OFFSTAGE_DANIO_MIN: float = 25.0
const LIMITE_BORDE_X: float = 550.0
const EDGEGUARDING_POS_X: float = 450.0
const EDGEGUARDING_DIST_BORDE: float = 50.0
const EDGEGUARDING_MARGEN_ATAQUE: float = 30.0

const NEUTRAL_PROB_ACERCARSE: float = 0.82
const BLOQUEO_RIVAL_DIST_X: float = 90.0
const COMBO_FOLLOWUP_MARGEN: float = 25.0
const COMBATE_VERTICAL_DIFF_Y: float = -40.0
const COMBO_SALTO_DIFF_Y: float = -50.0
const COMBATE_AEREO_CORRE_DIST_X: float = 180.0
const COMBATE_AEREO_FAST_FALL_Y: float = 80.0

const AIR_DAIR_DIFF_Y: float = 40.0
const AIR_DAIR_ABS_X: float = 50.0
const AIR_UAIR_DIFF_Y: float = -30.0
const AIR_UAIR_ABS_X: float = 60.0
const AIR_NAIR_ABS_X: float = 35.0
const AIR_NAIR_DIFF_Y: float = 35.0

const SUELO_STRONG_UP_DIFF_Y: float = -30.0
const SUELO_STRONG_UP_ABS_X: float = 50.0
const SUELO_STRONG_DOWN_ABS_X: float = 45.0
const SUELO_STRONG_DOWN_PROB: float = 0.4
const SUELO_TILT_UP_DIFF_Y: float = -30.0
const SUELO_TILT_UP_ABS_X: float = 50.0
const SUELO_TILT_DOWN_DIFF_Y: float = 20.0
const SUELO_TILT_DOWN_ABS_X: float = 45.0
const SUELO_TILT_DOWN_PROB: float = 0.3
const SUELO_JAB_ABS_X: float = 40.0

var vidas_IA: int = 3
var vidas_target: int = 3

var _tiempo_para_proxima_decision: float = 0.0
var _intencion_x: float = 0.0
var _intencion_run: bool = false
var _en_combo_followup: bool = false

const RETIRADA_PROB_DECISION = 0.8
const MARGEN_SEGURIDAD_BORDE = 100.0
var _tiempo_debug: float = 0.0

# MÉTODOS VIRTUALES DE GODOT

func _ready() -> void:
	if not controlled_character.is_in_group("IA"):
		set_physics_process(false)
		return
		
	vidas_IA = vidas_iniciales
	vidas_target = vidas_iniciales
	
	target = _buscar_oponente_valido()
	
	if controlled_character.has_signal("muerto"):
		controlled_character.muerto.connect(_on_IA_died)
		
	if is_instance_valid(target) and target.has_signal("muerto"):
		target.muerto.connect(_on_target_died)

func _physics_process(delta: float) -> void:
	_tiempo_debug += delta
	if _tiempo_debug >= DEBUG_INTERVALO:
		_tiempo_debug = 0.0
		debug_estado()
		
	if not is_instance_valid(target):
		target = _buscar_oponente_valido()
		
	if not target or target.dead:
		_ejecutar_recuperacion_desesperada()
		return
		
	if target.invulnerable:
		_ejecutar_retirada_táctica()
		return
	
	_evaluar_defensa_imediata()

	_tiempo_para_proxima_decision -= delta
	if _tiempo_para_proxima_decision <= 0.0:
		_evaluar_intenciones_tacticas()
		_tiempo_para_proxima_decision = randf_range(reaccion_min, reaccion_max)

	controlled_character.input_x = _intencion_x
	controlled_character.is_running = _intencion_run


# MOTOR TÁCTICO Y TOMA DE DECISIONES

func _evaluar_intenciones_tacticas() -> void:
	var dist_vector = target.global_position - controlled_character.global_position
	var dist_x = dist_vector.x
	var abs_dist_x = abs(dist_x)
	var diff_y = dist_vector.y
	
	var mi_zona = controlled_character.zona_actual
	var zona_target = target.zona_actual

	match mi_zona:
		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_DANGER:
			_ejecutar_recuperacion_desesperada()
			return

		controlled_character.ZonaEscenario.AIR_NEAR_WALL:
			var dir_salvo = -sign(controlled_character.global_position.x)
			_intencion_x = dir_salvo if dir_salvo != 0 else 1.0
			_intencion_run = true
			_presionar_salto_virtual(SALTO_VIRTUAL_CORTO)
			return

		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_SAFE:
			var dir_salvo = -sign(controlled_character.global_position.x)
			_intencion_x = dir_salvo if dir_salvo != 0 else 1.0
			_intencion_run = true
			if controlled_character.velocity.y > 0 and controlled_character.saltos_realizados < 2:
				_presionar_salto_virtual(SALTO_VIRTUAL_CORTO)
			return
			
	if randf() < RETIRADA_PROB_DECISION:
		_ejecutar_retirada_táctica()

	if target.is_hitstun:
		if _ejecutar_combo_o_remate(dist_x, diff_y):
			return

	if mi_zona == controlled_character.ZonaEscenario.ON_PLATFORM or mi_zona == controlled_character.ZonaEscenario.AIR_ABOVE_PLATFORM:
		if (zona_target == target.ZonaEscenario.AIR_ABOVE_VOID_DANGER or zona_target == target.ZonaEscenario.AIR_ABOVE_VOID_SAFE):
			# BUG Si el rival está en el vacío mortal, prohibido perseguirle a lo loco
			if zona_target != target.ZonaEscenario.AIR_ABOVE_VOID_DANGER and randf() < agresividad and controlled_character.saltos_realizados == 0 and target.porcentaje_daño > OFFSTAGE_DANIO_MIN:
				_ejecutar_offstage_chase(dist_x, diff_y)
				return
			else:
				_ejecutar_edgeguarding(dist_x, diff_y)
				return

	if not controlled_character.grounded or not target.grounded or diff_y < COMBATE_VERTICAL_DIFF_Y:
		_ejecutar_combate_aereo_vertical(dist_x, diff_y)
		return

	if mi_zona == controlled_character.ZonaEscenario.ON_PLATFORM:
		_procesar_neutral_suelo(dist_x, diff_y, abs_dist_x)


# MOTOR DEFENSIVO REACTIVO

func _evaluar_defensa_imediata() -> void:
	if not is_instance_valid(target): return
	if controlled_character.is_attacking or controlled_character.is_hitstun: return
	
	var dist_vector = target.global_position - controlled_character.global_position
	var abs_dist_x = abs(dist_vector.x)
	var abs_dist_y = abs(dist_vector.y)

	if target.is_attacking and abs_dist_x < DEF_DIST_X_MAX and abs_dist_y < DEF_DIST_Y_MAX:
		if randf() < DEF_PROB_BLOQUEO and controlled_character.grounded:
			controlled_character.bloquear()


# RUTINAS COMBINADAS DE COMBATE

func _ejecutar_combo_o_remate(dist_x: float, diff_y: float) -> bool:
	# Si el objetivo está en el aire en una zona peligrosa (vacío), 
	# cancelamos el combo/remate para evitar que la IA se ponga en peligro.
	if target.zona_actual == controlled_character.ZonaEscenario.AIR_ABOVE_VOID_DANGER:
		return false

	var abs_x = abs(dist_x)
	_intencion_x = sign(dist_x)
	_intencion_run = true

	if diff_y < COMBO_SALTO_DIFF_Y and controlled_character.grounded:
		_presionar_salto_virtual(SALTO_VIRTUAL_MEDIO)

	if abs_x < distancia_ataque + COMBO_FOLLOWUP_MARGEN:
		ejecutar_ataque_segun_posicion(dist_x, diff_y)
	return true

func _ejecutar_combate_aereo_vertical(dist_x: float, diff_y: float) -> void:
	var abs_x = abs(dist_x)
	_intencion_x = sign(dist_x)
	_intencion_run = (abs_x > COMBATE_AEREO_CORRE_DIST_X)

	if controlled_character.grounded and diff_y < COMBATE_VERTICAL_DIFF_Y:
		_presionar_salto_virtual(SALTO_VIRTUAL_MEDIO)

	if abs_x < distancia_ataque:
		ejecutar_ataque_segun_posicion(dist_x, diff_y)

	if not controlled_character.grounded and controlled_character.velocity.y > 0 and diff_y > COMBATE_AEREO_FAST_FALL_Y:
		controlled_character.input_fast_fall = true
	else:
		controlled_character.input_fast_fall = false

func _ejecutar_offstage_chase(dist_x: float, diff_y: float) -> void:
	_intencion_x = sign(dist_x)
	_intencion_run = true

	if abs(dist_x) < distancia_ataque:
		_decidir_ataque_aereo(dist_x, diff_y)
		_en_combo_followup = true

	if abs(controlled_character.global_position.x) > LIMITE_BORDE_X:
		var pos_x_escenario = -sign(controlled_character.global_position.x)
		_intencion_x = pos_x_escenario
		if controlled_character.velocity.y > 0 and controlled_character.saltos_realizados < 2:
			_presionar_salto_virtual(SALTO_VIRTUAL_LARGO)

func _procesar_neutral_suelo(dist_x: float, diff_y: float, abs_dist_x: float) -> void:
	controlled_character.input_fast_fall = false

	if target.is_blocking and abs_dist_x < BLOQUEO_RIVAL_DIST_X:
		_intencion_x = -sign(dist_x)
		_intencion_run = false
		return

	if abs_dist_x > distancia_ataque:
		if randf() < NEUTRAL_PROB_ACERCARSE:
			_intencion_x = sign(dist_x)
			_intencion_run = (abs_dist_x > distancia_correr)
		else:
			_intencion_x = 0
			_intencion_run = false
	else:
		_intencion_x = 0
		_intencion_run = false
		ejecutar_ataque_segun_posicion(dist_x, diff_y)

func _ejecutar_recuperacion_desesperada() -> void:
	var dir_salvo = -sign(controlled_character.global_position.x)
	_intencion_x = dir_salvo if dir_salvo != 0 else 1.0
	_intencion_run = true
	if controlled_character.velocity.y > 0 and controlled_character.saltos_realizados < 2:
		_presionar_salto_virtual(SALTO_VIRTUAL_LARGO)

func _ejecutar_edgeguarding(dist_x: float, diff_y: float) -> void:
	var pos_borde_x = sign(dist_x) * EDGEGUARDING_POS_X
	var dist_borde = abs(controlled_character.global_position.x - pos_borde_x)

	if dist_borde > EDGEGUARDING_DIST_BORDE:
		_intencion_x = sign(dist_x)
		_intencion_run = true
	else:
		_intencion_x = 0
		_intencion_run = false
		if abs(dist_x) < distancia_ataque + EDGEGUARDING_MARGEN_ATAQUE:
			ejecutar_ataque_segun_posicion(dist_x, diff_y)

func _ejecutar_retirada_táctica() -> void:
	var pos_x_actual = controlled_character.global_position.x
	
	if abs(pos_x_actual) > (LIMITE_BORDE_X - MARGEN_SEGURIDAD_BORDE):
		_intencion_x = -sign(pos_x_actual)
	else:
		var dist_x = target.global_position.x - pos_x_actual
		_intencion_x = -sign(dist_x)
		
	_intencion_run = true
	controlled_character.input_x = _intencion_x
	controlled_character.is_running = _intencion_run


# SISTEMA DE SELECCIÓN DE ATAQUES

func ejecutar_ataque_segun_posicion(dist_x: float, diff_y: float) -> void:
	if controlled_character.is_attacking or controlled_character.is_hitstun: return

	if not controlled_character.grounded:
		_decidir_ataque_aereo(dist_x, diff_y)
	else:
		_decidir_ataque_suelo(dist_x, diff_y)

func _decidir_ataque_aereo(dist_x: float, diff_y: float) -> void:
	var abs_x = abs(dist_x)
	var mirando_a_derecha = (controlled_character.facing == "right")
	var rival_a_la_derecha = (dist_x > 0)
	var esta_enfrente = (mirando_a_derecha == rival_a_la_derecha)

	if diff_y > AIR_DAIR_DIFF_Y and abs_x < AIR_DAIR_ABS_X:
		controlled_character.atacar_dair()
	elif diff_y < AIR_UAIR_DIFF_Y and abs_x < AIR_UAIR_ABS_X:
		controlled_character.atacar_uair()
	elif abs_x < AIR_NAIR_ABS_X and abs(diff_y) < AIR_NAIR_DIFF_Y:
		controlled_character.atacar_nair()
	elif esta_enfrente:
		controlled_character.atacar_fair()
	else:
		controlled_character.atacar_bair()

func _decidir_ataque_suelo(dist_x: float, diff_y: float) -> void:
	var abs_x = abs(dist_x)
	var es_kill_percent = (target.porcentaje_daño >= umbral_porcentaje_kill)

	if es_kill_percent:
		if diff_y < SUELO_STRONG_UP_DIFF_Y and abs_x < SUELO_STRONG_UP_ABS_X:
			controlled_character.atacar_strong_up()
		elif abs_x < SUELO_STRONG_DOWN_ABS_X and randf() < SUELO_STRONG_DOWN_PROB:
			controlled_character.atacar_strong_down()
		else:
			controlled_character.atacar_strong_side()
	else:
		if diff_y < SUELO_TILT_UP_DIFF_Y and abs_x < SUELO_TILT_UP_ABS_X:
			controlled_character.atacar_tilt_up()
		elif diff_y > SUELO_TILT_DOWN_DIFF_Y or (abs_x < SUELO_TILT_DOWN_ABS_X and randf() < SUELO_TILT_DOWN_PROB):
			controlled_character.atacar_tilt_down()
		elif abs_x < SUELO_JAB_ABS_X:
			controlled_character.atacar_jab()
		else:
			controlled_character.atacar_tilt_side()


# GESTIÓN DE PSICOLOGÍA, ESTADOS Y UTILIDADES

func _recalcular_psicologia_ia() -> void:
	var diferencia_vidas = vidas_IA - vidas_target

	if diferencia_vidas > 0:
		agresividad = clamp(agresividad_base * PSICOLOGIA_MULT_VENTAJA, AGRESIVIDAD_MIN_VENTAJA, AGRESIVIDAD_MAX)
		umbral_porcentaje_kill = KILL_PCT_VENTAJA
	elif diferencia_vidas < 0:
		agresividad = clamp(agresividad_base * PSICOLOGIA_MULT_DESVENTAJA, AGRESIVIDAD_MIN_DESVENTAJA, AGRESIVIDAD_MAX_DESVENTAJA)
		umbral_porcentaje_kill = KILL_PCT_DESVENTAJA
	else:
		agresividad = agresividad_base
		umbral_porcentaje_kill = KILL_PCT_BASE

func _buscar_oponente_valido() -> Character:
	var todos = get_tree().get_nodes_in_group("character")
	for p in todos:
		if p is Character and p != controlled_character:
			return p
	return null

func _quedarse_quieto() -> void:
	controlled_character.input_x = 0
	controlled_character.input_salto = false
	controlled_character.input_fast_fall = false
	controlled_character.is_running = false
	_intencion_x = 0.0
	_intencion_run = false

func _presionar_salto_virtual(duracion: float) -> void:
	if controlled_character.input_salto: return
	controlled_character.input_salto = true
	await get_tree().create_timer(duracion).timeout
	if is_instance_valid(controlled_character):
		controlled_character.input_salto = false

func _on_IA_died() -> void:
	vidas_IA = max(0, vidas_IA - 1)
	_recalcular_psicologia_ia()

func _on_target_died() -> void:
	vidas_target = max(0, vidas_target - 1)
	_ejecutar_recuperacion_desesperada()

func debug_estado() -> void:
	var IA_vidas_str = "[color=green]Vidas: %d[/color]" % vidas_IA
	var target_vidas_str = "[color=red]Rival Vidas: %d[/color]" % vidas_target
	
	var diferencia = vidas_IA - vidas_target
	var psico_str = ""
	if diferencia > 0:
		psico_str = "[color=cyan]VENTAJA (+%d)[/color]" % abs(diferencia)
	elif diferencia < 0:
		psico_str = "[color=orange]DESVENTAJA (-%d)[/color]" % abs(diferencia)
	else:
		psico_str = "[color=white]IGUALDAD (0)[/color]"

	var agresividad_str = "Agres: %.2f" % agresividad
	var kill_pct_str = "Kill@: %.0f%%" % umbral_porcentaje_kill
	
	var intencion_mov = "X: %+1.1f" % _intencion_x
	var corriendo_str = "[color=yellow]RUN[/color]" if _intencion_run else "WALK"
	
	var zona_str = ""
	match controlled_character.zona_actual:
		controlled_character.ZonaEscenario.ON_PLATFORM:
			zona_str = "[color=green]PLATFORM[/color]"
		controlled_character.ZonaEscenario.AIR_ABOVE_PLATFORM:
			zona_str = "[color=cyan]AIR_PLAT[/color]"
		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_SAFE:
			zona_str = "[color=yellow]VOID_SAFE[/color]"
		controlled_character.ZonaEscenario.AIR_ABOVE_VOID_DANGER:
			zona_str = "[color=red]VOID_DANGER[/color]"
		controlled_character.ZonaEscenario.AIR_NEAR_WALL:
			zona_str = "[color=orange]NEAR_WALL[/color]"
		_:
			zona_str = "UNKNOWN"

	print_rich("|[b] IA:[/b] %-10s |[b] RIVAL:[/b] %-12s |[b] ESTADO:[/b] %-18s |[b] CONFIG:[/b] %-14s |[b] %-9s[/b] |[b] MOV:[/b] %-8s |[b] %-4s[/b] |[b] ZONA:[/b] %-18s"
		% [IA_vidas_str, target_vidas_str, psico_str, agresividad_str, kill_pct_str, intencion_mov, corriendo_str, zona_str])
