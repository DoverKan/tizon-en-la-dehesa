# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/aspersor.gd
#  Qué es:   Aspersor de los jardines del MEIAC: lanza a Tizón hacia arriba
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Aspersor de los jardines del MEIAC: descansa, echa un chorro que sube, riega
## con fuerza y baja. Dentro del chorro Tizón sale disparado hacia arriba y
## puede saltar como si estuviera en el suelo.
## El origen es el pie del aspersor, en el centro.

const ALTO_CHORRO := 96.0
var reloj := 0
var chorro := 0.0


func _ready() -> void:
	tipo = "aspersor"
	ancho = 10.0
	alto = 4.0
	z_index = -1
	reloj = (int(position.x / 16.0) * 23) % 180


func paso(_delta: float) -> void:
	t += 1
	reloj += 1
	var c := reloj % 180
	if c < 90:
		chorro = 0.0
	elif c < 100:
		chorro = (c - 90) / 10.0 * ALTO_CHORRO
	elif c < 170:
		chorro = ALTO_CHORRO
	else:
		chorro = (180 - c) / 10.0 * ALTO_CHORRO
	if c == 90 and nivel.en_pantalla(caja(), 0.0):
		Sonido.tocar("chorro")
	if chorro > 8.0 and nivel.estado == "jugando":
		var j: Tizon = nivel.jugador
		var cj := j.caja()
		var arriba := global_position.y - chorro
		if cj.end.x > global_position.x - 5.0 and cj.position.x < global_position.x + 5.0 and cj.end.y > arriba and cj.end.y <= global_position.y + 2.0:
			# empuja hacia arriba sin frenar un salto que ya sube más deprisa,
			# y dentro del chorro se puede saltar
			if j.velocity.y > -252.0:
				j.velocity.y = maxf(j.velocity.y - 54.0, -252.0)
			j.en_suelo = false
			j.coyote = maxi(j.coyote, 2)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6, -4, 12, 4), Color("3a3e48"))
	draw_rect(Rect2(-5, -4, 10, 1), Color("8a8e9a"))
	draw_rect(Rect2(-2, -7, 4, 3), Color("5a5e6a"))
	var f := Engine.get_physics_frames()
	if chorro > 0.0:
		var arriba := -7.0 - chorro
		draw_rect(Rect2(-3, arriba, 6, chorro), Color(160 / 255.0, 210 / 255.0, 240 / 255.0, 0.75))
		draw_rect(Rect2(-1, arriba, 2, chorro), Color(230 / 255.0, 246 / 255.0, 1.0, 0.9))
		for i in 6:
			var ph := (f * 2 + i * 9) % 20
			draw_rect(Rect2(roundf(cos(i * 1.7) * (2.0 + ph / 3.0)), roundf(arriba - 2.0 + ph / 3.0), 2, 2), Color("d8eefa"))
	elif reloj % 180 > 70:
		draw_rect(Rect2(-1, -9 - ((f >> 2) & 1), 2, 2), Color("a8d4ee"))
