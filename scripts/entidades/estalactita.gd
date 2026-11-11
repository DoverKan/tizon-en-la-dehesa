# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/estalactita.gd
#  Qué es:   Estalactita de las cuevas: cae al pasar por debajo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Estalactita de las cuevas: tiembla y cae cuando Tizón pasa por debajo.

var estado := "colgada"    # colgada, tiembla, cae
var reloj := 0
var vy := 0.0


func _ready() -> void:
	tipo = "estalactita"
	ancho = 10.0
	alto = 14.0


func paso(_delta: float) -> void:
	t += 1
	var j: Tizon = nivel.jugador
	match estado:
		"colgada":
			if absf(j.global_position.x - global_position.x) < 22.0 and j.caja().position.y > caja().position.y:
				estado = "tiembla"
				reloj = 22
		"tiembla":
			reloj -= 1
			if reloj <= 0:
				estado = "cae"
				vy = 0.0
		"cae":
			vy = minf(vy + 0.35, 6.0)
			position.y += vy
			var celda: Vector2i = nivel.celda_en(global_position)
			if nivel.es_solido(celda) or nivel.tipo_en(celda) == "agua" or global_position.y > nivel.fondo_zona(self):
				for v in [Vector2(-1.2, -2.5), Vector2(1.2, -2.5), Vector2(-0.6, -1.5), Vector2(0.6, -1.5)]:
					nivel.particula_v("piedrecita", global_position + Vector2(0, -2), v, 30)
				if nivel.en_pantalla(caja(), 0.0):
					Sonido.tocar("derrumbe")
				quitar()
				return
	sprite.position.x = float((reloj >> 1) & 1) if estado == "tiembla" else 0.0
