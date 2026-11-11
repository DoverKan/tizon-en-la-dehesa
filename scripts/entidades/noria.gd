# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/noria.gd
#  Qué es:   Noria de la Feria (las cabinas son plataformas aparte)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## La noria de la Feria: patas, radios, aro y bombillas. Las seis cabinas son
## plataformas aparte (plataforma.gd con eje «giro»). El origen es el centro.

@export var suelo_y := 208.0     # y del suelo, en coordenadas del nivel (hasta donde llegan las patas)
const RADIO := 80.0

var nivel = null
var tipo := "noria"
var vivo := true
var activo := true
var angulo := 0.0


func _ready() -> void:
	z_index = -1


func paso(_delta: float) -> void:
	angulo += TAU / 720.0
	queue_redraw()


func caja() -> Rect2:
	return Rect2(global_position - Vector2(RADIO, RADIO), Vector2(RADIO * 2.0, RADIO * 2.0))


func _punto(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(p.round(), Vector2(2, 2)), c)


func _draw() -> void:
	var alto := suelo_y - position.y
	for s in [-1.0, 1.0]:
		for k in 40:
			var u := k / 40.0
			_punto(Vector2(s * u * 50.0, u * alto), Color("4a3a5a"))
	for k in 6:
		var a := angulo + k * PI / 3.0
		var q := 4.0
		while q < RADIO:
			_punto(Vector2(cos(a), sin(a)) * q, Color("6a5a8a"))
			q += 4.0
	var f := Engine.get_physics_frames()
	for k in 72:
		var a := angulo + k / 72.0 * TAU
		var encendida := ((k + (f >> 3)) % 3) == 0
		var c := Color("8a7aaa")
		if k % 6 == 0:
			c = Color.WHITE if encendida else Color("ffd23f")
		_punto(Vector2(cos(a), sin(a)) * RADIO - Vector2(1, 1), c)
	draw_rect(Rect2(-4, -4, 8, 8), Color("2a2040"))
	draw_rect(Rect2(-2, -2, 4, 4), Color("ffd23f"))
