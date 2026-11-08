# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/barra_fuego.gd
#  Qué es:   Barra de fuego de la Alcazaba
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Barra de fuego de la Alcazaba: cinco bolas que giran alrededor de un bloque.
## No se puede pisar ni apagar: hay que pasar cuando no apunta hacia ti.
## El origen es el centro del bloque sobre el que gira.

const BOLAS := 5
@export var angulo := 0.0
@export var giro := 0.034    # radianes por fotograma; negativo, gira al revés
var _tex: Texture2D = preload("res://assets/sprites/bola_fuego.png")


func _ready() -> void:
	tipo = "barra_fuego"
	ancho = 6.0
	alto = 6.0
	activo = true


func caja() -> Rect2:
	return Rect2(global_position - Vector2(3, 3), Vector2(6, 6))


func bola(i: int) -> Vector2:
	return global_position + Vector2(cos(angulo), sin(angulo)) * i * 8.0


func toca(r: Rect2) -> bool:
	for i in range(1, BOLAS + 1):
		if r.intersects(Rect2(bola(i) - Vector2(3, 3), Vector2(6, 6))):
			return true
	return false


func paso(_delta: float) -> void:
	t += 1
	angulo += giro
	queue_redraw()


func _draw() -> void:
	var f := (t >> 2) & 1
	for i in range(1, BOLAS + 1):
		var p := Vector2(cos(angulo), sin(angulo)) * i * 8.0 - Vector2(4, 4)
		draw_texture_rect_region(_tex, Rect2(p.round(), Vector2(8, 8)), Rect2(f * 8, 0, 8, 8))
