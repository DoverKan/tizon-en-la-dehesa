# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/abejorro.gd
#  Qué es:   Abejorro: vuela haciendo ondas
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Abejorro: vuela haciendo ondas. Se puede pisar.

var base_y := 0.0


func _ready() -> void:
	tipo = "abejorro"
	ancho = 14.0
	alto = 12.0
	base_y = position.y


func paso(_delta: float) -> void:
	t += 1
	if t == 1 and nivel:
		dir = -1 if nivel.jugador.global_position.x < global_position.x else 1
	position.x += 36.0 / 60.0 * dir
	position.y = base_y + sin(t * 0.06) * 14.0
	if t % 200 == 0:
		dir = -dir
	sprite.frame = (t >> 2) & 1
	sprite.flip_h = dir > 0
