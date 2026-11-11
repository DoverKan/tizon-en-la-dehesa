# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/tizon.gd
#  Qué es:   Tizón, el protagonista: movimiento, saltos, poderes y globo
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Tizon
extends CharacterBody2D
## Tizón, el schnauzer mini. Física al estilo de los plataformas de 16 bits:
## carrera con medidor, salto que crece si mantienes el botón, margen para
## saltar justo al borde, vuelta en el aire, concha en la boca y pasadizos.

# --- Física (píxeles por segundo, a 60 fotogramas por segundo)
const GRAV := 1350.0
const GRAV_MANTENIDO := 684.0
const CAIDA_MAX := 276.0
const ANDAR := 90.0
const CORRER := 150.0
const SPRINT := 186.0
const ACEL_ANDAR := 252.0
const ACEL_CORRER := 324.0
const ACEL_AIRE := 270.0
const FRENO := 270.0
const DERRAPE := 720.0
const SALTO := 306.0
const SALTO_VUELTA := 282.0
const PLANEO := 54.0
const MEDIDOR_LLENO := 40
const ANCHO := 12.0
const ALTO_PEQ := 13.0
const ALTO_GRANDE := 19.0

const TEX_PEQ := preload("res://assets/sprites/tizon_pequeno.png")
const TEX_GRANDE := [
	preload("res://assets/sprites/tizon_grande_normal.png"),
	preload("res://assets/sprites/tizon_grande_normal.png"),
	preload("res://assets/sprites/tizon_grande_fuego.png"),
	preload("res://assets/sprites/tizon_grande_disco.png"),
]
const TEX_DISCO := preload("res://assets/sprites/disco.png")
const TEX_GLOBO := preload("res://assets/sprites/globo.png")
const REBOTE_TOLDO := 372.0
const SUBIDA_GLOBO := 72.0
const ESCENA_FUEGO := "res://escenas/entidades/bola_fuego.tscn"
enum { QUIETO, PASO_A, PASO_B, SALTANDO, ESPECIAL }  # ESPECIAL: muerto (pequeño) o agachado (grande)

var nivel: Nivel = null
var poder := 0
var agachado := false
var mirando := 1
var girando := false
var en_suelo := false
var coyote := 0
var buffer_salto := 0
var buffer_vuelta := 0
var min_mantener := 0           # fotogramas en que el salto sube como si se mantuviera el botón
var invencible := 0
var medidor := 0
var anim := 0.0
var concha = null
var plataforma = null
var muerto := false
var automatico := false
var bloqueo_abajo := false
var derrapando := false
var transformacion := 0      # fotogramas de parpadeo al crecer o encoger
var poder_anterior := 0
var globo := {}              # colgado de un globo de la feria: {"t": fotogramas que quedan, "c": color}
var oculto := false
var _adornos: Node2D             # gafas, bufanda y gorro, encima del dibujo (huevos de pascua)
var _libelula := Vector2.INF     # posición de la libélula del modo piloto, en coordenadas del nivel          # ya ha entrado en The Cereal Cafe

@onready var sprite: Sprite2D = $Sprite
@onready var forma: CollisionShape2D = $Forma


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(10)
	forma.shape = RectangleShape2D.new()
	poder = Juego.poder
	_adornos = Node2D.new()
	_adornos.name = "Adornos"
	add_child(_adornos)
	_adornos.draw.connect(_dibujar_adornos)
	_ajustar_forma()
	_ajustar_sprite()


func alto() -> float:
	return ALTO_PEQ if (poder == 0 or agachado) else ALTO_GRANDE


func caja() -> Rect2:
	var h := alto()
	return Rect2(global_position.x - ANCHO / 2.0, global_position.y - h, ANCHO, h)


func _ajustar_forma() -> void:
	var h := alto()
	(forma.shape as RectangleShape2D).size = Vector2(ANCHO, h)
	forma.position = Vector2(0, -h / 2.0)


func poner_poder(p: int, con_animacion := true) -> void:
	poder_anterior = poder
	poder = p
	Juego.poder = p
	_ajustar_forma()
	if con_animacion:
		transformacion = 36


# ---------------------------------------------------------------- entrada
func _pulsado(accion: String) -> bool:
	return not automatico and Input.is_action_pressed(accion)


func _recien(accion: String) -> bool:
	return not automatico and Input.is_action_just_pressed(accion)


# ---------------------------------------------------------------- paso
func paso(delta: float) -> void:
	if not bloqueo_abajo or not Input.is_action_pressed("abajo"):
		bloqueo_abajo = bloqueo_abajo and Input.is_action_pressed("abajo")
	if en_suelo and not automatico and Input.is_action_pressed("abajo") and not bloqueo_abajo and concha == null:
		if nivel.intentar_pasadizo(self):
			return

	var dir := (0 if oculto else 1) if automatico else int(_pulsado("derecha")) - int(_pulsado("izquierda"))
	if en_suelo and not automatico:
		agachado = _pulsado("abajo")
	_ponerse_de_pie()

	# carrera y medidor de velocidad
	var corre := _pulsado("correr")
	if en_suelo:
		if corre and dir != 0 and absf(velocity.x) >= CORRER - 3.0:
			medidor = mini(MEDIDOR_LLENO + 20, medidor + 1)
		else:
			medidor = maxi(0, medidor - 1)
	var maximo := ANDAR if (automatico or not corre) else (SPRINT if medidor >= MEDIDOR_LLENO else CORRER)
	derrapando = false
	if dir != 0 and not (agachado and en_suelo):
		if en_suelo and velocity.x * dir < 0:
			velocity.x += dir * DERRAPE * delta
			derrapando = absf(velocity.x) > 36.0
			if derrapando and Engine.get_physics_frames() % 6 == 0:
				nivel.particula("polvo", global_position + Vector2(0, -2))
		else:
			var acel := (ACEL_CORRER if corre else ACEL_ANDAR) if en_suelo else ACEL_AIRE
			if velocity.x * dir < maximo:
				velocity.x = clampf(velocity.x + dir * acel * delta, -maximo, maximo)
			elif en_suelo:
				velocity.x = move_toward(velocity.x, dir * maximo, 144.0 * delta)
		if not girando:
			mirando = dir
	else:
		velocity.x = move_toward(velocity.x, 0.0, (180.0 if agachado else FRENO) * delta if en_suelo else 72.0 * delta)

	# salto con margen (coyote) y búfer
	if _recien("saltar"):
		buffer_salto = 8
	elif buffer_salto > 0:
		buffer_salto -= 1
	if _recien("vuelta"):
		buffer_vuelta = 8
	elif buffer_vuelta > 0:
		buffer_vuelta -= 1
	if en_suelo:
		coyote = 8
	elif coyote > 0:
		coyote -= 1
	if (buffer_salto > 0 or buffer_vuelta > 0) and coyote > 0 and globo.is_empty():
		var vuelta := buffer_vuelta > 0 and concha == null
		velocity.y = -(SALTO_VUELTA if vuelta else SALTO) - absf(velocity.x) * 0.26
		girando = vuelta
		coyote = 0
		buffer_salto = 0
		buffer_vuelta = 0
		en_suelo = false
		plataforma = null
		# con los botones táctiles un toque corto ya da casi el salto entero (como si se mantuviera 16 fotogramas)
		min_mantener = 16 if Juego.salto_tactil else 0
		Sonido.tocar("vuelta" if vuelta else "saltar")
	if min_mantener > 0:
		min_mantener -= 1
	var manteniendo := _pulsado("saltar") or (girando and _pulsado("vuelta")) or min_mantener > 0
	if not globo.is_empty():
		# colgado de un globo: sube despacio; con ↓ lo suelta
		velocity.y = move_toward(velocity.y, -SUBIDA_GLOBO, 7.2)
		if caja().position.y < nivel.zona_actual.rect.position.y + 8.0:
			velocity.y = maxf(velocity.y, 0.0)
		globo.t -= 1
		if globo.t <= 0 or _recien("abajo"):
			soltar_globo()
	else:
		velocity.y += (GRAV_MANTENIDO if (velocity.y < 0 and manteniendo) else GRAV) * delta
		if poder == 3 and manteniendo and velocity.y > PLANEO and not girando:
			velocity.y = maxf(PLANEO, velocity.y - 36.0)
		velocity.y = minf(velocity.y, CAIDA_MAX)

	# la vuelta en el aire rompe el corcho que pisa (solo grande)
	if girando and poder > 0 and velocity.y > 0:
		var c := caja()
		var y := c.end.y + velocity.y * delta + 1.0
		var rompio := false
		for x in [c.position.x + 1.0, c.end.x - 1.0]:
			var celda: Vector2i = nivel.celda_en(Vector2(x, y))
			if nivel.tipo_en(celda) == "corcho":
				nivel.romper(celda)
				rompio = true
		if rompio:
			velocity.y = minf(velocity.y, 120.0)

	# plataforma móvil: la plataforma lleva a Tizón
	if plataforma:
		position += plataforma.desplazamiento
	var pies_antes := global_position.y
	move_and_slide()
	en_suelo = is_on_floor()
	if is_on_wall():
		velocity.x = 0.0
	if is_on_ceiling() and velocity.y <= 0.0:
		_cabezazo()
	plataforma = null
	if velocity.y >= 0.0:
		var p = nivel.plataforma_bajo(self, pies_antes)
		if p:
			global_position.y = p.position.y
			velocity.y = 0.0
			en_suelo = true
			plataforma = p
	if en_suelo and plataforma == null:
		var c := caja()
		var fila := roundi(c.end.y / 16.0)
		var izq := floori(c.position.x / 16.0)
		var der := floori((c.end.x - 0.01) / 16.0)
		# toldos de Badajoz: rebotan (mantén el salto para subir más)
		for x in range(izq, der + 1):
			if nivel.tipo_en(Vector2i(x, fila)) == "toldo":
				velocity.y = -REBOTE_TOLDO
				en_suelo = false
				coyote = 0
				girando = false
				Sonido.tocar("rebote")
				nivel.hundir_toldos(Vector2i(izq - 2, fila), Vector2i(der + 2, fila))
				break
		# piedras romanas: empiezan a temblar en cuanto Tizón las pisa
		if en_suelo:
			for x in range(izq, der + 1):
				if nivel.tipo_en(Vector2i(x, fila)) == "desmorona":
					nivel.desmoronar(Vector2i(x, fila))
	if en_suelo:
		if girando:
			girando = false
		nivel.combo = 0
	# los bordes de la zona son paredes
	var zona: Rect2 = nivel.zona_actual.rect
	global_position.x = clampf(global_position.x, zona.position.x + ANCHO / 2.0, zona.end.x - ANCHO / 2.0)
	# nivel que avanza solo: el borde de la pantalla empuja a Tizón; si queda aplastado contra algo, cae
	if nivel.avanza_solo() and not automatico:
		var izquierda: float = nivel.cam.x
		if caja().position.x < izquierda:
			global_position.x = izquierda + ANCHO / 2.0
			velocity.x = maxf(velocity.x, 0.0)
			var c2 := caja()
			var x2 := floori((c2.end.x - 0.01) / 16.0)
			for y in range(floori(c2.position.y / 16.0), floori((c2.end.y - 0.01) / 16.0) + 1):
				if nivel.es_solido(Vector2i(x2, y)):
					nivel.morir()
					return
		if caja().end.x > izquierda + 384.0:
			global_position.x = izquierda + 384.0 - ANCHO / 2.0
	# el Guadiana: Tizón no sabe nadar contra la corriente
	var sup: float = nivel.superficie_agua(nivel.celda_en(global_position))
	if sup >= 0.0 and global_position.y > sup + 6.0 and not muerto:
		nivel.salpicar(Vector2(global_position.x, sup))
		nivel.morir()
		return

	nivel.recoger_huesos(caja())

	# fuego del Zorongollo
	if poder == 2 and _recien("correr") and concha == null:
		if get_tree().get_nodes_in_group("bolas_fuego").size() < 2:
			var b: Node2D = load(ESCENA_FUEGO).instantiate()
			b.position = global_position + Vector2(mirando * (ANCHO / 2.0 + (4.0 if poder > 0 else 1.0)), -alto() + 9.0)
			b.dir = mirando
			nivel.anadir(b)
			Sonido.tocar("fuego")

	_llevar_concha()

	if invencible > 0:
		invencible -= 1
	if en_suelo:
		anim += absf(velocity.x) / 60.0 * 0.09 + (0.03 if absf(velocity.x) > 6.0 else 0.0)
	if global_position.y > nivel.fondo_zona(self) + 8:
		nivel.morir()


func _cabezazo() -> void:
	var c := caja()
	var y := c.position.y - 2.0
	var centro: Vector2i = nivel.celda_en(Vector2(global_position.x, y))
	var celda := centro
	if nivel.tipo_en(celda) == "":
		for x in [c.position.x + 1.0, c.end.x - 1.0]:
			var otra: Vector2i = nivel.celda_en(Vector2(x, y))
			if nivel.tipo_en(otra) != "":
				celda = otra
				break
	nivel.golpear_bloque(celda, "grande" if poder > 0 else "pequeno")
	velocity.y = 36.0


func _ponerse_de_pie() -> void:
	var antes := (forma.shape as RectangleShape2D).size.y
	var ahora := alto()
	if ahora > antes:
		# ¿hay sitio encima para ponerse de pie?
		var c := caja()
		for x in [c.position.x + 1.0, c.end.x - 1.0]:
			if nivel.es_solido(nivel.celda_en(Vector2(x, c.position.y + 1.0))):
				agachado = true
				return
	if ahora != antes:
		_ajustar_forma()


func _llevar_concha() -> void:
	if concha == null:
		return
	var s = concha
	if not is_instance_valid(s) or not s.vivo or s.muriendo != "":
		concha = null
		return
	var alcance := 3.0 if poder > 0 else 0.0
	if not _pulsado("correr") or automatico:
		s.en_boca = false
		s.gracia = 12
		concha = null
		s.global_position = global_position + Vector2(mirando * (ANCHO / 2.0 + s.ancho / 2.0 + 1.0), 0)
		if nivel.es_solido(nivel.celda_en(s.global_position + Vector2(0, -s.alto / 2.0))):
			s.global_position.x = global_position.x
		if _pulsado("arriba"):
			s.lanzar(0.0, velocity.x * 0.5, -390.0)
			Sonido.tocar("patada")
		elif _pulsado("abajo"):
			s.lanzar(0.0, 0.0, 0.0)
		else:
			s.lanzar(mirando, 0.0, 0.0)
			Sonido.tocar("patada")
	else:
		s.global_position = global_position + Vector2(mirando * (ANCHO / 2.0 + s.ancho / 2.0 - 3.0 + alcance), -alto() + s.alto - 2.0 + (1.0 if poder > 0 else 0.0))
		s.velocity = Vector2.ZERO


func coger_globo(color: int) -> void:
	globo = {"t": 330, "c": color}
	girando = false


func soltar_globo() -> void:
	if globo.is_empty():
		return
	for i in 6:
		nivel.particula_v("gota", global_position + Vector2((i - 3) * 2, -alto() - 18.0), Vector2((i - 3) * 0.4, -1.5), 20)
	for k in range(nivel.particulas.size() - 6, nivel.particulas.size()):
		nivel.particulas[k]["color"] = Color("ff8a7a")
	globo = {}
	Sonido.tocar("reventar")


func soltar_concha() -> void:
	if concha and is_instance_valid(concha):
		concha.en_boca = false
		concha.lanzar(0.0, 0.0, 0.0)
	concha = null


# ---------------------------------------------------------------- rebotes
func rebotar(con_vuelta := false) -> void:
	var mantiene := Input.is_action_pressed("saltar") or Input.is_action_pressed("vuelta")
	if con_vuelta:
		velocity.y = -264.0 if mantiene else -168.0
	else:
		velocity.y = -324.0 if mantiene else -204.0
	en_suelo = false


func pisando(e) -> bool:
	return velocity.y > 0.0 and caja().end.y - velocity.y / 60.0 <= e.caja().position.y + 6.0


# ---------------------------------------------------------------- dibujo
func _process(_delta: float) -> void:
	_ajustar_sprite()


func _ajustar_sprite() -> void:
	if sprite == null:
		return
	var p := poder
	if transformacion > 0:
		p = poder_anterior if ((transformacion >> 2) & 1) != 0 else poder
	var grande := p > 0
	sprite.texture = TEX_GRANDE[p] if grande else TEX_PEQ
	sprite.hframes = 5
	var tam := 24.0 if grande else 16.0
	sprite.position = Vector2(-tam / 2.0, -tam)
	var f := QUIETO
	if muerto:
		sprite.texture = TEX_PEQ
		sprite.position = Vector2(-8, -16)
		f = ESPECIAL
	elif agachado and grande:
		f = ESPECIAL
	elif not en_suelo and not (nivel and nivel.estado == "pasadizo"):
		f = SALTANDO
	elif absf(velocity.x) > 9.0:
		f = PASO_A if int(anim) % 2 == 1 else PASO_B
	sprite.frame = f
	var cara := mirando
	if girando:
		cara = 1 if ((Engine.get_physics_frames() >> 2) & 1) != 0 else -1
	sprite.flip_h = cara < 0
	sprite.visible = not oculto and not (invencible > 0 and (Engine.get_physics_frames() & 2) != 0)
	queue_redraw()
	if _adornos:
		_adornos.queue_redraw()


## La libélula del modo piloto vuela detrás de Tizón, un poco por encima
func _physics_process(_delta: float) -> void:
	if not Juego.opciones.get("piloto", false) or muerto:
		_libelula = Vector2.INF
		return
	var f := Engine.get_physics_frames()
	var objetivo := Vector2(global_position.x - mirando * 18.0 - 5.0, global_position.y - alto() - 10.0 + sin(f * 0.08) * 3.0)
	if _libelula == Vector2.INF or _libelula.distance_to(objetivo) > 160.0:
		_libelula = objetivo
	else:
		_libelula += (objetivo - _libelula) * 0.12


func _dibujar_adornos() -> void:
	var piloto: bool = Juego.opciones.get("piloto", false)
	var cumple := Adornos.es_cumple()
	var f := Engine.get_physics_frames()
	if (piloto or cumple) and sprite.visible and not muerto:
		var grande := sprite.texture != TEX_PEQ
		Adornos.dibujar(_adornos, sprite.position, grande, grande and sprite.frame == ESPECIAL, -1 if sprite.flip_h else 1,
			absf(velocity.x) > 30.0 or not en_suelo, f, piloto, cumple)
	if piloto and _libelula != Vector2.INF and not oculto:
		Adornos.dibujar_libelula(_adornos, (_libelula - global_position).round(), f, mirando)


func _draw() -> void:
	if not globo.is_empty() and not (globo.t < 60 and (Engine.get_physics_frames() & 4) != 0):
		draw_texture_rect_region(TEX_GLOBO, Rect2(-7, -alto() - 26.0, 14, 26), Rect2(int(globo.c) * 14, 0, 14, 26))
	# planeando con el disco volador en la boca
	if poder == 3 and not en_suelo and Input.is_action_pressed("saltar") and velocity.y > 0.0 and not girando and not muerto:
		var x := (ANCHO / 2.0 - 4.0) if mirando > 0 else (-ANCHO / 2.0 - 12.0)
		draw_texture(TEX_DISCO, Vector2(x, -alto() - 12.0))
