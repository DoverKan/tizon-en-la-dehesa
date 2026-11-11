# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/fondo.gd
#  Qué es:   Fondos con paralaje de cada tema (dehesa, Badajoz, río, feria, cielo, Mérida...)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## Fondo con paralaje: cielo, nubes, lejanía y primer término de cada tema (la dehesa,
## Badajoz, el Guadiana, los jardines del MEIAC, la feria, el cielo y Mérida), o la
## cueva, el museo o los muros de la Alcazaba. Se dibuja en una capa por detrás del
## nivel a partir de la posición de la cámara.

const VW := 384
const VH := 224
const COLORES_FUEGOS := ["ff5a5a", "ffd23f", "5ad0ff", "7aff7a", "ff8ae8"]
var cam := Vector2.ZERO
var tema := "dehesa"
var zona := Rect2(0, 0, 384, 256)
var _tex := {}
static var _suelo := {}


func _tex_de(nombre: String) -> Texture2D:
	if not _tex.has(nombre):
		_tex[nombre] = load("res://assets/fondos/%s.png" % nombre)
	return _tex[nombre]


func _color_suelo(t: String) -> Color:
	if _suelo.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/datos.json"))
		_suelo = d.suelo_fondo
	return Color(_suelo.get(t, "93b25b"))


func _capa(tex: Texture2D, factor: float, y: float) -> void:
	var w := tex.get_width()
	var x := -fposmod(floorf(cam.x * factor), w)
	while x < VW:
		draw_texture(tex, Vector2(x, roundf(y)))
		x += w


func _draw() -> void:
	var cy := cam.y - zona.position.y          # cámara dentro de la zona
	var max_y := zona.size.y - VH
	match tema:
		"castillo":
			# muros de la Alcazaba y, al fondo, el agua del foso
			_capa(_tex_de("castillo"), 0.3, 0.0)
			var wy := roundf(zona.size.y - 42.0 - cy)
			if wy < VH:
				draw_rect(Rect2(0, wy, VW, VH - wy), Color("163050"))
				var x := -((Engine.get_physics_frames() >> 1) % 16)
				while x < VW:
					draw_rect(Rect2(x, wy + ((x >> 4) & 1), 7, 1), Color("3d6b94"))
					x += 16
			return
		"museo":
			var tex := _tex_de("museo")
			var ox := -fposmod(floorf(cam.x * 0.4), tex.get_width())
			var oy := -fposmod(floorf(cy * 0.4), tex.get_height())
			var x := ox
			while x < VW:
				var y := oy
				while y < VH:
					draw_texture(tex, Vector2(x, y))
					y += tex.get_height()
				x += tex.get_width()
			return
		"cueva", "gruta":
			_capa(_tex_de("cueva"), 0.35, 0.0)
			return
	var t := tema if tema in ["dehesa", "atardecer", "ciudad", "rio", "jardin", "feria", "cielo", "romano"] else "dehesa"
	draw_texture(_tex_de(t + "_cielo"), Vector2.ZERO)
	if t == "feria":
		_fuegos()
	_capa(_tex_de(t + "_nubes"), 0.08, 4.0 + (max_y - cy) * 0.05)
	_capa(_tex_de(t + "_lejos"), 0.22, VH - 178.0 + (max_y - cy) * 0.15)
	_capa(_tex_de(t + "_medio"), 0.45, VH - 152.0 + (max_y - cy) * 0.3)
	var abajo := roundf(VH - 152.0 + 110.0 + (max_y - cy) * 0.3) - 1.0
	if abajo < VH:
		draw_rect(Rect2(0, abajo, VW, VH - abajo), _color_suelo(t))


## Fuegos artificiales sobre la Feria de San Juan
func _fuegos() -> void:
	var g := Engine.get_physics_frames()
	for k in 3:
		var per := 150
		var t := (g + k * 53) % per
		var n := floori((g + k * 53) / float(per))
		var r := _aleatorios(n * 7 + k, 2)
		var x: float = 40.0 + r[0] * 300.0
		var y: float = 30.0 + r[1] * 60.0
		var col := Color(COLORES_FUEGOS[(n + k) % COLORES_FUEGOS.size()])
		if t < 30:
			draw_rect(Rect2(roundf(x), roundf(y + (30 - t) * 2.5), 1, 3), Color("ffe9a0"))
			continue
		var ph := (t - 30) / 70.0
		if ph > 1.0:
			continue
		col.a = 1.0 - ph * 0.8
		for i in 14:
			var a := i / 14.0 * TAU
			var rr := 4.0 + ph * 32.0
			draw_rect(Rect2(roundf(x + cos(a) * rr), roundf(y + sin(a) * rr + ph * ph * 10.0), 2, 2), col)


## Los mismos números pseudoaleatorios que la versión web (mulberry32)
static func _aleatorios(semilla: int, n: int) -> Array:
	var a := semilla & 0xFFFFFFFF
	var r := []
	for i in n:
		a = (a + 0x6D2B79F5) & 0xFFFFFFFF
		var t := a
		t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
		t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF)) & 0xFFFFFFFF
		r.append(float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0)
	return r
