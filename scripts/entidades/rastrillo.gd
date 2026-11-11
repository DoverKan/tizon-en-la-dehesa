# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/rastrillo.gd
#  Qué es:   Rastrillo de la Alcazaba: tiembla y cae al pasar por debajo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Rastrillo de la Alcazaba: cuando Tizón pasa por debajo tiembla un momento
## (es el aviso), cae de golpe, espera un poco en el suelo y vuelve a subir
## despacio. Hace daño si te pilla: andando da tiempo a pasar; parándose debajo, no.
## Ojo: aquí el origen es la esquina de arriba a la izquierda (32x30).

var y0 := 0.0
var estado := "arriba"     # arriba, tiembla, cae, abajo, sube
var espera := 0
var vy := 0.0
var _tex: Texture2D = preload("res://assets/sprites/rastrillo.png")


func _ready() -> void:
	tipo = "rastrillo"
	ancho = 32.0
	alto = 30.0
	y0 = position.y
	activo = true


func caja() -> Rect2:
	return Rect2(global_position, Vector2(ancho, alto))


func paso(_delta: float) -> void:
	t += 1
	var j: Tizon = nivel.jugador
	var cx := j.global_position.x
	match estado:
		"arriba":
			if espera > 0:
				espera -= 1
			elif cx > position.x - 6.0 and cx < position.x + ancho + 6.0 and j.caja().position.y > position.y:
				estado = "tiembla"
				espera = 14
				if nivel.en_pantalla(caja(), 16.0):
					Sonido.tocar("derrumbe")
		"tiembla":
			espera -= 1
			if espera <= 0:
				estado = "cae"
				vy = 0.0
		"cae":
			vy = minf(vy + 0.5, 7.0)
			position.y += vy
			var fila := floori((position.y + alto) / 16.0)
			if nivel.es_solido(Vector2i(floori((position.x + 8.0) / 16.0), fila)) or nivel.es_solido(Vector2i(floori((position.x + ancho - 8.0) / 16.0), fila)):
				position.y = fila * 16.0 - alto
				estado = "abajo"
				espera = 50
				if nivel.en_pantalla(caja(), 16.0):
					Sonido.tocar("golpazo")
		"abajo":
			espera -= 1
			if espera <= 0:
				estado = "sube"
		"sube":
			position.y -= 0.8
			if position.y <= y0:
				position.y = y0
				estado = "arriba"
				espera = 40
	queue_redraw()


## La parte que hace daño (un poco más estrecha que el dibujo).
func caja_dano() -> Rect2:
	return Rect2(global_position + Vector2(2, 0), Vector2(ancho - 4.0, alto))


func _draw() -> void:
	# cadena desde el techo
	var tiembla := float(((espera >> 1) & 1) * 2 - 1) if estado == "tiembla" else 0.0
	draw_rect(Rect2(15 + tiembla, y0 - position.y - 4.0, 2, maxf(0.0, position.y - y0 + 4.0)), Color("5a5e68"))
	draw_texture(_tex, Vector2(tiembla, 0))
