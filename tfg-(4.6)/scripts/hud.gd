extends CanvasLayer
class_name HUD

# Referencias a los labels de porcentaje
@onready var p1_label: Label = $Container/Player1_UI/PorcentajeLabel
@onready var p2_label: Label = $Container/Player2_UI/PorcentajeLabel

# Referencias a los labels de nombres (opcional)
@onready var p1_name: Label = $Container/Player1_UI/NombreLabel
@onready var p2_name: Label = $Container/Player2_UI/NombreLabel

var jugador1: Character = null
var jugador2: Character = null

# Función para inicializar la HUD desde el script principal de tu partida
func inicializar_partida(p1: Character, p2: Character) -> void:
	jugador1 = p1
	jugador2 = p2
	
	# Conectamos las señales de ambos personajes a nuestras funciones de la HUD
	jugador1.damage_changed.connect(_on_player_1_damage_changed)
	jugador2.damage_changed.connect(_on_player_2_damage_changed)
	
	# Formateo inicial
	p1_label.text = "0.0%"
	p2_label.text = "0.0%"
	
	# Cambiar el color inicial a blanco
	p1_label.modulate = Color.WHITE
	p2_label.modulate = Color.WHITE

func _on_player_1_damage_changed(new_percentage: float, _char: Character) -> void:
	p1_label.text = "%.1f%%" % new_percentage
	_actualizar_color_porcentaje(p1_label, new_percentage)

func _on_player_2_damage_changed(new_percentage: float, _char: Character) -> void:
	p2_label.text = "%.1f%%" % new_percentage
	_actualizar_color_porcentaje(p2_label, new_percentage)

# Función cosmética: hace que el texto se vuelva más rojo cuanto más daño tenga
func _actualizar_color_porcentaje(label: Label, damage: float) -> void:
	# El daño máximo para el color rojo total será 150% (puedes cambiarlo)
	var ratio = clamp(damage / 150.0, 0.0, 1.0)
	
	# Interpolamos de Blanco (sin daño) a Rojo Intenso (mucho daño)
	label.modulate = Color.WHITE.lerp(Color.RED, ratio)
	
	# Efecto Smash: Un pequeño salto de tamaño al recibir golpe
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.05)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
