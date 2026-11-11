# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/zona.gd
#  Qué es:   Zona de un nivel: límites de la cámara y tema del fondo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends Node2D
## Zona del nivel (la dehesa, la madriguera, la alcazaba...). La cámara no sale de su
## rectángulo y el fondo usa su tema. El rectángulo va en píxeles, relativo al nivel.

@export var rect := Rect2(0, 0, 384, 256):
	set(v):
		rect = v
		queue_redraw()
@export_enum("dehesa", "atardecer", "cueva", "castillo", "ciudad", "rio", "jardin", "museo", "feria", "gruta", "cielo", "romano") var tema := "dehesa"


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(rect, Color(0.3, 0.8, 1.0, 0.8), false, 2.0)
