# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/efectos.gd
#  Qué es:   Partículas, puntos que flotan, bloques que rebotan y bocadillos de los vecinos
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## Partículas y textos de puntos que flotan, bloques que rebotan al golpearlos,
## los destellos de las encinas con pasadizo y los bocadillos de los vecinos.

var nivel: Nivel = null
var _losetas: Texture2D = preload("res://assets/tiles/losetas.png")


func _draw() -> void:
	if nivel == null:
		return
	_pistas_pasadizo()
	for g in nivel.golpes:
		var off := roundf(sin(g.t / 10.0 * PI) * 3.0) if g.abajo else -roundf(sin(g.t / 10.0 * PI) * 5.0)
		draw_texture_rect_region(_losetas, Rect2(Vector2(g.celda * 16) + Vector2(0, off), Vector2(16, 16)), Rect2(Vector2(g.atlas * 16), Vector2(16, 16)))
	for q in nivel.particulas:
		var p: Vector2 = q.p.round()
		match q.k:
			"trozo":
				draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color("4a2a12"))
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("c27a3e") if ((q.t >> 2) & 1) != 0 else Color("e3a468"))
			"humo":
				var r: float = 3.0 + q.t / 3.0
				var c := Color(1, 1, 1, 1.0 - float(q.t) / q.vida)
				for o in [Vector2(-r, 0), Vector2(r, 0), Vector2(0, -r), Vector2(0, r)]:
					draw_rect(Rect2((p + o - Vector2(3, 3)).round(), Vector2(6, 6)), c)
			"chispa":
				if q.t >= 0:
					var s: int = (q.t >> 1) if q.t < 7 else ((14 - q.t) >> 1)
					draw_rect(Rect2(p.x - s, p.y, s * 2 + 1, 1), Color("fff6cc"))
					draw_rect(Rect2(p.x, p.y - s, 1, s * 2 + 1), Color("fff6cc"))
			"polvo":
				draw_rect(Rect2(p.x - 2 + (q.t >> 2), p.y - (q.t >> 2), 3, 3), Color(0.94, 0.9, 0.82, 0.8))
			"texto":
				FuentePixel.dibujar(self, q.texto, p)
			"rama":
				preload("res://scripts/entidades/meta.gd").dibujar_rama(self, p)
			"gota":
				draw_rect(Rect2(p, Vector2(2, 2)), q.get("color", Color("a8d4ee")))
			"piedrecita":
				draw_rect(Rect2(p, Vector2(3, 3)), Color("8c7a66"))
			"roca":
				draw_texture_rect_region(_losetas, Rect2(p, Vector2(16, 16)), Rect2(12 * 16, 41 * 16, 16, 16))
			"pluma":
				draw_rect(Rect2(p, Vector2(2, 1)), Color("e6e8ee"))
			"corazon":
				if q.t >= 0:
					_corazon(self, p)
	_bocadillos()


## Corazón de 7 x 6 píxeles (los vecinos se alegran de ver a Tizón)
static func _corazon(ci: CanvasItem, p: Vector2) -> void:
	var c := Color("e8577a")
	ci.draw_rect(Rect2(p.x, p.y, 2, 1), c)
	ci.draw_rect(Rect2(p.x + 3, p.y, 2, 1), c)
	ci.draw_rect(Rect2(p.x - 1, p.y + 1, 7, 2), c)
	ci.draw_rect(Rect2(p.x, p.y + 3, 5, 1), c)
	ci.draw_rect(Rect2(p.x + 1, p.y + 4, 3, 1), c)
	ci.draw_rect(Rect2(p.x + 2, p.y + 5, 1, 1), c)
	ci.draw_rect(Rect2(p.x, p.y + 1, 1, 1), Color("ffb0c4"))


## Bocadillos de diálogo encima de los vecinos y de Eduardo.
func _bocadillos() -> void:
	for e in nivel.entidades.get_children():
		if not e.has_method("texto_bocadillo") or e.is_queued_for_deletion():
			continue
		var texto: String = e.texto_bocadillo()
		if texto == "":
			continue
		var cx: float = e.global_position.x
		var arriba: float = e.global_position.y - 24.0
		var w := FuentePixel.ancho(texto) + 8.0
		var h := 13.0
		var x := roundf(clampf(cx - w / 2.0, nivel.cam.x + 2.0, nivel.cam.x + 384.0 - w - 2.0))
		var y := roundf(arriba - h - 5.0)
		var tx := clampf(roundf(cx), x + 3.0, x + w - 5.0)
		var borde := Color("2b1a10")
		var papel := Color("fffdf4")
		draw_rect(Rect2(x - 1, y, w + 2, h), borde)
		draw_rect(Rect2(x, y - 1, w, h + 2), borde)
		draw_rect(Rect2(x, y, w, h), papel)
		draw_rect(Rect2(tx - 1, y + h + 1, 4, 1), borde)
		draw_rect(Rect2(tx, y + h + 2, 2, 1), borde)
		draw_rect(Rect2(tx, y + h + 3, 1, 1), borde)
		draw_rect(Rect2(tx, y + h, 2, 1), papel)
		draw_rect(Rect2(tx, y + h + 1, 2, 1), papel)
		draw_rect(Rect2(tx, y + h + 2, 1, 1), papel)
		FuentePixel.dibujar(self, texto, Vector2(x + 4.0, y + 3.0), borde, 1, FuentePixel.SIN_SOMBRA)


## Las encinas con pasadizo echan destellos por el agujero y enseñan una flecha
## cuando Tizón está cerca (para entrar, ponte encima y pulsa abajo).
func _pistas_pasadizo() -> void:
	var f := Engine.get_physics_frames()
	var cj: Rect2 = nivel.jugador.caja()
	for e in nivel.entidades.get_children():
		if e.get("numero") == null or e.is_queued_for_deletion() or nivel._otro_pasadizo(e) == null:
			continue
		var cx: float = e.global_position.x
		var top: float = e.global_position.y
		if cx < nivel.cam.x - 32.0 or cx > nivel.cam.x + 384.0 + 32.0:
			continue
		var tx := int((cx - 16.0) / 16.0)
		for k in 3:
			var ph := (f + k * 17 + tx * 7) % 48
			var sx := roundf(cx - 7.0 + ((tx * 13 + k * 5 + floori((f + k * 17) / 48.0) * 3) % 14))
			var sy := roundf(top + 3.0 - ph * 0.5)
			if ph < 36:
				draw_rect(Rect2(sx, sy, 1, 1), Color("fff6cc"))
				if ph < 8:
					draw_rect(Rect2(sx - 1, sy, 3, 1), Color("ffe08a"))
					draw_rect(Rect2(sx, sy - 1, 1, 3), Color("ffe08a"))
		var cerca := absf(nivel.jugador.global_position.x - cx) < 64.0 and cj.end.y > top - 72.0 and cj.position.y < top + 24.0
		if cerca and nivel.estado == "jugando" and ((f >> 4) & 1) != 0:
			var bote := roundf(sin(f * 0.15) * 2.0)
			FuentePixel.dibujar(self, "▼", Vector2(roundf(cx - 2.0), roundf(top - 34.0 + bote)), Color("ffd25e"))
