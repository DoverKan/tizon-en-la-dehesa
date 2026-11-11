# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/milano.gd
#  Qué es:   Milano: avisa y se deja caer si Tizón pasa por debajo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Milano: vigila quieto en lo alto. Cuando Tizón pasa justo por debajo, tiembla y grazna (aviso)
## y luego se deja caer en vertical hasta salir por abajo de la pantalla: basta con apartarse un
## paso. Se puede pisar.

var estado := "vigila"     # vigila, aviso, picado
var y0 := 0.0
var x_aviso := 0.0
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
			position.y = y0 + sin(t * 0.08) * 4.0
			dir = -1 if pc.x < c.x else 1
			# solo si se le ve entero en pantalla
			var cx: float = nivel.cam.x
			var dentro: bool = caja().position.x > cx + 8.0 and caja().end.x < cx + nivel.VW - 8.0
			if absf(pc.x - c.x) < 28.0 and pc.y > caja().position.y + 24.0 and dentro:
				estado = "aviso"
				reloj = 0
				x_aviso = position.x
				Sonido.tocar("graznido")
		"aviso":
			position.x = x_aviso + (1.0 if ((reloj >> 1) & 1) != 0 else -1.0)
			reloj += 1
			if reloj > 40:
				position.x = x_aviso
				vx = 0.0
				vy = 2.0
				estado = "picado"
				reloj = 0
		"picado":
			# cae en vertical hasta salir por abajo de la pantalla
			position.y += vy
			if position.y > nivel.cam.y + nivel.VH + 16.0:
				quitar()
				return
	if estado == "picado":
		sprite.frame = 2
	else:
		var r := 1 if estado == "aviso" else 3
		sprite.frame = 0 if ((t >> r) & 1) != 0 else 1
	sprite.flip_h = dir > 0
