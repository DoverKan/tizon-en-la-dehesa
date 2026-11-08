# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/pieza.gd
#  Qué es:   Base de lo que no usa física (abejorro, cardo, calcetín, decorado...)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Pieza
extends Node2D
## Base de lo que no usa física: abejorro, cardo, calcetín, objetos flotantes...
## Origen en los pies, en el centro, como Cuerpo.

@export var ancho := 14.0
@export var alto := 12.0

var tipo := ""
var nivel: Nivel = null
var vivo := true
var activo := false
var muriendo := ""
var t := 0
var dir := -1
var velocity := Vector2.ZERO
@onready var sprite: Sprite2D = get_node_or_null("Sprite")


func caja() -> Rect2:
	return Rect2(global_position.x - ancho / 2.0, global_position.y - alto, ancho, alto)


func matar_volteo(direccion: float) -> void:
	muriendo = "volteo"
	velocity = Vector2(direccion * 66.0, -216.0)
	if sprite:
		sprite.flip_v = true
	z_index = 5


func paso_muriendo(delta: float) -> void:
	if muriendo == "volteo":
		velocity.y += 1080.0 * delta
		position += velocity * delta
		if nivel and global_position.y > nivel.camara.position.y + 260:
			quitar()


func quitar() -> void:
	vivo = false
	queue_free()
