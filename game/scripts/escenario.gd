extends Node2D

@onready var respawn_position: Node2D = $RespawnPosition

func _ready() -> void:
	$Fondo/Fondo_2/Estrellas.play()
	$Fondo/Fondo_1/Planetas.play()


func _on_deadzone_body_entered(body: Node2D) -> void:
	if body is Character:
		body.deadzone_kill(respawn_position)
