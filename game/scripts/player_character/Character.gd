extends CharacterBody2D
class_name Character

# NODOS
@onready var ground_check: RayCast2D = $RayCast2D
@onready var timer_salto: Timer = $JumpHeightTimer
@onready var combo_timer: Timer = $ComboTimer 
@onready var stun_timer: Timer = $StunTimer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var visuals: Node2D = $Visuals 
@onready var push_area: Area2D = $PushArea

# PLAYBACKS
@onready var root_playback = animation_tree.get("parameters/playback")
@onready var movimiento_playback = animation_tree.get("parameters/Movimiento/playback")
@onready var ataque_aire_playback = animation_tree.get("parameters/AtaquesAire/playback")
@onready var ataque_suelo_playback = animation_tree.get("parameters/AtaquesSuelo/playback")
@onready var idle_playback = animation_tree.get("parameters/Movimiento/idle/playback")
@onready var damage_playback = animation_tree.get("parameters/Damage/playback")

# CONSTANTES
const SPEED: int = Globals.PLAYER_SPEED
const JUMP_FORCE: int = Globals.PLAYER_JUMP_FORCE
const GRAVITY: int = Globals.GRAVITY
const PUSH_FORCE: float = Globals.PUSH_FORCE

# VARIABLES DE CONTROL (Inyectadas por los controladores)
var input_x: float = 0.0
var input_salto: bool = false
var input_fast_fall: bool = false
var is_running: bool = false

# ESTADO
var saltando_pressed: bool = false 
var grounded: bool = true 
@export var is_attacking: bool = false 
@export var can_flip: bool = true
@export var is_blocking: bool = false
var last_movimiento_state: String = ""
var facing: String
var is_fast_falling: bool = false
var saltos_realizados: int = 0
var is_hitstun: bool = false
var porcentaje_daño: float = 0.0 
var push_velocity: float = 0.0

# SEÑALES
signal damage_changed(new_percentage: float, character: Character)

func _ready() -> void:
	timer_salto.wait_time = Globals.MIN_JUMP_TIME
	timer_salto.one_shot = true
	combo_timer.wait_time = Globals.MIN_COMBO_TIMER
	combo_timer.one_shot = true
	animation_tree.active = true
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	root_playback.travel("Movimiento")
	AnimationFunctions.change_movimiento_state(movimiento_playback, idle_playback, "idle")

func _process(_delta: float) -> void:
	self.grounded = ground_check.is_colliding()
	self.facing = "DER >" if visuals.scale.x < 0 else "< IZQ"

func _physics_process(delta: float) -> void:
	# Aplicar Gravedad
	MoveFunctions.aplicar_gravedad(self, delta, GRAVITY)
	if is_hitstun:
		move_and_slide()
		return 

	# Gestionar Fast Fall (Actualizamos el estado según el input)
	if not grounded and velocity.y > 0:
		if input_fast_fall and not is_fast_falling:
			JumpFunctions.activar_fast_fall(self)
		elif not input_fast_fall and is_fast_falling:
			JumpFunctions.cancelar_fast_fall(self)

	# Acciones de Movimiento
	if is_attacking and grounded:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.2)
	else:
		mover_lateralmente(input_x)
		
	# Procesar Salto
	JumpFunctions.procesar_salto(self, input_salto, timer_salto, JUMP_FORCE)
	_gestionar_empuje_oponente(delta)
	move_and_slide()
	_update_animation_state()

func mover_lateralmente(dir: float) -> void:
	var multiplier = 1.6 if is_running else 1.0
	velocity.x = dir * SPEED * multiplier
	
	if can_flip and dir != 0:
		visuals.scale.x = -1 if dir > 0 else 1
		actualizar_direccion_hitboxes()

# FUNCIONES DE ATAQUE (Invocables desde controladores)

func _ejecutar_accion(anim_name: String, es_suelo: bool) -> void:
	if is_hitstun: return
	if is_attacking and root_playback.get_current_node() == "AtaquesSuelo":
		var current_anim = ataque_suelo_playback.get_current_node()
		if current_anim in ["jab1", "jab2"]:
			animation_tree["parameters/AtaquesSuelo/conditions/quiere_combo"] = true
			combo_timer.start()
			return 
	if es_suelo and grounded:
		root_playback.travel("AtaquesSuelo")
		ataque_suelo_playback.travel(anim_name)
	elif not es_suelo and not grounded:
		root_playback.travel("AtaquesAire")
		ataque_aire_playback.travel(anim_name)

func _gestionar_empuje_oponente(delta: float) -> void:
	# Obtenemos el primer área que esté solapando
	var areas = push_area.get_overlapping_areas()
	
	if areas.size() > 0:
		var oponente = areas[0].get_parent()
		
		# Verificamos que sea un Character y no nosotros mismos
		if oponente is Character and oponente != self:
			# Calculamos dirección (mí posición relativa al oponente)
			var diff_x = global_position.x - oponente.global_position.x
			
			# Romper empate si están en el mismo píxel
			if abs(diff_x) < 0.1: 
				diff_x = 1.0 if randi_range(0,1) == 1 else -1.0
			
			# Aplicar empuje directo a la velocidad
			velocity.x += sign(diff_x) * PUSH_FORCE * delta * 60


func atacar_jab():			_ejecutar_accion("jab1", true)
func atacar_tilt_up():		_ejecutar_accion("up_tilt", true)
func atacar_tilt_down():	_ejecutar_accion("down_tilt", true)
func atacar_tilt_side():	_ejecutar_accion("side_tilt", true)
func atacar_strong_up():	_ejecutar_accion("up_strong", true)
func atacar_strong_down():	_ejecutar_accion("down_strong", true)
func atacar_strong_side():	_ejecutar_accion("side_strong", true)
func atacar_nair():			_ejecutar_accion("nair", false)
func atacar_uair():			_ejecutar_accion("uair", false)
func atacar_dair():			_ejecutar_accion("dair", false)
func atacar_fair():			_ejecutar_accion("fair", false)
func atacar_bair():			_ejecutar_accion("bair", false)
func bloquear():			_ejecutar_accion("block", true)

func _update_animation_state() -> void:
	if is_attacking or is_hitstun: return
	var new_state: String = ""
	if not grounded: new_state = "jump" if velocity.y < 0 else "fall"
	else: new_state = "run" if (abs(velocity.x) > 300) else ("walk" if abs(velocity.x) > 10 else "idle")
	if new_state != last_movimiento_state:
		AnimationFunctions.change_movimiento_state(movimiento_playback, idle_playback, new_state)
		last_movimiento_state = new_state

func take_damage(damage: float, knockback_vector: Vector2, knockback_force: float) -> void:
	# Acumulamos daño y notificamos a la HUD
	porcentaje_daño += damage
	damage_changed.emit(porcentaje_daño, self)
	print("Daño actual: ", porcentaje_daño, "%")
	
	# Interrumpimos acciones actuales
	is_attacking = false
	is_hitstun = true
	
	# Calculamos y aplicamos el Empuje (escalado por porcentaje)
	var direccion: Vector2 = knockback_vector.normalized()
	velocity = direccion * (knockback_force + knockback_force * (porcentaje_daño / 100.0))
	
	# Reproducimos animaciones en el AnimationTree
	root_playback.travel("Damage")
	if damage_playback:
		damage_playback.travel("hitstun")
	
	# Feedback visual
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Calculamos el tiempo de hitstun en funcion del daño acumulado
	var tiempo_stun: float = 0.15 + (porcentaje_daño / 100.0) * 0.35
	
	# Limitamos el stun a 1 segundo
	tiempo_stun = clamp(tiempo_stun, 0.15, 1)
	
	# Configuramos y arrancamos el StunTimer
	stun_timer.wait_time = tiempo_stun
	stun_timer.one_shot = true
	
	# Si el temporizador ya estaba corriendo (porque nos pegaron antes hace poco), 
	# lo desconectamos para evitar que la señal antigua nos quite el stun antes de tiempo.
	if stun_timer.timeout.is_connected(_on_stun_timeout):
		stun_timer.timeout.disconnect(_on_stun_timeout)
		
	stun_timer.timeout.connect(_on_stun_timeout, CONNECT_ONE_SHOT)
	stun_timer.start()


# --- FUNCIÓN LLAMADA AL TERMINAR EL TIMER ---
func _on_stun_timeout() -> void:
	# Devolvemos el control al personaje si sigue vivo/en hitstun
	if is_hitstun:
		is_hitstun = false
		root_playback.travel("Movimiento")
	
func aplicar_block_stun(dir: Vector2, force: float) -> void:
	# Estado físico
	velocity = dir * force
	is_attacking = false
	is_hitstun = true # Lo tratamos como hitstun para que no pueda moverse
	# Animación
	root_playback.travel("Damage")
	if damage_playback:
		damage_playback.travel("hitstun") # TODO block_stun en lugar de hitstun
	# Feedback visual
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.ORANGE, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	# Recuperación
	# El blockstun suele ser más corto que el hitstun normal para que el castigo sea rápido
	await get_tree().create_timer(0.3).timeout
	is_hitstun = false
	root_playback.travel("Movimiento")

func actualizar_direccion_hitboxes() -> void:
	# Determinamos el multiplicador según la escala de los visuales
	# Si visuals.scale.x es -1 (mira a la derecha en tu código), multiplicador es 1
	# Si visuals.scale.x es 1 (mira a la izquierda), multiplicador es -1
	var multiplicador_x = -sign(visuals.scale.x)
	
	var nodos_categoria = $Visuals/Hitboxes.get_children()
	
	for categoria in nodos_categoria:
		for hitbox in categoria.get_children():
			if hitbox is Hitbox:
				# Ajustamos solo el eje X basado en la dirección actual
				hitbox.current_knockback_vector = Vector2(
					hitbox.base_knockback_vector.x * multiplicador_x,
					hitbox.base_knockback_vector.y
				)
	

func _on_combo_timer_timeout() -> void:
	animation_tree["parameters/AtaquesSuelo/conditions/quiere_combo"] = false

func debug_estado() -> void:
	var anim_ruta = Globals.get_deepest_animation(animation_tree, root_playback)
	var grounded_str = "[color=green]SUELO[/color]" if grounded else "[color=skyblue]AIRE[/color]"
	var atk_str = "[color=red]ATACANDO[/color]" if is_attacking else "[color=gray]LIBRE[/color]"
	var flip_str = "[color=yellow]LOCK[/color]" if not can_flip else "[color=cyan]FREE[/color]"
	var mira_str = self.facing
	var combo_val = animation_tree.get("parameters/AtaquesSuelo/conditions/quiere_combo")
	var combo_str = "[color=magenta]COMBO_ON[/color]" if combo_val else "------"
	print_rich("|[b] ANIM:[/b] %-25s |[b] POS:[/b] %-8s |[b] ATK:[/b] %-15s |[b] FLIP:[/b] %-12s |[b] MIRA:[/b] %-8s |[b] JAB:[/b] %-10s | V(%+4d, %+4d)" 
		% [anim_ruta, grounded_str, atk_str, flip_str, mira_str, combo_str, velocity.x, velocity.y])
