# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/meta.gd
#  Qué es:   Meta: los postes con el nido de cigüeña
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends Node2D
## Meta: dos postes con el nido de cigüeña y una rama que sube y baja.
## Si Tizón toca la rama, más puntos cuanto más alta esté. El origen es el
## pie del poste de atrás.

const ALTO := 118.0
const TEX_CIGUENA := preload("res://assets/sprites/ciguena.png")

var nivel: Nivel = null
var vivo := true
var activo := true
var tipo := "meta"
var barra_y := -100.0
var barra_v := 1.0
var barra_puesta := true
var t := 0


func paso(_delta: float) -> void:
	t += 1
	if barra_puesta:
		barra_y += barra_v
		if barra_y < -112.0:
			barra_y = -112.0
			barra_v = 1.0
		if barra_y > -18.0:
			barra_y = -18.0
			barra_v = -1.0
	queue_redraw()


func caja_barra() -> Rect2:
	return Rect2(global_position.x + 6.0, global_position.y + barra_y, 48.0, 6.0)


func _poste(x: float) -> void:
	draw_rect(Rect2(x, -ALTO, 6, ALTO), Color("3b2414"))
	draw_rect(Rect2(x + 1, -ALTO, 4, ALTO), Color("8b5a2b"))
	draw_rect(Rect2(x + 2, -ALTO, 1, ALTO), Color("b07a40"))


func _draw() -> void:
	_poste(0.0)
	var ny := -ALTO
	draw_rect(Rect2(-11, ny - 9, 28, 3), Color("4f3a1f"))
	draw_rect(Rect2(-9, ny - 6, 24, 3), Color("4f3a1f"))
	draw_rect(Rect2(-6, ny - 3, 18, 3), Color("4f3a1f"))
	draw_rect(Rect2(-10, ny - 8, 26, 1), Color("9a7442"))
	draw_rect(Rect2(-8, ny - 5, 22, 1), Color("7a5a32"))
	draw_rect(Rect2(-5, ny - 2, 16, 1), Color("7a5a32"))
	var marco := 1 if (t >> 5) % 4 == 0 else 0
	draw_texture_rect_region(TEX_CIGUENA, Rect2(-6, ny - 24, 16, 16), Rect2(marco * 16, 0, 16, 16))
	_poste(48.0)
	draw_rect(Rect2(47, -ALTO - 2, 8, 3), Color("3b2414"))
	if barra_puesta:
		dibujar_rama(self, Vector2(6, barra_y))


static func dibujar_rama(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_rect(Rect2(p.x, p.y + 2, 46, 3), Color("4a2a12"))
	ci.draw_rect(Rect2(p.x, p.y + 2, 46, 1), Color("9a6a3a"))
	for i in 5:
		var oy := 4.0 if i % 2 == 1 else -1.0
		ci.draw_rect(Rect2(p.x + 3 + i * 9, p.y + oy, 5, 3), Color("2f5a1e"))
		ci.draw_rect(Rect2(p.x + 4 + i * 9, p.y + oy, 3, 2), Color("6aa438"))
