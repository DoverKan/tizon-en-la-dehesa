# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/hud.gd
#  Qué es:   Marcador del nivel: vidas, tiempo, huesos, calcetines, puntos y jefe
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## Marcador y avisos del nivel (vidas del jefe y resumen al superar el nivel).
## La pausa la dibuja la pantalla principal, que es la que lleva su menú.

const VW := 384
const VH := 224
const ORO := Color("f2b632")
const CREMA := Color("fbf0da")
var nivel: Nivel = null
var _calcetin: Texture2D = preload("res://assets/sprites/calcetin.png")
var _hueso: Texture2D = preload("res://assets/sprites/hueso.png")
var _zoro: Texture2D = preload("res://assets/sprites/zorongollo.png")
var _disco: Texture2D = preload("res://assets/sprites/disco.png")


func _draw() -> void:
	if nivel == null:
		return
	var y := 6.0
	draw_rect(Rect2(0, 0, VW, 26), Color(0.12, 0.08, 0.04, 0.35))
	FuentePixel.dibujar(self, "TIZÓN", Vector2(8, y), ORO)
	FuentePixel.dibujar(self, "×" + str(Juego.vidas), Vector2(42, y))
	var cal: Array = Juego.calcetines[Juego.nivel]
	for i in 5:
		var x := 8.0 + i * 9.0
		if cal[i]:
			draw_texture_rect_region(_calcetin, Rect2(x, 15, 7, 9), Rect2(4, 0, 12, 15))
		else:
			draw_rect(Rect2(x + 1, 16, 3, 6), Color(1, 1, 1, 0.28))
			draw_rect(Rect2(x + 1, 21, 5, 2), Color(1, 1, 1, 0.28))
	FuentePixel.dibujar(self, "TIEMPO", Vector2(128, y), ORO)
	FuentePixel.dibujar(self, "%03d" % nivel.tiempo, Vector2(128, y + 10), Color("ff8a6a") if nivel.tiempo <= 100 else Color.WHITE)
	draw_texture_rect_region(_hueso, Rect2(205, y, 11, 6), Rect2(1, 4, 14, 8))
	FuentePixel.dibujar(self, "×%02d" % Juego.huesos, Vector2(218, y))
	FuentePixel.dibujar(self, "%07d" % Juego.puntos, Vector2(VW - 8, y), Color.WHITE, 1, FuentePixel.SOMBRA, FuentePixel.DERECHA)
	var j := nivel.jugador
	if j.poder == 2:
		draw_texture_rect_region(_zoro, Rect2(208, y + 9, 10, 10), Rect2(0, 0, 16, 16))
	elif j.poder == 3:
		draw_texture_rect(_disco, Rect2(208, y + 9, 10, 10), false)
	var lleno := mini(j.medidor, j.MEDIDOR_LLENO) / float(j.MEDIDOR_LLENO)
	draw_rect(Rect2(VW - 38, y + 12, 30, 3), Color(1, 1, 1, 0.18))
	var c := ORO
	if j.medidor >= j.MEDIDOR_LLENO and ((Engine.get_physics_frames() >> 2) & 1) != 0:
		c = Color.WHITE
	draw_rect(Rect2(VW - 38, y + 12, roundf(lleno * 30.0), 3), c)
	# vidas del jefe (Micifuz o la Urraca) durante la pelea
	var jefe = nivel.jefe
	if jefe != null and is_instance_valid(jefe) and jefe.vivo and jefe.estado != "espera":
		FuentePixel.dibujar(self, jefe.nombre, Vector2(VW / 2.0 + 40.0, y + 10.0), Color("ff9a6a"))
		for i in 3:
			draw_rect(Rect2(VW / 2.0 + 86.0 + i * 7.0, y + 10.0, 5, 7), Color("e8572a") if i < jefe.vidas else Color(1, 1, 1, 0.25))

	if nivel.estado in ["meta", "fin"] and not nivel.meta_info.is_empty():
		var m: Dictionary = nivel.meta_info
		if nivel.temporizador > 20 or m.fase != "andar":
			FuentePixel.dibujar(self, "¡NIVEL SUPERADO!", Vector2(VW / 2.0, 50), ORO, 2, Color("5a3510"), FuentePixel.CENTRO)
		if m.fase != "andar":
			var x := VW / 2.0 - 90.0
			draw_rect(Rect2(x - 8, 72, 196, 78), Color(0.08, 0.05, 0.02, 0.7))
			_fila("BONO DE TIEMPO", str(m.bono), x, 80, CREMA)
			_fila("HUESOS", str(Juego.huesos), x, 94, CREMA)
			var n := 0
			for k in cal:
				if k:
					n += 1
			_fila("CALCETINES", "%d/5" % n, x, 108, CREMA)
			_fila("PUNTOS", "%07d" % Juego.puntos, x, 126, ORO)
			if m.fase == "hecho":
				FuentePixel.dibujar(self, "PARTIDA GUARDADA", Vector2(VW / 2.0, 158), Color("9fe0ea"), 1, FuentePixel.SOMBRA, FuentePixel.CENTRO)
				if nivel.temporizador > 50 and ((Engine.get_physics_frames() >> 5) & 1) != 0:
					var texto := "PULSA SALTAR PARA SEGUIR" if Juego.nivel + 1 < Juego.NIVELES.size() else "PULSA SALTAR PARA TERMINAR"
					FuentePixel.dibujar(self, texto, Vector2(VW / 2.0, 172), Color.WHITE, 1, FuentePixel.SOMBRA, FuentePixel.CENTRO)


func _fila(a: String, b: String, x: float, y: float, c: Color) -> void:
	FuentePixel.dibujar(self, a, Vector2(x, y), c)
	FuentePixel.dibujar(self, b, Vector2(x + 180, y), c, 1, FuentePixel.SOMBRA, FuentePixel.DERECHA)
