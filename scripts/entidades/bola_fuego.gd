# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/bola_fuego.gd
#  Qué es:   Bola de fuego que escupe Tizón con el poder del Zorongollo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Bola de fuego que escupe Tizón con el poder del Zorongollo. Rebota por el suelo.


func _ready() -> void:
	tipo = "fuego"
	ancho = 8.0
	alto = 8.0
	super._ready()
	collision_layer = 0
	add_to_group("bolas_fuego")
	velocity = Vector2(222.0 * dir, 90.0)
	activo = true


func paso(delta: float) -> void:
	t += 1
	velocity.y = minf(velocity.y + 1080.0 * delta, 240.0)
	var vx := velocity.x
	move_and_slide()
	if is_on_floor():
		velocity.y = -162.0
	if is_on_wall():
		nivel.humo(global_position + Vector2(0, -4))
		quitar()
		return
	velocity.x = vx
	sprite.frame = (t >> 2) & 1
	if not nivel.en_pantalla(caja(), 16.0):
		quitar()
