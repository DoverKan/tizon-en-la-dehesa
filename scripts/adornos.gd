# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/adornos.gd
#  Qué es:   Huevos de pascua: gafas y bufanda del modo piloto, gorro del
#            cumpleaños de Tizón, la libélula y la puerta de la sala secreta
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Adornos
extends RefCounted
## Dibujos pequeños hechos píxel a píxel, iguales que en la versión web:
## - Modo piloto (código Konami): gafas de aviador, bufanda y una libélula que le sigue.
## - Cumpleaños de Tizón (27 de abril; nació en 2023): gorro de fiesta.
## - La puerta de la sala secreta de Badajoz 1-3 (con una huella como única pista).

## Posiciones medidas en los dibujos de Tizón mirando a la derecha, dentro de su casilla
## (16x16 pequeño, 24x24 grande; agachado, la cabeza baja 4 píxeles).
const ANCLAS := {
	"pequeno": {"ojo": Vector2i(12, 4), "arriba": 0, "collar": [8, 10, 6, 6]},
	"grande": {"ojo": Vector2i(18, 5), "arriba": 1, "collar": [13, 16, 9, 10]},
	"agachado": {"ojo": Vector2i(18, 9), "arriba": 5, "collar": [13, 16, 13, 14]},
}
const CUMPLE_DIA := 27
const CUMPLE_MES := 4
const NACIMIENTO := 2023
const GORRO := ["..Y..", "..R..", ".RA..", ".ARA.", "RARAR", "BBBBB"]
const COLOR_GORRO := {"Y": Color("ffd25e"), "R": Color("e85a8a"), "A": Color("2e6fb7"), "B": Color("fbf0da")}
## La libélula: 11x5, mirando a la derecha; dos dibujos para el aleteo
const LIBELULA := [
	[".eWe.eWe...", ".eWe.eWe...", "ttttttbbbo.", "...........", "..........."],
	["...........", "...........", "ttttttbbbo.", ".eWe.eWe...", ".eWe.eWe..."],
]
const COLOR_LIBELULA := {"W": Color("ffffff"), "e": Color("7ac3e6"), "t": Color("2aa198"), "b": Color("1d5f8a"), "o": Color("ffd25e")}

## Para las pruebas: hace como si hoy fuera el cumpleaños
static var forzar_cumple := false


static func es_cumple() -> bool:
	if forzar_cumple:
		return true
	var d := Time.get_date_dict_from_system()
	return d.day == CUMPLE_DIA and d.month == CUMPLE_MES


static func anios() -> int:
	return Time.get_date_dict_from_system().year - NACIMIENTO


static func _px(ci: CanvasItem, o: Vector2, x: int, y: int, c: Color) -> void:
	ci.draw_rect(Rect2(o.x + x, o.y + y, 1, 1), c)


## Dibuja los adornos sobre Tizón. `origen` es la esquina de arriba a la izquierda de su casilla.
static func dibujar(ci: CanvasItem, origen: Vector2, grande: bool, agachado: bool, cara: int,
		moviendose: bool, t: int, piloto: bool, cumple: bool) -> void:
	var a: Dictionary = ANCLAS["agachado" if (grande and agachado) else ("grande" if grande else "pequeno")]
	var w := 24 if grande else 16
	var p := func(x: int, y: int, c: Color) -> void:
		_px(ci, origen, x if cara > 0 else w - 1 - x, y, c)
	var ojo: Vector2i = a.ojo
	if piloto:
		# bufanda roja con una raya blanca y la punta al viento
		var col: Array = a.collar
		var rojo := Color("d9432f")
		for x in range(col[0], col[1] + 1):
			for y in range(col[2], col[3] + 1):
				p.call(x, y, rojo)
		if col[3] > col[2]:
			p.call(col[0] + 1, col[3], Color("fbf0da"))
		var ola := (t >> 3) & 1
		var cae := 0 if moviendose else 1
		var punta := [[1, 0], [2, ola * (1 - cae) + cae], [3, ola * (1 - cae) + cae * 2], [4, 1 - ola + cae * 2]]
		for i in punta.size():
			p.call(col[0] - punta[i][0], col[2] + punta[i][1], Color("fbf0da") if i == 3 else rojo)
		# gafas de aviador: la correa por la cabeza y el cristal sobre el ojo
		for x in range(ojo.x - 5, ojo.x - 1):
			p.call(x, ojo.y, Color("b5763a"))
		for x in range(ojo.x - 1, ojo.x + 2):
			for y in range(ojo.y - 1, ojo.y + 2):
				p.call(x, y, Color("e9a21f"))
		p.call(ojo.x, ojo.y, Color("7fd4e6"))
		p.call(ojo.x + 1, ojo.y - 1, Color.WHITE)
	if cumple:
		# gorro de fiesta de rayas con pompón
		var cx: int = ojo.x - 2
		var base: int = int(a.arriba) - 1
		for i in GORRO.size():
			var fila: String = GORRO[i]
			for j in fila.length():
				if fila[j] != ".":
					p.call(cx - 2 + j, base - (GORRO.size() - 1) + i, COLOR_GORRO[fila[j]])


## La libélula, con su esquina de arriba a la izquierda en `pos`
static func dibujar_libelula(ci: CanvasItem, pos: Vector2, t: int, cara: int) -> void:
	var f: Array = LIBELULA[(t >> 2) & 1]
	for y in f.size():
		var fila: String = f[y]
		for x in fila.length():
			if fila[x] != ".":
				_px(ci, pos, x if cara > 0 else 10 - x, y, COLOR_LIBELULA[fila[x]])


## Portal de madera de 2 casillas de ancho y 3 de alto (esquina de arriba a la izquierda en x, y)
static func dibujar_puerta(ci: CanvasItem, x: float, y: float) -> void:
	var r := func(rx: float, ry: float, w: float, h: float, c: String) -> void:
		ci.draw_rect(Rect2(x + rx, y + ry, w, h), Color(c))
	r.call(0, 2, 32, 46, "b9ab92")          # marco de granito
	r.call(2, 0, 28, 2, "b9ab92")
	r.call(2, 46, 28, 2, "8c7e66")          # escalón
	r.call(4, 6, 24, 40, "6b3a1e")          # las dos hojas
	r.call(6, 4, 20, 2, "6b3a1e")
	for k in 6:
		r.call(7 + k * 4, 6, 1, 40, "4f2a14")
	r.call(15, 5, 2, 41, "3a1e0e")
	r.call(4, 22, 24, 1, "4f2a14")
	r.call(12, 26, 2, 2, "e9a21f")          # aldabas
	r.call(18, 26, 2, 2, "e9a21f")
	# huella: cuatro deditos y la almohadilla
	var c := "e9d3a0"
	r.call(20, 12, 1, 1, c)
	r.call(22, 11, 1, 1, c)
	r.call(24, 12, 1, 1, c)
	r.call(25, 14, 1, 1, c)
	r.call(21, 14, 3, 2, c)
	r.call(22, 16, 1, 1, c)
