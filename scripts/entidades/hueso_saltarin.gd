# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/hueso_saltarin.gd
#  Qué es:   Huesito que sale de un bloque colmena
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Hueso que sale de un bloque colmena, da un salto y desaparece.


func _ready() -> void:
	tipo = "hueso_saltarin"
	velocity.y = -312.0
	activo = true
	z_index = 2


func paso(delta: float) -> void:
	t += 1
	position.y += velocity.y * delta
	velocity.y += 1152.0 * delta
	sprite.frame = (t >> 1) & 3
	if t > 24:
		nivel.particula("chispa", global_position + Vector2(0, -8))
		quitar()
