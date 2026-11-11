# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/tactil.gd
#  Qué es:   Mandos táctiles: cruceta o joystick y botones A, B, X e Y
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends CanvasLayer
## Botones táctiles, como un mando: a la izquierda una cruceta o un joystick (se
## elige en Opciones) y a la derecha cuatro botones en rombo: A salta, B da la
## vuelta, X e Y corren. Arriba a la derecha, la pausa. Se ven en el mapa y
## mientras se juega, si la pantalla es táctil (o si se fuerzan en Opciones).
## Admite varios dedos a la vez. Un dedo en los botones pulsa todos los que toca y se
## puede deslizar de uno a otro: con el pulgar entre A y X se salta y se corre a la vez.

const CENTRO_IZQ := Vector2(44, 178)
const RADIO_CRUZ := 34.0          # mitad del lado de la cruceta
const RADIO_PALANCA := 32.0
const RECORRIDO_PALANCA := 16.0
const CENTRO_BOTONES := Vector2(340, 178)
const SEPARACION := 25.0
const RADIO_BOTON := 13.0
const PAUSA := Rect2(352, 28, 26, 16)
const BOTONES := {
	"a": ["saltar", Vector2(0, 1), Color("d9432f")],
	"b": ["vuelta", Vector2(1, 0), Color("f2c94c")],
	"x": ["correr", Vector2(-1, 0), Color("2e6fb7")],
	"y": ["correr", Vector2(0, -1), Color("4f9a5a")],
}
const DIRECCIONES := ["izquierda", "derecha", "arriba", "abajo"]

var principal: Node = null
var _dibujo: Node2D
var _dedos := {}                  # índice del dedo -> {"que": "cruz"|"palanca"|"botones"|"pausa", "dir": {...}, "pulsa": [...], "pos": Vector2}
var _pulsadas := {}               # acciones que mantenemos pulsadas nosotros
var _forzar := false              # alguien ha tocado la pantalla (modo automático)


func _ready() -> void:
	_dibujo = Node2D.new()
	add_child(_dibujo)
	_dibujo.draw.connect(_pintar)


func _visible() -> bool:
	if principal == null or not (principal.estado in ["jugando", "mapa"]):
		return false
	if principal.estado == "jugando" and principal.nivel and principal.nivel.estado == "pausa":
		return false
	return Juego.con_tactil() or (_forzar and Juego.opciones.tactil == "auto")


func _process(_delta: float) -> void:
	var v := _visible()
	if not v and not _dedos.is_empty():
		_dedos.clear()
		_aplicar()
	_dibujo.visible = v
	_dibujo.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_forzar = true
	if not _visible():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var que := _zona(event.position)
			if que == "":
				return
			_dedos[event.index] = {"que": que, "pos": event.position, "dir": {}}
			_actualizar_dedo(event.index, event.position)
			get_viewport().set_input_as_handled()
		elif _dedos.has(event.index):
			_dedos.erase(event.index)
			_aplicar()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _dedos.has(event.index):
		_actualizar_dedo(event.index, event.position)
		get_viewport().set_input_as_handled()


## ¿Qué control hay en ese punto de la pantalla?
func _zona(p: Vector2) -> String:
	if PAUSA.grow(4).has_point(p):
		return "pausa"
	if p.distance_to(CENTRO_IZQ) <= 54.0:
		return "palanca" if Juego.opciones.mando == "joystick" else "cruz"
	if not _botones_en(p).is_empty():
		return "botones"
	return ""


## Botones que toca un dedo en ese punto. Cada botón se toca en un círculo algo mayor que su
## dibujo, así que entre dos botones vecinos (A y X, A y B...) se pulsan los dos.
func _botones_en(p: Vector2) -> Array:
	var out := []
	for k in BOTONES:
		if p.distance_to(CENTRO_BOTONES + BOTONES[k][1] * SEPARACION) <= RADIO_BOTON + 7.0:
			out.append(k)
	return out


## Direcciones a partir de un vector de -1 a 1; las diagonales solo cerca de los 45°
## para no agacharse sin querer (igual que en la web).
static func _direccion(n: Vector2, muerta: float, sesgo: float) -> Dictionary:
	return {
		"izquierda": n.x < -muerta and -n.x >= absf(n.y) * sesgo,
		"derecha": n.x > muerta and n.x >= absf(n.y) * sesgo,
		"arriba": n.y < -muerta and -n.y >= absf(n.x) * sesgo,
		"abajo": n.y > muerta and n.y >= absf(n.x) * sesgo,
	}


func _actualizar_dedo(i: int, p: Vector2) -> void:
	var d: Dictionary = _dedos[i]
	d.pos = p
	match d.que:
		"cruz":
			d.dir = _direccion((p - CENTRO_IZQ) / RADIO_CRUZ, 0.2, 0.8)
		"palanca":
			var v := (p - CENTRO_IZQ).limit_length(RECORRIDO_PALANCA)
			d.pos = CENTRO_IZQ + v
			d.dir = _direccion(v / RECORRIDO_PALANCA, 0.35, 0.7)
		"botones":
			d.pulsa = _botones_en(p)
	_aplicar()


func _aplicar() -> void:
	var quiero := {}
	for d in _dedos.values():
		match d.que:
			"cruz", "palanca":
				for k in DIRECCIONES:
					if d.dir.get(k, false):
						quiero[k] = true
			"pausa":
				quiero["pausa"] = true
			"botones":
				for k in d.get("pulsa", []):
					quiero[BOTONES[k][0]] = true
	Juego.salto_tactil = quiero.has("saltar") or quiero.has("vuelta")
	for accion in ["izquierda", "derecha", "arriba", "abajo", "saltar", "vuelta", "correr", "pausa"]:
		var si: bool = quiero.has(accion)
		if si and not _pulsadas.has(accion):
			Input.action_press(accion)
			_pulsadas[accion] = true
		elif not si and _pulsadas.has(accion):
			Input.action_release(accion)
			_pulsadas.erase(accion)


func _pulsado(que: String) -> bool:
	for d in _dedos.values():
		if d.que == que or (d.que == "botones" and que in d.get("pulsa", [])):
			return true
	return false


func _pintar() -> void:
	var c := _dibujo
	var oscuro := Color(0.1, 0.07, 0.04, 0.55)
	var claro := Color(1, 1, 1, 0.8)
	# cruceta o joystick
	var dirs := {}
	for d in _dedos.values():
		if d.que in ["cruz", "palanca"]:
			for k in DIRECCIONES:
				if d.dir.get(k, false):
					dirs[k] = true
	if Juego.opciones.mando == "joystick":
		c.draw_circle(CENTRO_IZQ, RADIO_PALANCA, oscuro)
		c.draw_arc(CENTRO_IZQ, RADIO_PALANCA, 0, TAU, 32, Color(1, 1, 1, 0.35), 1.0)
		var pomo := CENTRO_IZQ
		for d in _dedos.values():
			if d.que == "palanca":
				pomo = d.pos
		c.draw_circle(pomo, 12.0, Color(1, 1, 1, 0.75 if _pulsado("palanca") else 0.55))
		c.draw_circle(pomo, 7.0, Color(0.85, 0.85, 0.9, 0.8))
	else:
		var b := 13.0
		var l := RADIO_CRUZ
		c.draw_rect(Rect2(CENTRO_IZQ - Vector2(b, l), Vector2(b * 2, l * 2)), oscuro)
		c.draw_rect(Rect2(CENTRO_IZQ - Vector2(l, b), Vector2(l * 2, b * 2)), oscuro)
		var flechas := {"izquierda": Vector2(-1, 0), "derecha": Vector2(1, 0), "arriba": Vector2(0, -1), "abajo": Vector2(0, 1)}
		for k in flechas:
			var v: Vector2 = flechas[k]
			var centro: Vector2 = CENTRO_IZQ + v * (l - 9.0)
			var lado := Vector2(-v.y, v.x)
			var col := Color("ffd25e") if dirs.has(k) else claro
			c.draw_colored_polygon(PackedVector2Array([centro + v * 5.0, centro - v * 3.0 + lado * 5.0, centro - v * 3.0 - lado * 5.0]), col)
	# botones en rombo
	for k in BOTONES:
		var centro: Vector2 = CENTRO_BOTONES + BOTONES[k][1] * SEPARACION
		var pulsado := _pulsado(k)
		var col: Color = BOTONES[k][2]
		col.a = 0.95 if pulsado else 0.7
		c.draw_circle(centro, RADIO_BOTON + 1.0, Color(0.1, 0.07, 0.04, 0.6))
		c.draw_circle(centro, RADIO_BOTON, col)
		FuentePixel.dibujar(c, k.to_upper(), centro - Vector2(2, 3), Color.WHITE, 1, Color(0, 0, 0, 0.5))
	# pausa
	c.draw_rect(PAUSA, Color(0.1, 0.07, 0.04, 0.75 if _pulsado("pausa") else 0.55))
	c.draw_rect(Rect2(PAUSA.position + Vector2(10, 4), Vector2(2, 8)), claro)
	c.draw_rect(Rect2(PAUSA.position + Vector2(14, 4), Vector2(2, 8)), claro)
