class_name Hitbox
extends Area2D

@export var damage: float = 10.0
@export var knockback_force: float = 300.0
@export var base_knockback_vector: Vector2 = Vector2(1, -0.5)
var current_knockback_vector: Vector2

func _ready() -> void:
	# Capa 2: Hitboxes. Máscara 0: No detecta nada.
	collision_layer = 2
	collision_mask = 0
	monitoring = false # Desactivada por defecto
