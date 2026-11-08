# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/milano.gd
#  Qué es:   Milano: se lanza en picado
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Milano: vigila desde arriba y se lanza en picado hacia Tizón. Se puede pisar.

var estado := "vigila"     # vigila, picado, se_va
var y0 := 0.0
var vx := 0.0
var vy := 0.0
var reloj := 0


func _ready() -> void:
	tipo = "milano"
	ancho = 12.0
	alto = 9.0
	y0 = position.y


func paso(_delta: float) -> void:
	t += 1
	var c := caja().get_center()
	var pc: Vector2 = nivel.jugador.caja().get_center()
	match estado:
		"vigila":
			position.x -= 0.35
			position.y = y0 + sin(t * 0.08) * 4.0
			dir = -1
			if absf(pc.x - c.x) < 80.0 and pc.y > caja().position.y + 10.0:
				var d := pc - c
				var l := maxf(d.length(), 1.0)
				vx = d.x / l * 2.6
				vy = maxf(1.0, d.y / l * 2.6)
				estado = "picado"
				reloj = 0
				dir = -1 if d.x < 0.0 else 1
				Sonido.tocar("graznido")
		"picado":
			position += Vector2(vx, vy)
			reloj += 1
			if reloj > 50:
				estado = "se_va"
		_:
			vy = maxf(-2.0, vy - 0.08)
			position += Vector2(vx, vy)
			if not nivel.en_pantalla(caja(), 48.0):
				quitar()
				return
	if estado == "picado":
		sprite.frame = 2
	else:
		sprite.frame = 0 if ((t >> 3) & 1) != 0 else 1
	sprite.flip_h = dir > 0
