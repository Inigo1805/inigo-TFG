extends CanvasLayer
class_name HUD

# Referencias existentes
@onready var p1_label: Label = $Container/Player1_UI/PorcentajeLabel
@onready var p2_label: Label = $Container/Player2_UI/PorcentajeLabel
@onready var p1_vidas_label: Label = $Container/Player1_UI/VidasLabel
@onready var p2_vidas_label: Label = $Container/Player2_UI/VidasLabel
@onready var p1_name: Label = $Container/Player1_UI/NombreLabel
@onready var p2_name: Label = $Container/Player2_UI/NombreLabel

# Referencias a la interfaz de Game Over
@onready var game_over_panel: ColorRect = $GameOverPanel
@onready var winner_text_label: Label = $GameOverPanel/VBoxContainer/WinnerTextLabel

var jugador1: Character = null
var jugador2: Character = null

var vidas_p1: int = 3
var vidas_p2: int = 3

func inicializar_partida(p1: Character, p2: Character) -> void:
	jugador1 = p1
	jugador2 = p2
	
	jugador1.damage_changed.connect(_on_player_1_damage_changed)
	jugador2.damage_changed.connect(_on_player_2_damage_changed)
	
	jugador1.muerto.connect(_on_player_1_muerto)
	jugador2.muerto.connect(_on_player_2_muerto)
	
	p1_label.text = "0.0%"
	p2_label.text = "0.0%"
	p1_label.modulate = Color.WHITE
	p2_label.modulate = Color.WHITE
	
	# Aseguramos que el panel inicie oculto
	game_over_panel.visible = false
	_actualizar_texto_vidas()

func _on_player_1_damage_changed(new_percentage: float, _char: Character) -> void:
	p1_label.text = "%.1f%%" % new_percentage
	_actualizar_color_porcentaje(p1_label, new_percentage)

func _on_player_2_damage_changed(new_percentage: float, _char: Character) -> void:
	p2_label.text = "%.1f%%" % new_percentage
	_actualizar_color_porcentaje(p2_label, new_percentage)

func _on_player_1_muerto() -> void:
	vidas_p1 = max(0, vidas_p1 - 1)
	_actualizar_texto_vidas()

func _on_player_2_muerto() -> void:
	vidas_p2 = max(0, vidas_p2 - 1)
	_actualizar_texto_vidas()

func _actualizar_texto_vidas() -> void:
	p1_vidas_label.text = "Vidas: %d" % vidas_p1
	p2_vidas_label.text = "Vidas: %d" % vidas_p2

func _actualizar_color_porcentaje(label: Label, damage: float) -> void:
	var ratio = clamp(damage / 150.0, 0.0, 1.0)
	label.modulate = Color.WHITE.lerp(Color.RED, ratio)
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.05)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

# Solo actualiza el texto del ganador y hace visible la pantalla
func mostrar_game_over(mensaje_ganador: String) -> void:
	winner_text_label.text = mensaje_ganador
	game_over_panel.visible = true
