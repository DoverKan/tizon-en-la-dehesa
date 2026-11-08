# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/cafe.gd
#  Qué es:   The Cereal Cafe, meta del nivel Badajoz 1-3
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## The Cereal Cafe, la meta del nivel 1-3: al terminar, Tizón entra por la puerta.
## El origen es la esquina de abajo a la izquierda de la fachada (144 x 112).

@export var puerta_x := 72.0     # x de la puerta, en coordenadas del nivel


func _ready() -> void:
	tipo = "cafe"
	ancho = 144.0
	alto = 112.0
	activo = true
	z_index = -1


func caja() -> Rect2:
	return Rect2(global_position.x, global_position.y - alto, ancho, alto)


func paso(_delta: float) -> void:
	pass
