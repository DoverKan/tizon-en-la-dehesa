# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/disco.gd
#  Qué es:   Disco volador: da el poder de planear
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Disco volador: sale del bloque y baja flotando de lado a lado. Da el poder de planear.

var saliendo := 32
var base_x := 0.0


func _ready() -> void:
	tipo = "disco"
	ancho = 14.0
	alto = 8.0
	z_index = -1
	activo = true
	base_x = position.x


func paso(_delta: float) -> void:
	t += 1
	if saliendo > 0:
		saliendo -= 1
		position.y -= 0.5
		if saliendo == 0:
			z_index = 0
		return
	position.x = base_x + sin(t * 0.045) * 18.0
	position.y += 0.4
	if global_position.y > nivel.fondo_zona(self) + 16:
		quitar()
