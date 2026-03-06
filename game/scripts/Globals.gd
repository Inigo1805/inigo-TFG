extends Node

# Constantes de personaje
const PLAYER_SPEED:int = 300
const PLAYER_JUMP_FORCE:int = 700

# Constantes globales (reglas)
const GRAVITY:int = 1100
const MIN_JUMP_TIME:float = .05

func get_deepest_animation(animation_tree: AnimationTree, playback_node: AnimationNodeStateMachinePlayback, path_so_far: String = "") -> String:
	if playback_node == null:
		return ""

	var current_state: String = playback_node.get_current_node()
	var full_path: String = current_state if path_so_far == "" else path_so_far + "/" + current_state

	# Obtener el nodo actual
	var node: AnimationNode = animation_tree.get("parameters/" + current_state)
	if node == null:
		return full_path  # nodo no encontrado, devolvemos lo que tenemos

	# Si es otra máquina anidada, buscar su playback
	if node is AnimationNodeStateMachine:
		var nested_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/" + current_state + "/playback")
		if nested_playback != null:
			# llamada recursiva
			return get_deepest_animation(animation_tree, nested_playback, full_path)

	# Si no hay máquina anidada, devolvemos la ruta completa
	return full_path

# Devuelve un array de acciones activas en este frame
static func get_active_actions(actions: Array) -> Array:
	var active: Array = []
	for action in actions:
		if Input.is_action_pressed(action):
			active.append(action)
	return active
