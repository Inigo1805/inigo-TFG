#jab: 		light_punch1 light_punch8 light_punch2
#side tilt:	light_kick4
#up tilt: 	light_kick7
#down tilt:	light_kick1
#nair:		air_kick4
#fair:		air_kick2
#bair:		heavy_kick12
#uair:		ex_move_18
#dair:		air_punch7
#side strong:	heavy_punch15
#up strong:	heavy_kick19
#down strong:	heavy_kick8


extends CharacterBody2D

# --- NODOS ---
@onready var ground_check: RayCast2D = $RayCast2D
@onready var timer_salto: Timer = $JumpHeightTimer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Playbacks
@onready var root_playback = animation_tree.get("parameters/playback")
@onready var movimiento_playback = animation_tree.get("parameters/Movimiento/playback")
@onready var ataque_playback = animation_tree.get("parameters/Ataque/playback")
@onready var idle_playback = animation_tree.get("parameters/Movimiento/idle/playback")

# --- CONSTANTES ---
const SPEED = Globals.PLAYER_SPEED
const JUMP_FORCE = Globals.PLAYER_JUMP_FORCE
const GRAVITY = Globals.GRAVITY

# --- ESTADO ---
var saltando = false
var num = 0
var is_attacking = false
var active_playback: AnimationNodeStateMachinePlayback
var last_movimiento_state: String = ""
# Variables para correr
var last_tap_time_derecha: float = 0.0
var last_tap_time_izquierda: float = 0.0
var is_running: bool = false
const DOUBLE_TAP_DELAY: float = 0.25 # Tiempo máximo entre clics
var stop_time: float = 0.0 # Momento en el que se deja de correr (para el quick turn)
const RUN_GRACE_PERIOD: float = 0.15 # Tiempo para cambiar de dirección sin dejar de correr

func _ready() -> void:
	timer_salto.wait_time = Globals.MIN_JUMP_TIME
	timer_salto.one_shot = true
	animation_tree.active = true
	root_playback.travel("Movimiento")
	AnimationFunctions.change_movimiento_state(movimiento_playback, idle_playback, "idle")

func _process(_delta: float) -> void:
	active_playback = ataque_playback if is_attacking else movimiento_playback
	var estado_actual = Globals.get_deepest_animation(animation_tree, active_playback)
	print(estado_actual)

func _physics_process(delta: float) -> void:
	MoveFunctions.aplicar_gravedad(self, delta, GRAVITY)
	MoveFunctions.mover_horizontal(self, SPEED, !ground_check.is_colliding())
	JumpFunctions.procesar_salto(self, "salto", timer_salto, JUMP_FORCE)
	move_and_slide()
	_update_animation_state()

func _update_animation_state() -> void:
	var new_state: String = ""

	if velocity.y < 0 and not ground_check.is_colliding():
		# El personaje está subiendo
		new_state = "jump"       # jump_start o jump_loop según la animación
	elif velocity.y > 0 and not ground_check.is_colliding():
		# Está cayendo
		new_state = "fall"       # fall_start o fall_loop
	elif velocity.x != 0:
		new_state = "walk"
	else:
		new_state = "idle"

	if new_state != last_movimiento_state:
		AnimationFunctions.change_movimiento_state(movimiento_playback, idle_playback, new_state)
		last_movimiento_state = new_state

func _on_jump_height_timer_timeout() -> void:
	if not saltando:
		JumpFunctions.corta_salto(self)
