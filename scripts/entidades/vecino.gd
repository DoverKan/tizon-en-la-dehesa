# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/vecino.gd
#  Qué es:   Vecino de Badajoz que saluda a Tizón
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Vecino de Badajoz: en Badajoz todo el mundo conoce a Tizón. Al verle pasar le
## saluda (con un bocadillo y unos corazones). No hace daño.

@export_range(0, 3) var variante := 0
@export var mensaje := "¡HOLA, TIZÓN!"
var dicho := false
var habla := 0


func _ready() -> void:
	tipo = "vecino"
	ancho = 8.0
	alto = 22.0
	activo = true
	sprite.frame_coords = Vector2i(0, variante)


func paso(_delta: float) -> void:
	t += 1
	var j: Tizon = nivel.jugador
	var d := j.global_position.x - global_position.x
	dir = -1 if d < 0.0 else 1
	if not dicho and absf(d) < 64.0 and absf(j.caja().position.y - caja().position.y) < 70.0 and nivel.estado == "jugando":
		dicho = true
		habla = 150
		nivel.corazones(global_position + Vector2(0, -24))
		Sonido.tocar("ladrido")
	if habla > 0:
		habla -= 1
	sprite.frame_coords = Vector2i(1 if (habla > 0 and ((t >> 4) & 1) != 0) else 0, variante)
	sprite.flip_h = dir > 0


func texto_bocadillo() -> String:
	return mensaje if habla > 0 else ""
