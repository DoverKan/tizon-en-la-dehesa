# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/caseta.gd
#  Qué es:   Caseta: punto de control y guardado
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Caseta: punto de control. Al tocarla se guarda la partida y, si caes, vuelves aquí.

var encendida := false
var animacion := 0


func _ready() -> void:
	tipo = "caseta"
	ancho = 10.0
	alto = 32.0
	activo = true


func paso(_delta: float) -> void:
	t += 1
	if animacion > 0:
		animacion -= 1
	sprite.frame = 1 if encendida else 0
	sprite.position.y = -13.5 - (roundf(sin((40 - animacion) / 40.0 * PI) * 3.0) if animacion > 0 else 0.0)
