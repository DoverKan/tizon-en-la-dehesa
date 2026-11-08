# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/objeto.gd
#  Qué es:   Objetos que salen de las colmenas: galleta y Zorongollo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Objetos que salen de los bloques colmena:
##  - galleta: Tizón crece. Se desliza por el suelo.
##  - zorongollo: poder de fuego. Sale corriendo con sus patitas y da saltitos.
## (El disco volador flota y usa disco.gd.)

@export var clase := "galleta"
var saliendo := 32


func _ready() -> void:
	tipo = clase
	if clase == "galleta":
		ancho = 14.0
		alto = 13.0
	else:
		ancho = 12.0
		alto = 14.0
	super._ready()
	collision_layer = 0
	z_index = -1
	activo = true
	if clase == "zorongollo":
		sprite.texture = load("res://assets/sprites/zorongollo.png")
		sprite.hframes = 2
		sprite.position = Vector2(0, -8)
	else:
		sprite.texture = load("res://assets/sprites/galleta.png")
		sprite.hframes = 1
		sprite.position = Vector2(0, -6)


func paso(delta: float) -> void:
	t += 1
	if saliendo > 0:
		saliendo -= 1
		position.y -= 0.5
		if saliendo == 0:
			z_index = 0
		return
	if clase == "galleta":
		velocity.x = 60.0 * dir
	else:
		velocity.x = 48.0 * dir
		sprite.frame = (t >> 3) & 1
		sprite.flip_h = dir < 0
	caer(delta)
	move_and_slide()
	if is_on_wall():
		dir = -dir
	if clase == "zorongollo" and is_on_floor() and t % 70 == 0:
		velocity.y = -204.0
	if nivel.al_agua(self):
		return
	if global_position.y > nivel.fondo_zona(self) + 16:
		quitar()


func botar(desde_x: float) -> void:
	velocity.y = -210.0
	dir = -1 if global_position.x < desde_x else 1
