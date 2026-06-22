# AnimationFunctions.gd
extends Node
class_name AnimationFunctions

static func change_movimiento_state(mov_playback, idle_playback, name: String) -> void:
	if mov_playback.get_current_node() == name:
		return
	mov_playback.travel(name)
	if name == "idle":
		choose_random_idle(idle_playback)

static func choose_random_idle(idle_playback) -> void:
	var r = randi_range(1, 3)
	idle_playback.travel("idle" + str(r))
