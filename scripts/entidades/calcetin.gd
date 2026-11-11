# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/calcetin.gd
#  Qué es:   Calcetín: cinco escondidos en cada nivel
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Calcetín: hay cinco escondidos en cada nivel. Tizón los colecciona.

@export var indice := 0


func _ready() -> void:
	tipo = "calcetin"
	ancho = 12.0
	alto = 14.0
	activo = true


func paso(_delta: float) -> void:
	t += 1
	sprite.position.y = -7.0 + roundf(sin(t * 0.08) * 1.5)
