extends CharacterBody2D
class_name Character

# ENUMERADO DE GEOLOCALIZACIÓN
enum ZonaEscenario {
	ON_PLATFORM,
	AIR_ABOVE_PLATFORM,
	AIR_ABOVE_VOID_SAFE,
	AIR_ABOVE_VOID_DANGER,
	AIR_NEAR_WALL
}

# NODOS (Añadimos el Raycast del Vacío)
@onready var ground_check: RayCast2D = $Areas/RayCastGround
@onready var void_check: RayCast2D = $Areas/RayCastVoid
@onready var void_check_left: RayCast2D = $Areas/RayCastVoidLeft
@onready var void_check_right: RayCast2D = $Areas/RayCastVoidRight
@onready var timer_salto: Timer = $Timers/JumpHeightTimer
@onready var combo_timer: Timer = $Timers/ComboTimer 
@onready var stun_timer: Timer = $Timers/StunTimer
@onready var invulnerability_timer: Timer = $Timers/InvulnerabilityTimer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var push_area: Area2D = $Areas/PushArea
@onready var visuals: Node2D = $Visuals
@onready var SFX: Node2D = $SFX

# PLAYBACKS
@onready var root_playback = animation_tree.get("parameters/playback")
@onready var movimiento_playback = animation_tree.get("parameters/Movimiento/playback")
@onready var ataque_aire_playback = animation_tree.get("parameters/AtaquesAire/playback")
@onready var ataque_suelo_playback = animation_tree.get("parameters/AtaquesSuelo/playback")
@onready var idle_playback = animation_tree.get("parameters/Movimiento/idle/playback")
@onready var damage_playback = animation_tree.get("parameters/Damage/playback")

# CONSTANTES
const SPEED: int = Globals.PLAYER_SPEED
const JUMP_FORCE: Vector2 = Globals.PLAYER_JUMP_FORCE
const GRAVITY: int = Globals.GRAVITY
const PUSH_FORCE: float = Globals.PUSH_FORCE

# VARIABLES DE CONTROL
var _input_x: float = 0.0
var _input_salto: bool = false
var _input_fast_fall: bool = false
var _is_running: bool = false

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
var dead = false
var invulnerable = false

# CONTROL GEOGRÁFICO Y WALLJUMP
var zona_actual: ZonaEscenario = ZonaEscenario.ON_PLATFORM
var wall_jump_lock_timer: float = 0.0
var hizo_wall_jump: bool = false

# SEÑALES
signal damage_changed(new_percentage: float, character: Character)
signal muerto

func set_sprite(color_name: String) -> void:
	var path = "res://sprites/animaciones/%s/%s.tres" % [color_name, color_name]
	var frames = load(path)
	
	if frames and sprite:
		sprite.sprite_frames = frames
		sprite.play("basic_idle1")

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
	# Debug visual de la orientación del personaje
	self.facing = "DER >" if visuals.scale.x < 0 else "< IZQ"
	#debug_estado()

func _physics_process(delta: float) -> void:
	if dead:
		move_and_slide()
		return
	
	if not self.grounded:
		self.grounded = ground_check.is_colliding()
		if self.grounded: SFX.land.play()
	self.grounded = ground_check.is_colliding()

	_actualizar_zona_actual()

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	JumpFunctions.aplicar_gravedad(self, delta, GRAVITY)
	
	if is_hitstun:
		move_and_slide()
		return 

	if not grounded and velocity.y > 0:
		if _input_fast_fall and not is_fast_falling:
			JumpFunctions.activar_fast_fall(self)
		elif not _input_fast_fall and is_fast_falling:
			JumpFunctions.cancelar_fast_fall(self)

	var input_horizontal_final = 0.0 if wall_jump_lock_timer > 0.0 else _input_x
	mover_lateralmente(input_horizontal_final)
		
	var ha_saltado = JumpFunctions.procesar_salto(self, _input_salto, timer_salto, JUMP_FORCE)
	if ha_saltado:
		SFX.jump.play()
		if hizo_wall_jump:
			wall_jump_lock_timer = 0.22 
			hizo_wall_jump = false 
			
	_gestionar_empuje_oponente(delta)
	
	move_and_slide()
	_update_animation_state()

func _actualizar_zona_actual() -> void:
	if grounded:
		zona_actual = ZonaEscenario.ON_PLATFORM
		return
		
	if is_on_wall_only():
		zona_actual = ZonaEscenario.AIR_NEAR_WALL
		return
		
	if void_check and void_check.is_colliding():
		zona_actual = ZonaEscenario.AIR_ABOVE_PLATFORM
		return
		
	var diagonal_izquierdo_toca = void_check_left and void_check_left.is_colliding()
	var diagonal_derecho_toca = void_check_right and void_check_right.is_colliding()
	
	if diagonal_izquierdo_toca or diagonal_derecho_toca:
		zona_actual = ZonaEscenario.AIR_ABOVE_VOID_SAFE
	else:
		zona_actual = ZonaEscenario.AIR_ABOVE_VOID_DANGER

func mover_lateralmente(dir: float) -> void:
	if abs(dir) < 0.1:
		dir = 0.0

	if is_attacking and grounded:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.2)
		return

	# Usamos _is_running en lugar de la variable directa
	var multiplier = 1.6 if _is_running else 1.0
	var target_speed = dir * SPEED * multiplier
	
	var accel: float
	if not grounded:
		target_speed *= 1.2
		accel = SPEED * (0.8 if dir != 0 else 0.02)
	else:
		accel = SPEED * (0.2 if dir != 0 else 0.3)
		
	velocity.x = move_toward(velocity.x, target_speed, accel)
	
	if can_flip and dir != 0:
		var nueva_escala = -1 if dir > 0 else 1
		if visuals.scale.x != nueva_escala:
			visuals.scale.x = nueva_escala
			actualizar_direccion_hitboxes()
# FUNCIONES DE ATAQUE (Invocables desde controladores)

func _ejecutar_accion(anim_name: String, es_suelo: bool) -> void:
	if is_hitstun: return
	if is_attacking and root_playback.get_current_node() == "AtaquesSuelo":
		var current_anim = ataque_suelo_playback.get_current_node()
		if current_anim in ["jab1", "jab2"]:
			animation_tree["parameters/AtaquesSuelo/conditions/quiere_combo"] = true
			combo_timer.start()
			SFX.punch_woosh_1.play()
		return 
	if es_suelo and grounded and not is_attacking:
		root_playback.travel("AtaquesSuelo")
		ataque_suelo_playback.travel(anim_name)
		if anim_name == "block":
			pass
		elif anim_name.ends_with("_strong"):
			SFX.punch_woosh_2.play()
		else:
			SFX.punch_woosh_1.play()
		return
	elif not es_suelo and not grounded and not is_attacking:
		root_playback.travel("AtaquesAire")
		ataque_aire_playback.travel(anim_name)
		SFX.punch_woosh_1.play()

func take_damage(damage: float, knockback_vector: Vector2, knockback_force: float) -> void:
	# Acumulamos daño y notificamos a la HUD
	SFX.punch_hit.play()
	porcentaje_daño += damage
	damage_changed.emit(porcentaje_daño, self)
	#print("Daño actual: ", porcentaje_daño, "%")
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
	var tiempo_stun: float = Globals.MIN_HITSTUN_TIME + (porcentaje_daño / 100.0) * Globals.HITSTUN_TIME_DAMAGE_MULT
	# Limitamos el stun a 1 segundo
	tiempo_stun = clamp(tiempo_stun, 0.15, 1.0)
	# Configuramos y arrancamos el StunTimer
	stun_timer.wait_time = tiempo_stun
	stun_timer.one_shot = true
	
	# Desconectar señales previas si nos golpean consecutivamente como parte de un combo
	if stun_timer.timeout.is_connected(_on_stun_timeout):
		stun_timer.timeout.disconnect(_on_stun_timeout)
		
	stun_timer.timeout.connect(_on_stun_timeout, CONNECT_ONE_SHOT)
	stun_timer.start()

func deadzone_kill(respawn_position: Node2D) -> void:
	#print("player dead")
	dead = true
	muerto.emit()
	animation_tree.active = false
	animation_player.play("dead")
	
	# Notificamos la muerte inmediatamente a la escena/HUD
	
	await animation_player.animation_finished
	
	set_physics_process(false)
	
	# Comprobamos nuevamente antes de intentar reaparecer por si la escena cambió durante la espera
	if is_inside_tree():
		reset_player(respawn_position)

func reset_player(respawn_position: Node2D) -> void:
	dead = false
	saltos_realizados = 0
	set_physics_process(true)
	animation_tree.active = true
	root_playback.travel("Movimiento")
	porcentaje_daño = 0
	velocity = Vector2.ZERO
	position = respawn_position.global_position
	invulnerability_timer.start()
	invulnerable = true
	_aplicar_efecto_invulnerabilidad(true)

func _aplicar_efecto_invulnerabilidad(activo: bool) -> void:
	if activo:
		while invulnerable:
			sprite.modulate = Color(2, 2, 2, 1)
			await get_tree().create_timer(0.15).timeout
			if not invulnerable: break
			sprite.modulate = Color(1, 1, 1, 0.4)
			await get_tree().create_timer(0.15).timeout
		sprite.modulate = Color(1, 1, 1, 1)

func _on_invulnerability_timer_timeout() -> void:
	invulnerable = false
	_aplicar_efecto_invulnerabilidad(false)

func aplicar_block_stun(dir: Vector2, force: float) -> void:
	# Interrumpuimos acciones y aplicamos estado de hitstun (aunque no sea un "hit")
	is_attacking = false
	is_hitstun = true
	SFX.parry.play()
	# Empuje físico al atacante (hacia atrás por rebotar contra el escudo)
	velocity = dir.normalized() * force
	# Lanzamos animaciones en el State Machine de Damage
	root_playback.travel("Damage")
	if damage_playback:
		damage_playback.travel("hitstun") 
	# Feedback visual (Color naranja/amarillo para diferenciarlo de recibir daño)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.ORANGE, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	# Configurar el StunTimer con un tiempo fijo para el Blockstun
	stun_timer.wait_time = Globals.TIEMPO_BLOCKSTUN
	stun_timer.one_shot = true
	# Limpieza de conexiones previas de seguridad
	if stun_timer.timeout.is_connected(_on_stun_timeout):
		stun_timer.timeout.disconnect(_on_stun_timeout)
	
	stun_timer.timeout.connect(_on_stun_timeout, CONNECT_ONE_SHOT)
	stun_timer.start()
	
# FUNCIÓN LLAMADA AL TERMINAR EL TIMER
func _on_stun_timeout() -> void:
	if is_hitstun:
		is_hitstun = false
		
		# Limpieza profunda de inputs fantasmas para evitar arranques mecánicos raros
		_input_x = 0.0
		_input_salto = false
		_input_fast_fall = false
		
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
				
func _gestionar_empuje_oponente(delta: float) -> void:
	var areas = push_area.get_overlapping_areas()
	if areas.size() > 0:
		var oponente = areas[0].get_parent()
		if oponente is Character and oponente != self:
			var diff_x = global_position.x - oponente.global_position.x
			if abs(diff_x) < 0.1: 
				diff_x = 1.0 if randi_range(0,1) == 1 else -1.0
			velocity.x += sign(diff_x) * PUSH_FORCE * delta * 60

# ACCIONES
func set_horizontal_input(value: float) -> void:
	_input_x = value
func set_jump_input(pressed: bool) -> void:
	_input_salto = pressed
func set_fast_fall_input(pressed: bool) -> void:
	_input_fast_fall = pressed
func set_running(running: bool) -> void:
	_is_running = running
func atacar_jab(): _ejecutar_accion("jab1", true)
func atacar_tilt_up(): _ejecutar_accion("up_tilt", true)
func atacar_tilt_down(): _ejecutar_accion("down_tilt", true)
func atacar_tilt_side(): _ejecutar_accion("side_tilt", true)
func atacar_strong_up(): _ejecutar_accion("up_strong", true)
func atacar_strong_down(): _ejecutar_accion("down_strong", true)
func atacar_strong_side(): _ejecutar_accion("side_strong", true)
func atacar_nair(): _ejecutar_accion("nair", false)
func atacar_uair(): _ejecutar_accion("uair", false)
func atacar_dair(): _ejecutar_accion("dair", false)
func atacar_fair(): _ejecutar_accion("fair", false)
func atacar_bair(): _ejecutar_accion("bair", false)
func bloquear(): _ejecutar_accion("block", true)

func _update_animation_state() -> void:
	if is_attacking or is_hitstun: return
	var new_state: String = ""
	if not grounded: 
		new_state = "jump" if velocity.y < 0 else "fall"
	else: 
		new_state = "run" if (abs(velocity.x) > Globals.RUN_SPEED) else ("walk" if abs(velocity.x) > Globals.WALK_SPEED else "idle")
		
	if new_state != last_movimiento_state:
		AnimationFunctions.change_movimiento_state(movimiento_playback, idle_playback, new_state)
		last_movimiento_state = new_state

func _on_combo_timer_timeout() -> void:
	animation_tree["parameters/AtaquesSuelo/conditions/quiere_combo"] = false

func debug_estado() -> void:
	var anim_ruta = Globals.get_deepest_animation(animation_tree, root_playback)
	var grounded_str = "[color=green]SUELO[/color]" if grounded else "[color=skyblue]AIRE[/color]"
	var atk_str = "[color=red]ATACANDO[/color]" if is_attacking else "[color=gray]LIBRE[/color]"
	var flip_str = "[color=yellow]LOCK[/color]" if not can_flip else "[color=cyan]FREE[/color]"
	var mira_str = self.facing
	
	var zona_str = ""
	match zona_actual:
		ZonaEscenario.ON_PLATFORM:
			zona_str = "[color=green]PLATFORM[/color]"
		ZonaEscenario.AIR_ABOVE_PLATFORM:
			zona_str = "[color=cyan]AIR_PLAT[/color]"
		ZonaEscenario.AIR_ABOVE_VOID_SAFE:
			zona_str = "[color=yellow]VOID_SAFE[/color]"
		ZonaEscenario.AIR_ABOVE_VOID_DANGER:
			zona_str = "[color=red]VOID_DANGER[/color]"
		ZonaEscenario.AIR_NEAR_WALL:
			zona_str = "[color=orange]NEAR_WALL[/color]"
		_:
			zona_str = "UNKNOWN"

	print_rich("|[b] ANIM:[/b] %-25s |[b] POS:[/b] %-8s |[b] ATK:[/b] %-15s |[b] FLIP:[/b] %-12s |[b] MIRA:[/b] %-8s |[b] ZONA:[/b] %-18s | V(%+4d, %+4d)"
		% [anim_ruta, grounded_str, atk_str, flip_str, mira_str, zona_str, velocity.x, velocity.y])
