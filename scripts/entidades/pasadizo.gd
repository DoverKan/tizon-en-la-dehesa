# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/pasadizo.gd
#  Qué es:   Pasadizo: boca de una encina hueca
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
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
## Puerta (2 casillas de ancho y 3 de alto) en vez de encina: se entra con un fundido
@export var puerta := false


func _ready() -> void:
	# la puerta se dibuja delante de la fachada y detrás de Tizón (que se añade al nivel después)
	if puerta:
		queue_redraw()


func _draw() -> void:
	if puerta:
		Adornos.dibujar_puerta(self, -16.0, -48.0)   # sin destellos ni flecha: es secreta
		return
	if Engine.is_editor_hint():
		draw_rect(Rect2(-12, -3, 24, 3), Color(1.0, 0.8, 0.2, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(-4, -6), str(numero), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.85, 0.3))
