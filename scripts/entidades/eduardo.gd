# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/eduardo.gd
#  Qué es:   Eduardo, el dueño de The Cereal Cafe
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Eduardo, el dueño de The Cereal Cafe: espera a Tizón en la puerta del café.

var dicho := 0
var habla := 0
var lineas: Array = []
var mensaje := ""


func _ready() -> void:
	tipo = "eduardo"
	ancho = 8.0
	alto = 22.0
	activo = true


func paso(_delta: float) -> void:
	t += 1
	var j: Tizon = nivel.jugador
	var d := j.global_position.x - global_position.x
	dir = -1 if d < 0.0 else 1
	if dicho == 0 and absf(d) < 200.0 and nivel.estado == "jugando":
		dicho = 1
		lineas = ["¡BUENOS DÍAS, TIZÓN!", "¿LO DE SIEMPRE?"]
		habla = 0
		nivel.corazones(global_position + Vector2(0, -24))
	if nivel.estado == "meta" and dicho < 2:
		dicho = 2
		lineas = ["¡PASA, PASA!"]
		habla = 0
	if habla > 0:
		habla -= 1
	elif not lineas.is_empty():
		mensaje = lineas.pop_front()
		habla = 110
	var saluda := (habla > 0 or nivel.estado == "meta") and ((t >> 4) & 1) != 0
	sprite.frame = 1 if saluda else 0
	sprite.flip_h = dir > 0


func texto_bocadillo() -> String:
	return mensaje if habla > 0 else ""
