class_name Hurtbox
extends Area2D

func _ready() -> void:
	# Capa 0: No es una hitbox. Máscara 2: Detecta Hitboxes.
	collision_layer = 1
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func _on_area_entered(hitbox: Area2D) -> void:
	if not hitbox is Hitbox or hitbox.owner == self.owner:
		return
		
	var victima = self.owner # El Character que tiene esta Hurtbox
	var atacante = hitbox.owner # El Character que lanzó el ataque
	# --- CASO A: BLOQUEO ---
	if victima.is_blocking:
		# 1. Feedback visual para la víctima
		victima.velocity = hitbox.current_knockback_vector * (hitbox.knockback_force * 0.3)
		_efecto_visual_bloqueo(victima)
		
		# 2. CASTIGO AL ATACANTE (Añadir un pequeño retroceso o stun)
		if atacante.has_method("aplicar_block_stun"):
			# Mandamos al atacante hacia atrás por haber sido bloqueado
			var dir_retroceso = -hitbox.current_knockback_vector 
			atacante.aplicar_block_stun(dir_retroceso, 200.0)
			
		print("¡Ataque bloqueado y contraatacado!")
		return # IMPORTANTE: Evitamos que se llame a take_damage

	# --- CASO B: DAÑO NORMAL ---
	if victima.has_method("take_damage"):
		victima.take_damage(hitbox.damage, hitbox.current_knockback_vector, hitbox.knockback_force)
		
func _efecto_visual_bloqueo(obj):
	var tween = create_tween()
	tween.tween_property(obj.sprite, "modulate", Color.CYAN, 0.05)
	tween.tween_property(obj.sprite, "modulate", Color.WHITE, 0.05)
