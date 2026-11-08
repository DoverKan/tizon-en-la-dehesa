# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/pasadizo.gd
#  Qué es:   Pasadizo: boca de una encina hueca
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends Node2D
## Pasadizo: marca la boca de una encina hueca por la que se puede entrar con ↓.
## Se sale por el otro pasadizo del nivel que tenga el mismo número.
## Colócalo centrado sobre la boca del tronco (encima de las dos losetas de arriba).

@export var numero := 1:
	set(v):
		numero = v
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-12, -3, 24, 3), Color(1.0, 0.8, 0.2, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(-4, -6), str(numero), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.85, 0.3))
