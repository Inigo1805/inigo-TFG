extends Camera2D
class_name CameraBrawler

# Config en el inspector
@export_group("Objetivos")
@export var personaje_1: CharacterBody2D
@export var personaje_2: CharacterBody2D

@export_group("Límites de Movimiento")
@export var limite_izquierdo: float = -1000.0
@export var limite_derecho: float = 1000.0
@export var limite_superior: float = -600.0
@export var limite_inferior: float = 600.0

@export_group("Configuración del Zoom")
@export var zoom_minimo: float = 0.6      # Zoom cuando están muy lejos (Cámara alejada)
@export var zoom_maximo: float = 1.3      # Zoom cuando están pegados (Cámara muy cerca)
@export var margen_distancia: float = 400.0 # Distancia en píxeles a partir de la cual la cámara empieza a alejarse

@export_group("Suavizado (Smoothing)")
@export var velocidad_movimiento: float = 8.0 # Qué tan rápido sigue la cámara al punto medio
@export var velocidad_zoom: float = 4.0       # Qué tan suave es la transición del zoom

func _ready() -> void:
	# Nos aseguramos de que la cámara esté activa
	make_current()

func _physics_process(delta: float) -> void:
	# Seguridad: Si falta alguno de los personajes, no hacemos nada
	if not personaje_1 or not personaje_2:
		return

	var punto_medio: Vector2 = (personaje_1.global_position + personaje_2.global_position) / 2.0
	
	# Aplicar los límites de movimiento (Clamping) para que la cámara no muestre el vacío del mapa
	punto_medio.x = clamp(punto_medio.x, limite_izquierdo, limite_derecho)
	punto_medio.y = clamp(punto_medio.y, limite_superior, limite_inferior)

	# Mover la cámara suavemente hacia el punto medio usando interpolación (lerp)
	global_position = global_position.lerp(punto_medio, velocidad_movimiento * delta)

	# Calcular zoom dinamico
	# Obtenemos la distancia absoluta en el eje X e Y entre ambos personajes
	var distancia_x: float = abs(personaje_1.global_position.x - personaje_2.global_position.x)
	var distancia_y: float = abs(personaje_1.global_position.y - personaje_2.global_position.y)
	
	# Usamos la distancia mayor como referencia para que nadie se salga de la pantalla
	var distancia_maxima: float = max(distancia_x, distancia_y)
	
	# Calculamos el factor de zoom ideal en base a la distancia
	var zoom_objetivo_factor: float = margen_distancia / max(distancia_maxima, 1.0)
	
	# Limitamos el factor para que no supere nuestros límites configurados
	zoom_objetivo_factor = clamp(zoom_objetivo_factor, zoom_minimo, zoom_maximo)
	
	# Creamos el Vector2 del zoom, manteniendo el aspect ratio
	var zoom_objetivo := Vector2(zoom_objetivo_factor, zoom_objetivo_factor)
	
	# Aplicar el cambio de zoom de forma paulatina y suave
	zoom = zoom.lerp(zoom_objetivo, velocidad_zoom * delta)
