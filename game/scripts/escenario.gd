extends Node2D

@onready var respawn_position: Node2D = $RespawnPosition

func _ready() -> void:
	$Fondo/Fondo_2/Estrellas.play()
	$Fondo/Fondo_1/Planetas.play()


func _on_deadzone_body_entered(body: Node2D) -> void:
	if body.has_method("deadzone_kill"):
		# Usamos call_deferred para que se ejecute fuera del ciclo de físicas actual
		body.call_deferred("deadzone_kill", respawn_position)
