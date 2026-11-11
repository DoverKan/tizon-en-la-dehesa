# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/paloma.gd
#  Qué es:   Paloma de Badajoz
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Paloma de Badajoz: anda por la acera y de vez en cuando se para a picotear.
## Si la pisas (o le da el fuego o una concha) sale volando.

var picotea := false
var _mirando_ya := false


func _ready() -> void:
	tipo = "paloma"
	ancho = 12.0
	alto = 10.0
	super._ready()


func paso(delta: float) -> void:
	t += 1
	if not _mirando_ya:
		dir = -1 if nivel.jugador.global_position.x < global_position.x else 1
		_mirando_ya = true
	picotea = (t % 140) > 108
	velocity.x = 0.0 if picotea else 27.0 * dir
	caer(delta)
	move_and_slide()
	if is_on_wall():
		dir = 1 if get_wall_normal().x > 0.0 else -1
	if nivel.al_agua(self):
		return
	if global_position.y > nivel.fondo_zona(self) + 32:
		quitar()
		return
	_dibujo()


## Sale volando hacia un lado, soltando plumas.
func volar(direccion: float) -> void:
	muriendo = "vuelo"
	dir = 1 if direccion >= 0.0 else -1
	velocity = Vector2(dir * 1.4, -1.4)      # en píxeles por fotograma
	collision_mask = 0
	nivel.plumas(global_position + Vector2(0, -6))
	Sonido.tocar("aleteo")


func paso_muriendo(delta: float) -> void:
	if muriendo != "vuelo":
		super.paso_muriendo(delta)
		return
	t += 1
	position += velocity
	velocity.y = maxf(-2.4, velocity.y - 0.06)
	if not nivel.en_pantalla(caja(), 48.0):
		quitar()
		return
	_dibujo()


func _dibujo() -> void:
	if muriendo == "vuelo":
		sprite.frame = 2 if ((t >> 2) & 1) != 0 else 3
		sprite.position.y = -7.0
	else:
		sprite.frame = 0 if ((t >> 3) & 1) != 0 else 1
		sprite.position.y = -6.0 if (picotea and ((t >> 3) & 1) != 0) else -7.0
	sprite.flip_h = dir > 0
