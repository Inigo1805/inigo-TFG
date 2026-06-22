class_name AttackFunctions
extends Node

# Maneja la lógica de activar el ataque o encadenar combos
static func ejecutar_ataque(player: CharacterBody2D, boton: String) -> void:
	# 1. Lógica de Combo
	if player.is_attacking and player.root_playback.get_current_node() == "AtaquesSuelo":
		var current_anim = player.ataque_suelo_playback.get_current_node()
		if current_anim in ["jab1", "jab2"]:
			player.animation_tree["parameters/AtaquesSuelo/conditions/quiere_combo"] = true
			player.combo_timer.start() 
			return 

	# 2. Determinar qué ataque toca
	var anim_name = determinar_ataque_especifico(player, boton)
	if anim_name == "": return

	# 3. Viajar al subárbol correspondiente
	if player.grounded:
		player.root_playback.travel("AtaquesSuelo")
		player.ataque_suelo_playback.travel(anim_name)
	else:
		player.root_playback.travel("AtaquesAire")
		player.ataque_aire_playback.travel(anim_name)

# Determina el nombre de la animación basado en inputs y estado
static func determinar_ataque_especifico(player: CharacterBody2D, boton: String) -> String:
	var in_x = Input.get_axis("izquierda", "derecha")
	var in_y = Input.get_axis("arriba", "abajo")
	
	# --- ATAQUES AÉREOS ---
	if not player.grounded:
		if in_y < -0.5: return "uair"
		if in_y > 0.5:  return "dair"
		if abs(in_x) > 0.5:
			# Compara el input con la dirección del sprite para Fair o Bair
			print(in_x)
			print(player.facing)
			if in_x > 0:
				if player.facing == "DER >":
					return "fair"
				else:
					return "bair"
			if in_x < 0:
				if player.facing == "< IZQ":
					return "fair"
				else:
					return "bair"
				
		return "nair"

	# --- ATAQUES EN SUELO ---
	if boton == "attack_a": # Jab y Tilts
		if in_y < -0.5: return "up_tilt"
		if in_y > 0.5:  return "down_tilt"
		if abs(in_x) > 0.5: return "side_tilt"
		return "jab1"
	else: # attack_b -> Strongs
		if in_y < -0.5: return "up_strong"
		if in_y > 0.5:  return "down_strong"
		return "side_strong"
