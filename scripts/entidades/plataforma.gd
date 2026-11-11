# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/plataforma.gd
#  Qué es:   Plataformas: madera, barca, tronco, cabina de noria y cigüeña
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends Node2D
## Plataformas sobre las que Tizón puede ir de pie. Su origen es la esquina superior izquierda.
##  - madera / barca: va y viene (eje "x") o sube y baja (eje "y"). La barca es la del Guadiana.
##  - tronco: flota en el Guadiana y se hunde si Tizón se queda encima (eje "hundir").
##  - gondola: cabina de la noria; da vueltas alrededor del centro (eje "giro").
##  - ciguena: una cigüeña que vuela de un lado a otro y sube y baja un poco (bambolea).

@export_enum("madera", "barca", "tronco", "gondola", "ciguena") var clase := "madera":
	set(v):
		clase = v
		queue_redraw()
@export_enum("x", "y", "hundir", "giro") var eje := "x"
@export var ancho := 48.0
@export var recorrido := 112.0
@export var periodo := 6.0          # segundos de ida y vuelta
@export var desfase := 0            # fotogramas
@export var bambolea := false
@export var centro := Vector2.ZERO  # solo noria: centro de giro, en coordenadas del nivel
@export var radio := 80.0
@export var angulo0 := 0.0

const COLORES_CABINA := ["d9432f", "2e6fb7", "f2c94c", "4f9a5a", "e85a8a", "f28a1e"]
const TEX_CIGUENA := preload("res://assets/sprites/ciguena_vuelo.png")

var nivel = null
var origen := Vector2.ZERO
var t := 0
var encima := 0                     # fotogramas que lleva Tizón encima del tronco
var desplazamiento := Vector2.ZERO


func _ready() -> void:
	origen = position
	t = desfase
	if clase == "tronco":
		z_index = -1            # lo que queda bajo el agua no se ve
	if eje == "giro":
		_colocar_giro()


func _colocar_giro() -> void:
	var a := angulo0 + t * TAU / 720.0
	position = centro + Vector2(cos(a) * radio - ancho / 2.0, sin(a) * radio - 3.0)


func paso(_delta: float) -> void:
	var antes := position
	match eje:
		"giro":
			t += 1
			_colocar_giro()
		"hundir":
			if nivel and nivel.jugador.plataforma == self:
				encima += 1
				if encima > 14:
					position.y = minf(origen.y + 30.0, position.y + 0.3)
			else:
				encima = 0
				if position.y > origen.y:
					position.y = maxf(origen.y, position.y - 0.3)
		_:
			t += 1
			var fase := (1.0 - cos(t * TAU / (periodo * 60.0))) / 2.0
			if eje == "x":
				position.x = origen.x + fase * recorrido
			else:
				position.y = origen.y - fase * recorrido
			if bambolea:
				position.y = origen.y + roundf(sin(t * 0.06) * 4.0)
	desplazamiento = position - antes
	queue_redraw()


func _draw() -> void:
	match clase:
		"gondola":
			var col := Color(COLORES_CABINA[int(roundf(angulo0 / (PI / 3.0))) % COLORES_CABINA.size()])
			draw_rect(Rect2(15, -6, 2, 6), Color("4a3a5a"))
			draw_rect(Rect2(0, 0, 32, 3), Color("2a2040"))
			draw_rect(Rect2(1, 0, 30, 1), Color("8a7aaa"))
			draw_rect(Rect2(3, 3, 26, 10), Color("2a2040"))
			draw_rect(Rect2(4, 3, 24, 9), col)
			draw_rect(Rect2(7, 5, 6, 4), Color("ffe9a0"))
			draw_rect(Rect2(19, 5, 6, 4), Color("ffe9a0"))
		"ciguena":
			var marco := 0 if ((t >> 3) & 1) != 0 else 1
			draw_texture_rect_region(TEX_CIGUENA, Rect2(-2, -5, 32, 16), Rect2(marco * 32, 0, 32, 16))
		"tronco":
			var tiembla := float((Engine.get_physics_frames() >> 1) & 1) if encima > 0 and encima < 16 else 0.0
			draw_rect(Rect2(0, tiembla, ancho, 9), Color("3a2412"))
			draw_rect(Rect2(1, 1 + tiembla, ancho - 2, 7), Color("7a4e2a"))
			draw_rect(Rect2(1, 1 + tiembla, ancho - 2, 2), Color("a06a3a"))
			var k := 6
			while k < ancho - 8:
				draw_rect(Rect2(k, 4 + ((k / 12) & 1) + tiembla, 6, 1), Color("5a3418"))
				k += 12
			draw_rect(Rect2(ancho - 5, 1 + tiembla, 4, 7), Color("c89a5e"))
			draw_rect(Rect2(ancho - 4, 3 + tiembla, 2, 3), Color("8a5a2e"))
		"barca":
			draw_rect(Rect2(0, 0, ancho, 3), Color("4a2a12"))
			draw_rect(Rect2(1, 0, ancho - 2, 2), Color("a06a3a"))
			draw_rect(Rect2(2, 3, ancho - 4, 4), Color("3a6a8a"))
			draw_rect(Rect2(2, 4, ancho - 4, 1), Color("f6eedb"))
			draw_rect(Rect2(5, 7, ancho - 10, 3), Color("2a4a6a"))
		_:
			draw_rect(Rect2(0, 0, ancho, 8), Color("4a2a12"))
			draw_rect(Rect2(1, 1, ancho - 2, 5), Color("c58d55"))
			draw_rect(Rect2(1, 1, ancho - 2, 1), Color("e3ad74"))
			for x in [4.0, ancho / 2.0 - 1.0, ancho - 6.0]:
				draw_rect(Rect2(x, 3, 2, 2), Color("5b3a1e"))
	if Engine.is_editor_hint() and eje in ["x", "y"]:
		var fin := Vector2(recorrido, 0) if eje == "x" else Vector2(0, -recorrido)
		draw_dashed_line(Vector2(ancho / 2.0, 4), Vector2(ancho / 2.0, 4) + fin, Color(1, 1, 1, 0.6), 1.0, 3.0)
