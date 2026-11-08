# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/luciernaga.gd
#  Qué es:   Luciérnaga de las cuevas: da luz y sigue a Tizón
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Luciérnaga de las cuevas de Fuentes de León: revolotea dando luz. Si Tizón la
## coge, le sigue dando vueltas y la luz alrededor de Tizón crece.
## El origen es el centro de la luciérnaga.

@export var fase := 0
var origen := Vector2.ZERO
var cogida := false
var hueco := 0


func _ready() -> void:
	tipo = "luciernaga"
	ancho = 4.0
	alto = 4.0
	activo = true
	origen = position


func caja() -> Rect2:
	return Rect2(global_position - Vector2(2, 2), Vector2(4, 4))


func caja_coger() -> Rect2:
	return Rect2(global_position - Vector2(7, 7), Vector2(14, 14))


func paso(_delta: float) -> void:
	t += 1
	if not cogida:
		position = origen + Vector2(sin(t * 0.03 + fase) * 8.0, sin(t * 0.05 + fase) * 5.0)
	else:
		var j: Tizon = nivel.jugador
		var cj := j.caja()
		var a := t * 0.06 + hueco * PI / 2.0
		position = Vector2(cj.get_center().x + cos(a) * 16.0, cj.position.y + 4.0 + sin(a) * 9.0)
	queue_redraw()


func _draw() -> void:
	if cogida or ((t >> 3) % 5) != 0:
		draw_rect(Rect2(-2, -2, 3, 3), Color("d8ff6a"))
		draw_rect(Rect2(-1, -1, 1, 1), Color.WHITE)
