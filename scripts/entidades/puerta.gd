# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/puerta.gd
#  Qué es:   Puerta de la sala del jefe: se cierra al empezar la pelea
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends Node2D
## Puerta de la sala de Micifuz: al empezar la pelea, esta casilla se convierte
## en piedra y ya no se puede salir. El origen es la esquina de arriba a la izquierda.

var tipo := "puerta"


func celda() -> Vector2i:
	return Vector2i(floori(position.x / 16.0), floori(position.y / 16.0))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(0, 0, 16, 16), Color(1.0, 0.4, 0.3, 0.8), false, 1.0)
