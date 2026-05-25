extends CharacterBody2D

# --- NODOS ---
@onready var ground_check: RayCast2D = $RayCast2D
@onready var timer_salto: Timer = $JumpHeightTimer
@onready var animation_tree: AnimationTree = $AnimationTree #TODO
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var root_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var movimiento_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Movimiento/playback")
@onready var ataque_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Ataque/playback")

@onready var idle_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Movimiento/idle/playback")

# --- CONSTANTES ---
const SPEED := Globals.PLAYER_SPEED
const JUMP_FORCE := Globals.PLAYER_JUMP_FORCE
const GRAVITY := Globals.GRAVITY

# --- ESTADO ---
var saltando: bool = false # Indica intención de salto, no si está en el aire
var num = 0
var is_attacking = false
var active_playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	timer_salto.wait_time = Globals.MIN_JUMP_TIME
	timer_salto.one_shot = true
	animation_tree.active = true
	print(animation_tree)
	root_playback.travel("Movimiento")

func _process(_delta: float) -> void:
	pass # TODO: imprimir estados para la máquina de estados
	update_animation_parameters()
	if is_attacking:
		active_playback = ataque_playback
	else:
		active_playback = movimiento_playback

	var estado_actual = Globals.get_deepest_animation(animation_tree, active_playback)
	#print("Estado actual:", estado_actual)


func _physics_process(delta: float) -> void:
	_aplicar_gravedad(delta)
	
	_mover_horizontal()
	_procesar_salto()
	# Move and slide para aplicar cambios segun el movimiento
	move_and_slide()
	

var last_movimiento_state: String = ""

func change_movimiento_state(name: String):

	var current := movimiento_playback.get_current_node()

	# Si ya estamos en ese estado, no hacemos nada
	if current == name:
		return

	# Si no, viajamos
	movimiento_playback.travel(name)

	# Si estamos entrando en Idle desde otro estado
	if name == "idle":
		choose_random_idle()


func choose_random_idle():
	var r = randi_range(1, 3)
	idle_playback.travel("idle" + str(r))

func update_animation_parameters():
	if ground_check.is_colliding():
		if velocity == Vector2.ZERO:
			change_movimiento_state("idle")
		else:
			change_movimiento_state("walk")

# =========================
#        MOVIMIENTO
# =========================

func _aplicar_gravedad(delta: float) -> void:
	if ground_check.is_colliding():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta


func _mover_horizontal() -> void:
	var input_dir := Input.get_axis("izquierda", "derecha")
	velocity.x = input_dir * SPEED
	# Rotación horizontal del sprite según dirección
	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true

# =========================
#           SALTO
# =========================

func _procesar_salto() -> void:
	if Input.is_action_pressed("salto") and ground_check.is_colliding():
		_iniciar_salto()

	if not Input.is_action_pressed("salto") and saltando:
		_interrumpir_salto()


func _iniciar_salto() -> void:
	change_movimiento_state("jump")
	timer_salto.start()
	velocity.y = -JUMP_FORCE
	saltando = true


func _interrumpir_salto() -> void:
	saltando = false

	# Si el tiempo mínimo ya pasó, cortamos ahora
	if timer_salto.is_stopped():
		corta_salto()


func corta_salto() -> void:
	change_movimiento_state("fall")
	if velocity.y < 0:
		velocity.y *= 0.15

# TIMER

func _on_jump_height_timer_timeout() -> void:
	# Si el jugador ya no quiere saltar, cortamos ahora
	if not saltando:
		corta_salto()
