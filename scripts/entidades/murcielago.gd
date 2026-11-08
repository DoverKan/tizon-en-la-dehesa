# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/murcielago.gd
#  Qué es:   Murciélago: cuelga del techo y se lanza en picado
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Murciélago: cuelga del techo y se lanza en picado cuando Tizón pasa por debajo.
## Se puede pisar, como el abejorro.

var estado := "colgado"    # colgado, picado
var vy := 0.0


func _ready() -> void:
	tipo = "murcielago"
	ancho = 12.0
	alto = 10.0


func paso(_delta: float) -> void:
	t += 1
	var j: Tizon = nivel.jugador
	var dx := j.global_position.x - global_position.x
	if estado == "colgado":
		if absf(dx) < 76.0 and j.caja().position.y > caja().position.y:
			estado = "picado"
			dir = 1 if dx >= 0.0 else -1
			vy = 2.7
	else:
		position.x += 1.15 * dir
		position.y += vy
		if vy > 0.0:
			vy = maxf(0.0, vy - 0.055)
		if not nivel.en_pantalla(caja(), 64.0):
			quitar()
			return
	sprite.frame = 0 if estado == "colgado" else (1 if ((t >> 3) & 1) != 0 else 2)
	sprite.flip_h = dir > 0
