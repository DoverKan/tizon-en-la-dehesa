# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/urraca.gd
#  Qué es:   La Urraca, jefa del Teatro Romano (Mundo 2)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## La Urraca del Teatro Romano, jefa del Mundo 2. Espera hasta que Tizón cruza la
## puerta de la sala; entonces la puerta se cierra. Vuela de lado a lado, apunta
## (sale un «!»), se lanza en picado y se queda aturdida en el suelo: es el
## momento de pisarla. Volando no se le puede hacer nada (Tizón rebota). Aguanta
## tres pisotones y con cada uno va más deprisa.

const W := 28.0
const H := 18.0
var nombre := "URRACA"
var vidas := 3
var estado := "espera"     # espera, vuela, apunta, picado, suelo, sube, herida, vencida
var reloj := 0
var ex := 0.0              # esquina de arriba a la izquierda (como en la web)
var ey := 0.0
var y0 := 0.0
var vx := 0.0
var vy := 0.0
var min_x := 0.0
var max_x := 0.0
var suelo_y := 0.0


func _ready() -> void:
	tipo = "urraca"
	ancho = W
	alto = H
	activo = true
	ex = position.x - W / 2.0
	ey = position.y - H
	y0 = ey


func _colocar() -> void:
	position = Vector2(ex + W / 2.0, ey + H)
	queue_redraw()


func paso(_delta: float) -> void:
	t += 1
	var cj: Rect2 = nivel.jugador.caja()
	if estado == "espera":
		ey = y0 + sin(t * 0.05) * 3.0
		var puertas: Array = nivel.puertas()
		if not puertas.is_empty() and cj.position.x > (puertas[0].x + 2) * 16.0:
			_empezar(puertas[0])
		_colocar()
		_dibujo()
		return
	reloj += 1
	var lvl := 3 - vidas
	match estado:
		"vuela":
			ey += (y0 - ey) * 0.1 + sin(t * 0.1) * 0.4
			ex += vx * (1.0 + lvl * 0.3)
			if ex < min_x:
				ex = min_x
				vx = absf(vx)
			if ex > max_x:
				ex = max_x
				vx = -absf(vx)
			dir = -1 if vx < 0.0 else 1
			if reloj > 110 - lvl * 20:
				estado = "apunta"
				reloj = 0
		"apunta":
			var tx := cj.get_center().x - W / 2.0
			ex += clampf(tx - ex, -2.2, 2.2)
			ex = clampf(ex, min_x, max_x)
			dir = -1 if tx < ex else 1
			if reloj > 36:
				var d := cj.get_center() - Vector2(ex + W / 2.0, ey + H / 2.0)
				var l := maxf(d.length(), 1.0)
				var sp := 4.0 + lvl * 0.6
				vx = d.x / l * sp
				vy = maxf(1.5, d.y / l * sp)
				estado = "picado"
				reloj = 0
				Sonido.tocar("graznido")
		"picado":
			ex = clampf(ex + vx, min_x, max_x)
			ey += vy
			if ey + H >= suelo_y:
				ey = suelo_y - H
				estado = "suelo"
				reloj = 0
				Sonido.tocar("golpazo")
				nivel.particula("polvo", Vector2(ex + 4.0, suelo_y - 3.0))
				nivel.particula("polvo", Vector2(ex + W - 4.0, suelo_y - 3.0))
		"suelo":
			if reloj > 80 - lvl * 15:
				estado = "sube"
				reloj = 0
		"sube":
			ey -= 1.8
			if ey <= y0:
				ey = y0
				estado = "vuela"
				reloj = 0
				vx = (-1.0 if cj.position.x < ex else 1.0) * 1.4
		"herida":
			ey = maxf(y0, ey - 2.2)
			if reloj > 50:
				estado = "vuela"
				reloj = 0
		"vencida":
			vy += 0.25
			ey += vy
			ex += vx
			if reloj > 120:
				vivo = false
				nivel.jefe_vencido()
				queue_free()
				return
	_colocar()
	_dibujo()


## Tizón ha cruzado la puerta: se cierra la sala y se mide hasta dónde puede volar.
func _empezar(puerta: Vector2i) -> void:
	nivel.empezar_jefe(self)
	var zona: Rect2 = nivel.zona_de(global_position).rect
	var ultima_x := int(zona.end.x / 16.0) - 1
	var fila := floori((y0 + H / 2.0) / 16.0)      # la pared de la sala, a la altura a la que vuela
	var rx := puerta.x + 2
	while rx < ultima_x and not nivel.es_solido(Vector2i(rx, fila)):
		rx += 1
	min_x = (puerta.x + 1) * 16.0 + 2.0
	max_x = rx * 16.0 - W - 2.0
	var fy := floori((y0 + H) / 16.0)
	var cx := floori((ex + W / 2.0) / 16.0)
	while fy < int(zona.end.y / 16.0) and not nivel.es_solido(Vector2i(cx, fy)):
		fy += 1
	suelo_y = fy * 16.0
	estado = "vuela"
	reloj = 0
	vx = 1.4


func herir() -> void:
	estado = "herida"
	reloj = 0


func vencer(lado: float) -> void:
	estado = "vencida"
	reloj = 0
	vy = -4.0
	vx = lado * 0.6
	z_index = 5


func _dibujo() -> void:
	sprite.visible = not (estado == "herida" and (t & 2) != 0)
	var f := 0
	if estado == "picado":
		f = 2
	elif estado == "suelo":
		f = 3
	elif estado in ["vencida", "herida"]:
		f = 4
	else:
		f = 0 if ((t >> 3) & 1) != 0 else 1
	sprite.frame = f
	sprite.position = Vector2(0, -12 + (2 if f == 3 else 0))
	sprite.flip_h = dir > 0
	sprite.flip_v = estado == "vencida"


func _draw() -> void:
	var g := Engine.get_physics_frames()
	if estado == "suelo":
		for i in 3:
			var a := g * 0.12 + i * 2.1
			draw_rect(Rect2(roundf(-4.0 + cos(a) * 10.0), roundf(-24.0 + sin(a) * 3.0), 2, 2), Color("ffd23f"))
	if estado == "apunta" and ((t >> 2) & 1) != 0:
		FuentePixel.dibujar(self, "!", Vector2(-3, -30), Color("ff5a5a"))
