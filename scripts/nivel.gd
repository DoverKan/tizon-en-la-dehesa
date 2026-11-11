# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/nivel.gd
#  Qué es:   Un nivel: losetas, cámara, bloques, agua, oscuridad, jefes e interacciones
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Nivel
extends Node2D
## Un nivel: losetas, entidades, cámara, tiempo, bloques, pasadizos, caseta y meta.
## Estructura de la escena:
##   Nivel (este script)
##   ├─ Decorado   TileMapLayer con flores, fachadas, setos, arcos... (no chocan)
##   ├─ Suelo      TileMapLayer con losetas sólidas, bloques, troncos, tablones y agua
##   ├─ Huesos     TileMapLayer con los huesitos (se recogen al tocarlos)
##   ├─ Zonas      un nodo Zona por zona (dehesa, madriguera, museo...)
##   └─ Entidades  Salida, enemigos, calcetines, caseta, meta, plataformas, pasadizos,
##                 decorado grande (farolas, naranjos...) y los jefes

signal superado
signal perdido

const T := 16
const VW := 384
const VH := 224
const PUNTOS_PISAR := [200, 400, 800, 1000, 2000, 4000, 8000, -1]   # -1 = vida extra
const PUNTOS_CALCETIN := [1000, 2000, 4000, 8000, -1]
const SOLIDOS := ["suelo", "corcho", "corcho_multi", "colmena", "colmena_poder", "colmena_disco", "usado", "piedra", "tronco", "invisible",
	"granito", "interruptor", "rojo", "azul", "columna", "desmorona"]
const ATLAS := {"usado": Vector2i(2, 8), "piedra": Vector2i(3, 8), "invisible": Vector2i(13, 10), "toldo_invisible": Vector2i(14, 10)}
## Lo que sigue activo aunque Tizón cambie de zona por un pasadizo
const SIEMPRE_ACTIVOS := ["calcetin", "caseta", "meta", "barra_fuego", "rastrillo", "micifuz", "urraca"]
## Enemigos a los que les afectan las conchas y las bolas de fuego
const DIANAS := ["pelotero", "caracol", "concha", "abejorro", "cardo", "murcielago", "micifuz", "paloma", "carpa", "pato", "milano", "urraca"]

const ESC_JUGADOR := "res://escenas/jugador.tscn"
const ESC_OBJETO := "res://escenas/entidades/objeto.tscn"
const ESC_DISCO := "res://escenas/entidades/disco.tscn"
const ESC_HUESO := "res://escenas/entidades/hueso_saltarin.tscn"

@export var nombre := "DEHESA 1-1"
@export var subtitulo := "LAS ENCINAS"
@export var dedicatoria := ""
## Si es mayor que cero, la zona principal avanza sola (píxeles por fotograma)
@export var avance := 0.0

@onready var suelo: TileMapLayer = $Suelo
@onready var capa_huesos: TileMapLayer = $Huesos
@onready var decorado: TileMapLayer = $Decorado
@onready var entidades: Node2D = $Entidades
@onready var zonas: Node2D = $Zonas

var jugador: Tizon
var camara: Camera2D
var fondo: Node2D
var hud: Node2D
var efectos: Node2D
var oscuridad: ColorRect
var estado := "jugando"     # jugando, pausa, muriendo, pasadizo, meta
var bloqueado := false      # la pantalla de opciones está abierta encima de la pausa
var tiempo := 300
var tic := 0
var prisa := false
var combo := 0
var congelar := 0
var temporizador := 0
var zona_actual: Node2D
var particulas: Array = []
var golpes: Array = []        # {celda, t, atlas, abajo}
var multi := {}
var pasadizo := {}
var meta_info := {}
var cam := Vector2.ZERO
var scroll := -1.0            # posición de la cámara en los niveles que avanzan solos
var jefe: Node2D = null       # Micifuz o la Urraca, cuando empieza la pelea
var sw := 0                   # interruptor de colores: 0 = rojos sólidos, 1 = azules sólidos
var celdas_color: Array = []  # [celda, "rojo" | "azul"]
var setas: Array = []         # casillas con setas luminosas (dan luz en la cueva)
var desmoronan := {}          # casilla -> fotogramas desde que Tizón la pisó
var luciernagas := 0


func _ready() -> void:
	# cámara
	camara = Camera2D.new()
	camara.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camara)
	camara.make_current()
	# fondo (detrás de todo), efectos, oscuridad de la cueva y marcador
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -10
	add_child(capa_fondo)
	fondo = Node2D.new()
	fondo.set_script(load("res://scripts/fondo.gd"))
	capa_fondo.add_child(fondo)
	efectos = Node2D.new()
	efectos.set_script(load("res://scripts/efectos.gd"))
	efectos.z_index = 10
	add_child(efectos)
	efectos.nivel = self
	var capa_oscura := CanvasLayer.new()
	capa_oscura.layer = 5
	add_child(capa_oscura)
	oscuridad = ColorRect.new()
	oscuridad.size = Vector2(VW, VH)
	oscuridad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/oscuridad.gdshader")
	oscuridad.material = mat
	oscuridad.visible = false
	capa_oscura.add_child(oscuridad)
	var capa_hud := CanvasLayer.new()
	capa_hud.layer = 10
	add_child(capa_hud)
	hud = Node2D.new()
	hud.set_script(load("res://scripts/hud.gd"))
	capa_hud.add_child(hud)
	hud.nivel = self
	# losetas que cambian: bloques de colores y setas
	for c in suelo.get_used_cells():
		var tipo := tipo_en(c)
		if tipo.begins_with("rojo"):
			celdas_color.append([c, "rojo"])
		elif tipo.begins_with("azul"):
			celdas_color.append([c, "azul"])
	for c in decorado.get_used_cells():
		var td := decorado.get_cell_tile_data(c)
		if td and String(td.get_custom_data("tipo")) == "seta":
			setas.append(c)
	_aplicar_colores()
	# entidades
	for e in entidades.get_children():
		e.set("nivel", self)
		if e.has_method("paso") and e.get("tipo") == "calcetin":
			if Juego.calcetines[Juego.nivel][e.indice]:
				e.queue_free()
	# Tizón
	jugador = load(ESC_JUGADOR).instantiate()
	jugador.nivel = self
	var salida := entidades.get_node_or_null("Salida") as Node2D
	var inicio := salida.position if salida else Vector2(40, 208)
	var caseta := _caseta()
	if Juego.desde_caseta and caseta:
		inicio = caseta.position + Vector2(-2, 0)
		caseta.encendida = true
	jugador.position = inicio
	add_child(jugador)
	zona_actual = zona_de(jugador.global_position)
	if avance > 0.0:
		scroll = clampf(jugador.caja().position.x - VW * 0.25, zonas.get_child(0).rect.position.x, zonas.get_child(0).rect.end.x - VW)
	_mover_camara(true)


func _caseta() -> Node2D:
	for e in entidades.get_children():
		if e.get("tipo") == "caseta":
			return e
	return null


# ------------------------------------------------------------------ casillas
func celda_en(p: Vector2) -> Vector2i:
	return suelo.local_to_map(suelo.to_local(p))


func tipo_en(celda: Vector2i) -> String:
	var td := suelo.get_cell_tile_data(celda)
	return "" if td == null else String(td.get_custom_data("tipo"))


func es_solido(celda: Vector2i) -> bool:
	return tipo_en(celda) in SOLIDOS


func poner_loseta(celda: Vector2i, tipo: String) -> void:
	if tipo == "":
		suelo.erase_cell(celda)
	else:
		suelo.set_cell(celda, 0, ATLAS[tipo])


# ------------------------------------------------------------------ zonas
func zona_de(p: Vector2) -> Node2D:
	for z in zonas.get_children():
		if z.rect.grow(64).has_point(p):
			return z
	return zonas.get_child(0)


func fondo_zona(nodo: Node2D) -> float:
	var z := zona_de(nodo.global_position)
	return z.rect.end.y


func en_pantalla(r: Rect2, margen: float) -> bool:
	return Rect2(cam, Vector2(VW, VH)).grow(margen).intersects(r)


## ¿La pantalla avanza sola ahora mismo? (solo en la zona principal de ese nivel)
func avanza_solo() -> bool:
	return scroll >= 0.0 and zona_actual == zonas.get_child(0)


# ------------------------------------------------------------------ bucle
func _physics_process(delta: float) -> void:
	if not bloqueado and Input.is_action_just_pressed("pausa") and estado == "jugando" and _reanudado != Engine.get_physics_frames():
		pausar()
	match estado:
		"jugando":
			if congelar > 0:
				congelar -= 1
				jugador.transformacion = congelar
				_actualizar_particulas()
			else:
				_plataformas()
				jugador.paso(delta)
				_actualizar_desmoronan()
				_entidades(delta)
				_interacciones()
				_actualizar_particulas()
				_mover_camara(false)
				tic += 1
				if estado == "jugando" and tic >= 40:
					tic = 0
					tiempo -= 1
					if tiempo == 100 and not prisa:
						prisa = true
						Sonido.tocar("prisa")
						Sonido.musica(true)
					if tiempo <= 0:
						tiempo = 0
						morir()
		"pasadizo":
			_paso_pasadizo()
			_actualizar_particulas()
		"muriendo":
			temporizador += 1
			if temporizador == 32:
				jugador.velocity.y = -330.0
			if temporizador > 32:
				jugador.velocity.y = minf(jugador.velocity.y + 864.0 * delta, 300.0)
				jugador.position.y += jugador.velocity.y * delta
			_actualizar_particulas()
			if temporizador > 175:
				estado = "fin"
				perdido.emit()
		"meta":
			_paso_meta(delta)
	hud.queue_redraw()
	efectos.queue_redraw()
	fondo.cam = cam
	fondo.tema = zona_actual.tema
	fondo.zona = zona_actual.rect
	fondo.queue_redraw()
	_oscuridad()


func pausar() -> void:
	estado = "pausa"
	Sonido.parar_musica()
	Sonido.tocar("pausa")


var _reanudado := -1


func seguir() -> void:
	_reanudado = Engine.get_physics_frames()
	estado = "jugando"
	Sonido.musica(prisa)
	Sonido.tocar("pausa")


func _plataformas() -> void:
	for e in entidades.get_children():
		if e.has_method("paso") and e.get("desplazamiento") != null:
			e.paso(0.0)


func _entidades(delta: float) -> void:
	var visto := Rect2(cam, Vector2(VW, VH)).grow(48)
	for e in entidades.get_children():
		if e.is_queued_for_deletion() or e.get("desplazamiento") != null or not e.has_method("paso"):
			continue
		if not e.vivo:
			continue
		if not e.activo:
			if visto.intersects(e.caja()) and zona_de(e.global_position) == zona_actual:
				e.activo = true
			else:
				continue
		if e.get("muriendo") != null and e.muriendo != "":
			e.paso_muriendo(delta)
		else:
			e.paso(delta)


func _mover_camara(instantaneo: bool) -> void:
	var z: Node2D = zona_actual
	var objetivo := Vector2(jugador.global_position.x - VW / 2.0 + jugador.mirando * 28.0, jugador.global_position.y - jugador.alto() / 2.0 - VH * 0.6)
	if instantaneo:
		cam = objetivo
	else:
		cam.x += clampf((objetivo.x - cam.x) * 0.1, -4.0, 4.0)
		cam.y += (objetivo.y - cam.y) * 0.08
	if avanza_solo():
		# el vuelo de las cigüeñas: la pantalla avanza sola y empuja a Tizón
		if not instantaneo and estado == "jugando":
			scroll = minf(z.rect.end.x - VW, scroll + avance)
		cam.x = scroll
	cam.x = clampf(cam.x, z.rect.position.x, z.rect.end.x - VW)
	cam.y = clampf(cam.y, z.rect.position.y, z.rect.end.y - VH)
	if z.tema == "castillo":
		# en la Alcazaba la cámara no baja: se ve el techo y el foso queda al fondo
		cam.y = z.rect.position.y
	camara.position = cam.round()


# ------------------------------------------------------------------ bloques
func golpear_bloque(celda: Vector2i, origen: String) -> void:
	var tipo := tipo_en(celda)
	var pos := Vector2(celda * T)
	match tipo:
		"colmena", "corcho_multi":
			hueso_saltarin(pos + Vector2(8, 0))
			var final := "usado"
			if tipo == "corcho_multi":
				var n: int = multi.get(celda, 8) - 1
				multi[celda] = n
				if n > 0:
					final = "corcho_multi"
			_rebote(celda, final)
		"colmena_poder", "colmena_disco":
			var clase := "galleta"
			if jugador.poder > 0:
				clase = "zorongollo" if tipo == "colmena_poder" else "disco"
			_sacar_objeto(clase, pos)
			_rebote(celda, "usado")
			Sonido.tocar("brotar")
		"interruptor":
			# cambia qué bloques de color son sólidos
			sw ^= 1
			_aplicar_colores()
			_rebote(celda, "interruptor")
			Sonido.tocar("interruptor")
			_desatascar()
		"corcho":
			if origen == "grande" or origen == "concha":
				romper(celda)
				return
			_rebote(celda, "corcho")
			Sonido.tocar("golpe")
		_:
			if origen != "concha":
				Sonido.tocar("golpe")
	_golpe_arriba(celda)


func _rebote(celda: Vector2i, final: String) -> void:
	var atlas := suelo.get_cell_atlas_coords(celda)
	if final == "usado":
		atlas = ATLAS.usado
	elif final == "corcho_multi":
		atlas = Vector2i(1, 8)
	elif final == "corcho":
		atlas = Vector2i(0, 8)
	elif final == "interruptor":
		atlas = Vector2i(6 + sw, 41)
	golpes.append({"celda": celda, "t": 0, "atlas": atlas, "abajo": false})
	suelo.set_cell(celda, 0, ATLAS.invisible)


## Los toldos se hunden un poco cuando Tizón rebota en ellos.
func hundir_toldos(desde: Vector2i, hasta: Vector2i) -> void:
	for x in range(desde.x, hasta.x + 1):
		var c := Vector2i(x, desde.y)
		if tipo_en(c) != "toldo" or suelo.get_cell_atlas_coords(c) == ATLAS.toldo_invisible:
			continue
		golpes.append({"celda": c, "t": 0, "atlas": suelo.get_cell_atlas_coords(c), "abajo": true})
		suelo.set_cell(c, 0, ATLAS.toldo_invisible)


func _aplicar_colores() -> void:
	for cc in celdas_color:
		var c: Vector2i = cc[0]
		if cc[1] == "rojo":
			suelo.set_cell(c, 0, Vector2i(8 if sw == 0 else 9, 41))
		else:
			suelo.set_cell(c, 0, Vector2i(10 if sw == 1 else 11, 41))


## Al cambiar los bloques de colores, si Tizón queda dentro de uno, sube hasta quedar libre.
func _desatascar() -> void:
	for k in 40:
		var c := jugador.caja()
		var a := celda_en(c.position)
		var b := celda_en(c.end - Vector2(0.01, 0.01))
		var dentro := false
		for y in range(a.y, b.y + 1):
			for x in range(a.x, b.x + 1):
				if es_solido(Vector2i(x, y)):
					dentro = true
		if not dentro:
			return
		jugador.position.y -= 1.0


func romper(celda: Vector2i) -> void:
	suelo.erase_cell(celda)
	var c := Vector2(celda * T) + Vector2(8, 8)
	for v in [Vector2(-84, -300), Vector2(84, -300), Vector2(-66, -180), Vector2(66, -180)]:
		particulas.append({"k": "trozo", "p": c, "v": v, "t": 0, "vida": 80})
	Juego.sumar_puntos(50)
	Sonido.tocar("romper")
	_golpe_arriba(celda)


func _golpe_arriba(celda: Vector2i) -> void:
	var zona := Rect2(Vector2(celda * T) + Vector2(0, -6), Vector2(T, 8))
	for e in entidades.get_children():
		if not e.has_method("caja") or not e.get("vivo") or not e.get("activo") or e.get("muriendo") != "":
			continue
		if e.tipo == "paloma" and zona.intersects(e.caja()):
			e.volar(-1.0 if e.global_position.x < celda.x * T + 8 else 1.0)
			pisoton(e.global_position)
		elif e.tipo in ["pelotero", "caracol", "concha"] and zona.intersects(e.caja()):
			e.matar_volteo(-1.0 if e.global_position.x < celda.x * T + 8 else 1.0)
			pisoton(e.global_position)
		elif e.tipo in ["galleta", "zorongollo"] and zona.intersects(e.caja()) and e.saliendo == 0:
			e.botar(celda.x * T + 8)
	var arriba := celda + Vector2i(0, -1)
	if capa_huesos.get_cell_source_id(arriba) != -1:
		capa_huesos.erase_cell(arriba)
		hueso_saltarin(Vector2(arriba * T) + Vector2(8, 8))


func _sacar_objeto(clase: String, pos: Vector2) -> void:
	var o: Node2D
	if clase == "disco":
		o = load(ESC_DISCO).instantiate()
	else:
		o = load(ESC_OBJETO).instantiate()
		o.clase = clase
		o.dir = -1 if jugador.global_position.x > pos.x + 8 else 1
	o.position = pos + Vector2(8, 15)
	anadir(o)


func hueso_saltarin(pos: Vector2) -> void:
	var h: Node2D = load(ESC_HUESO).instantiate()
	h.position = pos + Vector2(0, 2)
	anadir(h)
	recoger_hueso()


func anadir(nodo: Node2D) -> void:
	nodo.set("nivel", self)
	entidades.add_child(nodo)


# ------------------------------------------------------------------ piedras que se desmoronan
func desmoronar(celda: Vector2i) -> void:
	if not desmoronan.has(celda):
		desmoronan[celda] = 0


func _actualizar_desmoronan() -> void:
	for c in desmoronan.keys():
		var n: int = desmoronan[c] + 1
		if n > 28:
			suelo.erase_cell(c)
			desmoronan.erase(c)
			particulas.append({"k": "roca", "p": Vector2(c * T), "v": Vector2(0, 0.5), "t": 0, "vida": 70})
			if en_pantalla(Rect2(Vector2(c * T), Vector2(T, T)), 0.0):
				Sonido.tocar("derrumbe")
		else:
			desmoronan[c] = n
			suelo.set_cell(c, 0, Vector2i(13 if (n & 2) != 0 else 12, 41))


# ------------------------------------------------------------------ agua del Guadiana
## Altura de la superficie del agua en esa casilla, o -1 si no hay agua.
func superficie_agua(celda: Vector2i) -> float:
	if tipo_en(celda) != "agua":
		return -1.0
	var s := celda.y
	while tipo_en(Vector2i(celda.x, s - 1)) == "agua":
		s -= 1
	return s * float(T)


## Los enemigos y objetos que caen al río desaparecen (con una salpicadura).
func al_agua(e) -> bool:
	var c: Rect2 = e.caja()
	var sy := superficie_agua(celda_en(Vector2(c.get_center().x, c.end.y)))
	if sy < 0.0 or c.end.y <= sy + 4.0:
		return false
	if en_pantalla(c, 0.0):
		salpicar(Vector2(c.get_center().x, sy), true)
	e.quitar()
	return true


func salpicar(p: Vector2, flojo := false) -> void:
	for i in 7:
		particulas.append({"k": "gota", "p": p + Vector2((i - 3) * 2, 0), "v": Vector2((i - 3) * 0.35, -2.2 - (i % 3) * 0.7), "t": 0, "vida": 34})
	if not flojo:
		Sonido.tocar("chapoteo")
	elif en_pantalla(Rect2(p - Vector2(8, 8), Vector2(16, 16)), 0.0):
		Sonido.tocar("plof")


# ------------------------------------------------------------------ huesos y puntos
func recoger_huesos(r: Rect2) -> void:
	var a := capa_huesos.local_to_map(r.position)
	var b := capa_huesos.local_to_map(r.end - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			var c := Vector2i(x, y)
			if capa_huesos.get_cell_source_id(c) != -1:
				capa_huesos.erase_cell(c)
				recoger_hueso()
				particula("chispa", Vector2(c * T) + Vector2(8, 8))


func recoger_hueso() -> void:
	Juego.huesos += 1
	Juego.sumar_puntos(10)
	Sonido.tocar("hueso")
	if Juego.huesos >= 100:
		Juego.huesos -= 100
		vida_extra(jugador.global_position + Vector2(0, -30))


func vida_extra(p: Vector2) -> void:
	Juego.vidas = mini(Juego.VIDAS_MAX, Juego.vidas + 1)
	Sonido.tocar("vida")
	particulas.append({"k": "texto", "texto": "+1 VIDA", "p": p, "t": 0, "vida": 48})


func puntos(n: int, p: Vector2) -> void:
	if n < 0:
		vida_extra(p)
		return
	Juego.sumar_puntos(n)
	particulas.append({"k": "texto", "texto": str(n), "p": p, "t": 0, "vida": 48})


func pisoton(p: Vector2) -> void:
	puntos(PUNTOS_PISAR[mini(combo, PUNTOS_PISAR.size() - 1)], p + Vector2(-6, -20))
	combo += 1


func particula(k: String, p: Vector2) -> void:
	particulas.append({"k": k, "p": p, "t": 0, "vida": 16 if k != "humo" else 24})


## Partícula que se mueve sola (velocidad en píxeles por fotograma, como en la web)
func particula_v(k: String, p: Vector2, v: Vector2, vida: int, t0 := 0) -> void:
	particulas.append({"k": k, "p": p, "v": v, "t": t0, "vida": vida})


func humo(p: Vector2) -> void:
	particula("humo", p)


func corazones(p: Vector2) -> void:
	for i in 3:
		particula_v("corazon", p + Vector2(-6 + i * 6, 0), Vector2(0, -0.5), 46, -i * 6)


func plumas(p: Vector2) -> void:
	for i in 5:
		particula_v("pluma", p, Vector2((i - 2) * 0.5, -0.6 - i * 0.2), 40)


func _actualizar_particulas() -> void:
	for g in golpes:
		g.t += 1
		if g.t >= 10:
			suelo.set_cell(g.celda, 0, g.atlas)
	golpes = golpes.filter(func(g): return g.t < 10)
	for q in particulas:
		q.t += 1
		match q.k:
			"trozo", "rama":
				q.v.y += 1080.0 / 60.0
				q.p += q.v / 60.0
			"texto":
				q.p.y -= 0.8
			"gota", "piedrecita":
				q.v.y += 0.2
				q.p += q.v
			"roca":
				q.v.y = minf(q.v.y + 0.3, 6.0)
				q.p.y += q.v.y
			"pluma":
				q.v.y = minf(0.6, q.v.y + 0.04)
				q.p += Vector2(q.v.x + sin(q.t * 0.3) * 0.4, q.v.y)
			"corazon":
				if q.t >= 0:
					q.p.y += q.v.y
	particulas = particulas.filter(func(q): return q.t < q.vida)


# ------------------------------------------------------------------ Tizón
func herir() -> void:
	if jugador.invencible > 0 or estado != "jugando":
		return
	jugador.soltar_globo()
	if jugador.poder == 0:
		morir()
		return
	Sonido.tocar("perder_poder")
	jugador.poner_poder(1 if jugador.poder >= 2 else 0)
	congelar = 36
	jugador.invencible = 120
	jugador.soltar_concha()


func dar_poder(p: int, pos: Vector2) -> void:
	puntos(1000, pos)
	if jugador.poder == p or (p == 1 and jugador.poder > 0):
		return
	Sonido.tocar("poder")
	jugador.poner_poder(p)
	congelar = 36


func morir() -> void:
	if estado != "jugando":
		return
	estado = "muriendo"
	temporizador = 0
	jugador.globo = {}
	jugador.muerto = true
	jugador.velocity = Vector2.ZERO
	jugador.invencible = 0
	jugador.soltar_concha()
	jugador.z_index = 20
	Juego.poder = 0
	Sonido.parar_musica()
	Sonido.tocar("morir")


func plataforma_bajo(j: Tizon, pies_antes: float) -> Variant:
	var c := j.caja()
	for e in entidades.get_children():
		if e.get("desplazamiento") == null:
			continue
		var top: float = e.position.y
		if c.end.x > e.position.x and c.position.x < e.position.x + e.ancho and pies_antes <= top + 5.0 and c.end.y >= top:
			return e
	return null


# ------------------------------------------------------------------ pasadizos
func intentar_pasadizo(j: Tizon) -> bool:
	for e in entidades.get_children():
		if e.get("numero") == null or e.is_queued_for_deletion():
			continue
		if absf(j.global_position.x - e.global_position.x) <= 8.0 and absf(j.global_position.y - e.global_position.y) <= 2.0:
			var destino := _otro_pasadizo(e)
			if destino == null:
				return false
			j.agachado = false
			j._ajustar_forma()
			j.velocity = Vector2.ZERO
			j.girando = false
			j.global_position.x = e.global_position.x
			var es_puerta: bool = e.get("puerta") == true
			if not es_puerta:
				j.z_index = -1
			estado = "pasadizo"
			pasadizo = {"fase": "entra", "t": 0, "boca": e.global_position.y, "destino": destino, "puerta": es_puerta}
			Sonido.tocar("pasadizo")
			return true
	return false


func _otro_pasadizo(p: Node2D) -> Node2D:
	for e in entidades.get_children():
		if e != p and e.get("numero") == p.numero:
			return e
	return null


## Oscuridad del fundido al cruzar la puerta secreta (0 nada, 1 negro)
func fundido() -> float:
	if estado != "pasadizo" or not pasadizo.get("puerta", false):
		return 0.0
	return clampf((pasadizo.t if pasadizo.fase == "entra" else 24 - pasadizo.t) / 24.0, 0.0, 1.0)


func _paso_pasadizo() -> void:
	pasadizo.t += 1
	if pasadizo.get("puerta", false):
		# puerta: fundido a negro, cambio de zona y fundido de vuelta
		if pasadizo.fase == "entra" and pasadizo.t >= 24:
			var d: Node2D = pasadizo.destino
			jugador.global_position = d.global_position
			jugador.velocity = Vector2.ZERO
			jugador.mirando = 1
			zona_actual = zona_de(d.global_position)
			for e in entidades.get_children():
				if e.get("activo") != null and e.get("tipo") not in SIEMPRE_ACTIVOS:
					e.activo = false
			pasadizo.fase = "sale"
			pasadizo.t = 0
			_mover_camara(true)
		elif pasadizo.fase == "sale" and pasadizo.t >= 24:
			jugador.en_suelo = true
			jugador.bloqueo_abajo = true
			estado = "jugando"
		_mover_camara(false)
		return
	if pasadizo.fase == "entra":
		jugador.position.y += 0.55
		if jugador.position.y > pasadizo.boca + jugador.alto() + 4.0:
			var d: Node2D = pasadizo.destino
			jugador.global_position = Vector2(d.global_position.x, d.global_position.y + jugador.alto() + 4.0)
			jugador.mirando = 1
			zona_actual = zona_de(d.global_position)
			for e in entidades.get_children():
				if e.get("activo") != null and e.get("tipo") not in SIEMPRE_ACTIVOS:
					e.activo = false
			pasadizo.fase = "sale"
			pasadizo.boca = d.global_position.y
			pasadizo.t = 0
			_mover_camara(true)
			Sonido.tocar("pasadizo")
	elif pasadizo.t > 10:
		jugador.position.y -= 0.55
		if jugador.position.y <= pasadizo.boca:
			jugador.position.y = pasadizo.boca
			jugador.z_index = 0
			jugador.en_suelo = true
			jugador.bloqueo_abajo = true
			estado = "jugando"
	_mover_camara(false)


# ------------------------------------------------------------------ jefes
func puertas() -> Array:
	var r := []
	for e in entidades.get_children():
		if e.get("tipo") == "puerta":
			r.append(e.celda())
	return r


## Tizón ha entrado en la sala: se cierran las puertas y la música se acelera.
func empezar_jefe(e: Node2D) -> void:
	for c in puertas():
		poner_loseta(c, "piedra")
		humo(Vector2(c * T) + Vector2(8, 8))
	Sonido.tocar("golpazo")
	Sonido.tocar("graznido" if e.tipo == "urraca" else "maullido")
	Sonido.musica(true)
	jefe = e


func jefe_vencido() -> void:
	_empezar_meta()


# ------------------------------------------------------------------ meta
func _empezar_meta() -> void:
	if estado != "jugando":
		return
	estado = "meta"
	temporizador = 0
	jugador.automatico = true
	jugador.invencible = 0
	jugador.soltar_concha()
	Sonido.parar_musica()
	Sonido.tocar("nivel_superado")
	meta_info = {"fase": "andar", "bono": 0}


func _paso_meta(delta: float) -> void:
	temporizador += 1
	_plataformas()
	jugador.paso(delta)
	_actualizar_desmoronan()
	_entidades(delta)
	_actualizar_particulas()
	_mover_camara(false)
	# en Badajoz, Tizón entra a desayunar en The Cereal Cafe
	for e in entidades.get_children():
		if e.get("tipo") == "cafe" and not jugador.oculto and jugador.global_position.x >= e.puerta_x:
			jugador.oculto = true
			jugador.velocity.x = 0.0
			Sonido.tocar("ladrido")
	if meta_info.fase == "andar" and temporizador > 150:
		meta_info.fase = "contar"
	if meta_info.fase == "contar":
		if tiempo > 0:
			var d := mini(tiempo, 3)
			tiempo -= d
			Juego.sumar_puntos(d * 50)
			meta_info.bono += d * 50
			if temporizador % 3 == 0:
				Sonido.tocar("tic")
		else:
			meta_info.fase = "hecho"
			temporizador = 0
			Juego.guardar_record()
			Juego.poder = jugador.poder
			Juego.nivel_superado()
	if meta_info.fase == "hecho" and temporizador > 50:
		if not bloqueado and (Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("pausa") or _toque()):
			estado = "fin"
			superado.emit()


## La escena principal avisa de los toques en la pantalla (los de los botones táctiles no cuentan).
var tocado := false


func _toque() -> bool:
	var t := tocado
	tocado = false
	return t


# ------------------------------------------------------------------ oscuridad de la cueva
## En las cuevas de Fuentes de León todo está a oscuras salvo la luz de Tizón,
## las luciérnagas, las bolas de fuego, los calcetines, las setas y las antorchas.
func _oscuridad() -> void:
	var a_oscuras: bool = zona_actual.tema == "gruta"
	oscuridad.visible = a_oscuras
	if not a_oscuras:
		return
	var luces := PackedVector3Array()
	var poner := func(p: Vector2, r: float) -> void:
		var q := p - cam.round()
		if q.x > -r and q.x < VW + r and q.y > -r and q.y < VH + r and luces.size() < 32:
			luces.append(Vector3(roundf(q.x), roundf(q.y), r))
	if not jugador.muerto or temporizador < 60:
		poner.call(jugador.caja().get_center(), 84.0 + luciernagas * 16.0)
	for e in entidades.get_children():
		if e.is_queued_for_deletion() or e.get("vivo") == false:
			continue
		match e.get("tipo"):
			"luciernaga":
				if not e.cogida:
					poner.call(e.global_position - Vector2(1, 1), 22.0 + ((e.t >> 4) & 1) * 3.0)
			"fuego":
				poner.call(e.global_position + Vector2(0, -4), 22.0)
			"calcetin":
				poner.call(e.global_position + Vector2(0, -7), 18.0)
			"antorcha":
				poner.call(e.global_position + Vector2(8, 2), 48.0)
	for c in setas:
		poner.call(Vector2(c * T) + Vector2(8, 8), 44.0)
	var mat: ShaderMaterial = oscuridad.material
	var lista := []
	for l in luces:
		lista.append(l)
	while lista.size() < 32:
		lista.append(Vector3(-9999, -9999, 0))
	mat.set_shader_parameter("luces", lista)
	mat.set_shader_parameter("cuantas", luces.size())


# ------------------------------------------------------------------ interacciones
func _interacciones() -> void:
	if estado != "jugando":
		return
	var j := jugador
	var cj := j.caja()
	# pinchos: hacen daño si Tizón se mete en la mitad de abajo de la casilla
	var a := celda_en(cj.position)
	var b := celda_en(cj.end - Vector2(0.01, 0.01))
	for x in range(a.x, b.x + 1):
		if tipo_en(Vector2i(x, b.y)) == "pinchos" and cj.end.y > b.y * T + 7:
			herir()
			break
	for e in entidades.get_children():
		if not e.has_method("caja") or e.is_queued_for_deletion():
			continue
		if not e.get("vivo") or not e.get("activo") or e.get("muriendo") != "":
			continue
		var toca: bool = cj.intersects(e.caja())
		match e.tipo:
			"barra_fuego":
				if e.toca(cj):
					herir()
			"rastrillo":
				if toca and cj.grow(-1.0).intersects(e.caja_dano()):
					herir()
			"micifuz":
				if not toca or e.estado in ["espera", "vencido"]:
					continue
				if j.pisando(e) and e.estado != "herido":
					e.vidas -= 1
					j.velocity.y = -360.0
					j.en_suelo = false
					Sonido.tocar("golpe_jefe")
					puntos(1000 if e.vidas > 0 else 5000, e.global_position + Vector2(-8, -32))
					if e.vidas <= 0:
						e.vencer(float(j.mirando))
						Sonido.tocar("maullido")
						Sonido.parar_musica()
					else:
						e.herir(-1.0 if e.global_position.x < j.global_position.x else 1.0)
				elif e.estado != "herido":
					herir()
			"urraca":
				if not toca or e.estado in ["espera", "vencida", "herida"]:
					continue
				if j.pisando(e) and e.estado in ["suelo", "sube"]:
					e.vidas -= 1
					j.velocity.y = -360.0
					j.en_suelo = false
					Sonido.tocar("golpe_jefe")
					puntos(1000 if e.vidas > 0 else 5000, e.global_position + Vector2(-8, -26))
					if e.vidas <= 0:
						e.vencer(float(j.mirando))
						Sonido.tocar("graznido")
						Sonido.parar_musica()
					else:
						e.herir()
				elif j.pisando(e):
					j.rebotar()      # volando no le hace nada: Tizón rebota
				else:
					herir()
			"paloma":
				if not toca:
					continue
				if j.pisando(e):
					e.volar(float(j.mirando))
					pisoton(e.global_position)
					j.rebotar(j.girando)
					Sonido.tocar("pisar")
				else:
					herir()
			"carpa":
				if not toca or e.estado == "espera":
					continue
				if j.pisando(e):
					if j.girando:
						humo(e.global_position + Vector2(0, -8))
						e.quitar()
						j.rebotar(true)
						puntos(200, e.global_position + Vector2(-6, -20))
					else:
						e.matar_volteo(j.mirando)
						pisoton(e.global_position)
						j.rebotar()
					Sonido.tocar("pisar")
				else:
					herir()
			"globo":
				if j.globo.is_empty() and j.concha == null and cj.intersects(e.caja_cuerda()):
					e.quitar()
					j.coger_globo(e.color)
					Sonido.tocar("tic")
			"estalactita":
				if toca:
					herir()
			"luciernaga":
				if not e.cogida and cj.intersects(e.caja_coger()):
					e.cogida = true
					e.hueco = luciernagas
					luciernagas = mini(4, luciernagas + 1)
					puntos(100, e.global_position + Vector2(-6, -8))
					Sonido.tocar("campanilla")
			"pelotero", "abejorro", "murcielago", "pato", "milano":
				if not toca:
					continue
				if j.pisando(e):
					if j.girando:
						humo(e.global_position + Vector2(0, -6))
						e.quitar()
						j.rebotar(true)
						puntos(200, e.global_position + Vector2(-6, -20))
					elif e.tipo == "pelotero":
						e.aplastar()
						pisoton(e.global_position)
						j.rebotar()
					else:
						e.matar_volteo(j.mirando)
						pisoton(e.global_position)
						j.rebotar()
					Sonido.tocar("pisar")
				else:
					herir()
			"caracol":
				if not toca:
					continue
				if j.pisando(e):
					if j.girando:
						humo(e.global_position + Vector2(0, -6))
						e.quitar()
						j.rebotar(true)
						puntos(200, e.global_position + Vector2(-6, -20))
					else:
						e.meterse()
						pisoton(e.global_position)
						j.rebotar()
					Sonido.tocar("pisar")
				else:
					herir()
			"concha":
				if not toca or e.en_boca:
					continue
				if not e.pateada:
					if e.gracia > 0:
						continue
					if Input.is_action_pressed("correr") and j.concha == null and not j.agachado and not j.automatico:
						j.concha = e
						e.en_boca = true
						e.quieta = 0
						continue
					var lado := 1.0 if j.global_position.x < e.global_position.x else -1.0
					e.lanzar(lado, 0.0, 0.0)
					e.gracia = 14
					Sonido.tocar("patada")
					puntos(400, e.global_position + Vector2(-6, -20))
					if j.pisando(e):
						j.rebotar()
				elif j.pisando(e):
					if j.girando:
						humo(e.global_position + Vector2(0, -6))
						e.quitar()
						j.rebotar(true)
					else:
						e.lanzar(0.0, 0.0, 0.0)
						e.gracia = 10
						j.rebotar()
						pisoton(e.global_position)
					Sonido.tocar("pisar")
				elif e.gracia <= 0:
					herir()
			"cardo":
				if not toca or e.fuera < 6.0:
					continue
				if j.girando and j.pisando(e):
					humo(e.global_position + Vector2(0, -10))
					e.quitar()
					j.rebotar(true)
					Sonido.tocar("pisar")
					puntos(400, e.global_position + Vector2(-6, -30))
				else:
					herir()
			"galleta":
				if toca and e.saliendo == 0:
					e.quitar()
					dar_poder(1, e.global_position + Vector2(-6, -20))
			"zorongollo":
				if toca and e.saliendo == 0:
					e.quitar()
					dar_poder(2, e.global_position + Vector2(-6, -20))
			"disco":
				if toca and e.saliendo <= 8:
					e.quitar()
					dar_poder(3, e.global_position + Vector2(-6, -20))
			"calcetin":
				if toca:
					e.quitar()
					Juego.calcetines[Juego.nivel][e.indice] = true
					var n := 0
					for c in Juego.calcetines[Juego.nivel]:
						if c:
							n += 1
					puntos(PUNTOS_CALCETIN[n - 1], e.global_position + Vector2(-6, -24))
					Sonido.tocar("calcetin")
					for i in 6:
						particulas.append({"k": "chispa", "p": e.global_position + Vector2(cos(i) * 10.0, -8.0 + sin(i) * 10.0), "t": -i * 2, "vida": 16})
			"caseta":
				if not e.encendida and cj.end.x > e.global_position.x - 5.0 and cj.position.x < e.global_position.x + 5.0 and cj.end.y > e.global_position.y - 32.0:
					e.encendida = true
					e.animacion = 40
					Sonido.tocar("caseta")
					Sonido.tocar("ladrido")
					puntos(1000, e.global_position + Vector2(-10, -40))
					if j.poder == 0:
						j.poner_poder(1)
						congelar = 36
					Juego.poder = j.poder
					Juego.desde_caseta = true
					Juego.cp_nivel = Juego.nivel
					Juego.guardar(Juego.nivel, true)
	# la meta
	for e in entidades.get_children():
		if e.get("tipo") != "meta":
			continue
		if e.barra_puesta and cj.intersects(e.caja_barra()):
			var k := clampf((-18.0 - e.barra_y) / 94.0, 0.0, 1.0)
			var pts := maxi(100, int(roundf((100.0 + k * 4900.0) / 100.0)) * 100)
			e.barra_puesta = false
			puntos(pts, j.global_position + Vector2(-6, -30))
			particulas.append({"k": "rama", "p": e.global_position + Vector2(6, e.barra_y), "v": Vector2(90, -180), "t": 0, "vida": 90})
			_empezar_meta()
		elif j.global_position.x > e.global_position.x + 2.0 * T:
			_empezar_meta()
	_conchas_y_fuego()


func _conchas_y_fuego() -> void:
	var lista := entidades.get_children()
	for s in lista:
		if s.get("vivo") != true or s.get("activo") != true or s.get("muriendo") != "" or s.is_queued_for_deletion():
			continue
		var es_concha: bool = s.tipo == "concha" and (s.pateada or s.en_boca)
		if not es_concha and s.tipo != "fuego":
			continue
		for e in lista:
			if e == s or e.get("vivo") != true or e.get("activo") != true or e.get("muriendo") != "" or e.is_queued_for_deletion():
				continue
			if e.get("tipo") not in DIANAS:
				continue
			if e.tipo in ["micifuz", "urraca"]:
				# a los jefes no les hacen nada: las bolas de fuego se deshacen al tocarlos
				if s.tipo == "fuego" and e.estado != "espera" and s.caja().intersects(e.caja()):
					humo(s.global_position + Vector2(0, -4))
					s.quitar()
					break
				continue
			if e.tipo == "carpa" and e.estado == "espera":
				continue
			if e.tipo == "cardo" and e.fuera < 6.0:
				continue
			if e == jugador.concha and s.tipo == "fuego":
				continue
			if not s.caja().intersects(e.caja()):
				continue
			var lado := signf(s.velocity.x) if s.velocity.x != 0.0 else float(jugador.mirando)
			if s.tipo == "fuego":
				humo(s.global_position + Vector2(0, -4))
				s.quitar()
				if e.tipo == "cardo":
					humo(e.global_position + Vector2(0, -10))
					e.quitar()
				elif e.tipo == "paloma":
					e.volar(signf(s.velocity.x))
				else:
					e.matar_volteo(signf(s.velocity.x))
					hueso_saltarin(e.global_position + Vector2(0, -16))
				puntos(200, e.global_position + Vector2(-6, -20))
				Sonido.tocar("patada")
				break
			var pts: int = PUNTOS_PISAR[mini(s.cadena, PUNTOS_PISAR.size() - 1)]
			s.cadena += 1
			if e.tipo == "cardo":
				humo(e.global_position + Vector2(0, -10))
				e.quitar()
			elif e.tipo == "paloma":
				e.volar(lado)
			else:
				e.matar_volteo(lado)
			puntos(pts, e.global_position + Vector2(-6, -20))
			Sonido.tocar("patada")
			if s.en_boca or e.tipo == "concha":
				if s == jugador.concha:
					jugador.concha = null
				s.en_boca = false
				s.matar_volteo(-lado)
				break
