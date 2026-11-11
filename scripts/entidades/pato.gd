# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/pato.gd
#  Qué es:   Pato de la caseta de tiro de la Feria
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Pato de la caseta de tiro: va y viene por el mostrador. Se puede pisar.

const RECORRIDO := 64.0
var x0 := 0.0


func _ready() -> void:
	tipo = "pato"
	ancho = 14.0
	alto = 13.0
	x0 = position.x
	dir = -1


func paso(_delta: float) -> void:
	t += 1
	position.x += dir * 0.7
	if position.x < x0:
		position.x = x0
		dir = 1
	if position.x > x0 + RECORRIDO:
		position.x = x0 + RECORRIDO
		dir = -1
	sprite.flip_h = dir > 0
