extends CharacterBody2D

@onready var ground_check = $RayCast2D
@onready var timer_salto = $JumpHeightTimer

const SPEED: = Globals.PLAYER_SPEED
const JUMP_FORCE := Globals.PLAYUER_JUMP_FORCE
const GRAVITY := Globals.GRAVITY
var saltando:bool = false # No es lo mismo que estar en el aire

func _ready() -> void:
	timer_salto.wait_time = Globals.MIN_JUMP_TIME
	timer_salto.one_shot = true

func _process(_delta: float) -> void:
	pass #TODO print estados para la maquina de estados

func corta_salto() -> void:
	saltando = false
	if velocity.y < 0: # Corte de salto si aún sube el personaje
		velocity.y = velocity.y * 0.15 # Corte no abrupto

func _physics_process(delta):
	if not ground_check.is_colliding():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	var input_dir = Input.get_axis("izquierda", "derecha")
	velocity.x = input_dir * SPEED

	if Input.is_action_pressed("salto") and ground_check.is_colliding():
		timer_salto.start() # Empezamos el timer de salto mínimo
		velocity.y = -JUMP_FORCE # Aplicamos fuerza de salto
		saltando = true # El personaje está saltando
		
	if !Input.is_action_pressed("salto") and saltando:
		saltando = false # El jugador no tiene intención de saltar
		# Si el salto era muy corto lo cortaremos en el timeout
		# si no (ya ha habido timeout), lo cortamos ahora 
		if timer_salto.is_stopped(): 
			corta_salto()

	move_and_slide() # Aplicar el vector de velocity cada delta

# Si ocurre el timeout y el jugador ya dejó de pulsar
# el salto, se deja de saltar ahora (salto mínimo)
func _on_jump_height_timer_timeout() -> void:
	if !saltando: # Cortamos el salto
		corta_salto()
