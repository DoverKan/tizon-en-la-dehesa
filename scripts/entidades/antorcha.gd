# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/antorcha.gd
#  Qué es:   Antorcha de la Alcazaba (decorado que da luz)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## Antorcha de la Alcazaba (solo decorado). El origen es la esquina de arriba
## a la izquierda de su casilla; la llama sobresale 6 píxeles por arriba.

var tipo := "antorcha"
@onready var sprite: Sprite2D = $Sprite


func _process(_delta: float) -> void:
	sprite.frame = ((Engine.get_physics_frames() >> 3) + int(position.x / 16.0)) % 3
