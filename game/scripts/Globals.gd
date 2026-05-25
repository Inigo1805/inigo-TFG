extends Node

# Constantes de personaje
const PLAYER_SPEED:int = 300
const PLAYER_JUMP_FORCE:int = 800

# Constantes globales (reglas)
const GRAVITY:int = 1100
const MIN_JUMP_TIME:float = .05
const MIN_COMBO_TIMER:float = .3
const DOUBLE_TAP_DELAY: float = 0.25 # Tiempo máximo entre clics
const RUN_GRACE_PERIOD: float = 0.15 # Tiempo para cambiar de dirección sin dejar de correr
const PUSH_FORCE = 30

func get_deepest_animation(animation_tree: AnimationTree, playback: AnimationNodeStateMachinePlayback, path: String = "") -> String:
	if playback == null:
		return path
	
	var current_node = playback.get_current_node()
	if current_node == "": 
		return path
	
	# Construimos la ruta hacia el nombre del nodo para mostrarlo (ej: Movimiento/idle/calm)
	var display_path = current_node if path == "" else path + "/" + current_node
	
	# Construimos la ruta técnica para buscar el siguiente playback en los parámetros
	# Godot usa "parameters/NombreDelNodo/playback"
	var internal_path = "parameters/" + display_path + "/playback"
	
	# Intentamos obtener un playback anidado en esa ruta
	var nested_playback = animation_tree.get(internal_path)
	
	if nested_playback is AnimationNodeStateMachinePlayback:
		# Si existe, seguimos bajando recursivamente
		return get_deepest_animation(animation_tree, nested_playback, display_path)
	
	# Si no hay más hijos, hemos llegado a la animación final (AnimationNodeAnimation)
	return display_path

# Devuelve un array de acciones activas en este frame
static func get_active_actions(actions: Array) -> Array:
	var active: Array = []
	for action in actions:
		if Input.is_action_pressed(action):
			active.append(action)
	return active
