# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/fuente_pixel.gd
#  Qué es:   Fuente de píxeles 5x7 del juego
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name FuentePixel
extends RefCounted
## Texto con la fuente de píxeles 5x7 del juego (los mismos caracteres que la web).

const CARACTERES := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZÑ .,!¡?¿:-+×/·'▼<→←>()"
const ACENTOS := {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U"}
const SOMBRA := Color("2b1a10")
const SIN_SOMBRA := Color(0, 0, 0, 0)
enum { IZQUIERDA, CENTRO, DERECHA }

static var _textura: Texture2D = null


static func textura() -> Texture2D:
	if _textura == null:
		_textura = load("res://assets/fuente/fuente.png")
	return _textura


static func ancho(texto: String, escala: int = 1) -> int:
	return texto.length() * 6 * escala - escala


static func dibujar(ci: CanvasItem, texto: String, pos: Vector2, color: Color = Color.WHITE,
		escala: int = 1, sombra: Color = SOMBRA, alinear: int = IZQUIERDA) -> void:
	texto = texto.to_upper()
	var x := pos.x
	if alinear == CENTRO:
		x = roundf(pos.x - ancho(texto, escala) / 2.0)
	elif alinear == DERECHA:
		x = roundf(pos.x - ancho(texto, escala))
	if sombra.a > 0.0:
		_pasada(ci, texto, Vector2(x + escala, pos.y + escala), sombra, escala)
	_pasada(ci, texto, Vector2(x, pos.y), color, escala)


## Texto con contorno (logotipo)
static func dibujar_contorno(ci: CanvasItem, texto: String, centro_x: float, y: float, relleno: Color,
		contorno: Color, escala: int, caida: Color = SIN_SOMBRA) -> void:
	var x := roundf(centro_x - ancho(texto.to_upper(), escala) / 2.0)
	if caida.a > 0.0:
		_pasada(ci, texto.to_upper(), Vector2(x, y + escala * 2), caida, escala)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_pasada(ci, texto.to_upper(), Vector2(x, y) + o * escala, contorno, escala)
	_pasada(ci, texto.to_upper(), Vector2(x, y), relleno, escala)


static func _pasada(ci: CanvasItem, texto: String, pos: Vector2, color: Color, escala: int) -> void:
	var tex := textura()
	for i in texto.length():
		var ch := texto[i]
		var acento := false
		if ACENTOS.has(ch):
			acento = true
			ch = ACENTOS[ch]
		var idx := CARACTERES.find(ch)
		if idx < 0:
			idx = CARACTERES.find("?")
		var x := pos.x + i * 6 * escala
		ci.draw_texture_rect_region(tex, Rect2(x, pos.y, 5 * escala, 7 * escala), Rect2(idx * 6, 0, 5, 7), color)
		if acento and texto[i] == "Ü":
			ci.draw_rect(Rect2(x + escala, pos.y - 2 * escala, escala, escala), color)
			ci.draw_rect(Rect2(x + 3 * escala, pos.y - 2 * escala, escala, escala), color)
		elif acento:
			ci.draw_rect(Rect2(x + 3 * escala, pos.y - 3 * escala, escala, escala), color)
			ci.draw_rect(Rect2(x + 2 * escala, pos.y - 2 * escala, escala, escala), color)


## Parte un texto en líneas que no pasen de cierto ancho (en píxeles, a escala 1).
static func partir(texto: String, ancho_max: float) -> PackedStringArray:
	var lineas := PackedStringArray()
	var linea := ""
	for palabra in texto.split(" ", false):
		var prueba := palabra if linea == "" else linea + " " + palabra
		if ancho(prueba) > ancho_max and linea != "":
			lineas.append(linea)
			linea = palabra
		else:
			linea = prueba
	if linea != "":
		lineas.append(linea)
	return lineas
