# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/principal.gd
#  Qué es:   Escena principal: menús, mapa del mundo, presentación de niveles y pausa
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node
## Escena principal: pantalla de inicio, código de partida, ayuda, bestiario,
## opciones, mapa de cada mundo, presentación de cada nivel, menú de pausa, fin de
## partida y final. Carga los niveles de Juego.NIVELES.

const VW := 384
const VH := 224

## titulo, codigo, borrar, ayuda, bestiario, opciones, mapa, mundo_superado, intro,
## jugando, fin_partida, final, nombre (para el ranking) y ranking
var estado := "titulo"
var temporizador := 0
var menu := 0
var nivel: Nivel = null
var pantalla: Node2D
var fondo_titulo: Node2D
var tactil: CanvasLayer
var panel_codigo: PanelContainer
var _codigo_texto: Label
var _entrada: LineEdit
var _mensaje: Label
var _toque := Vector2(-1, -1)
var toque := Vector2(-1, -1)       # toque de este fotograma (lo usa también pantalla.gd)
# mapa del mundo: nivel elegido, de dónde viene Tizón y cuánto le queda de camino
var mapa := {"sel": 0, "desde": 0, "t": 40}
# pantallas de ayuda, bestiario y opciones
var pagina := 0
var bicho := 0
var fichas: Array = []
var opcion := 0
var volver_a := "titulo"           # desde dónde se abrieron las opciones: titulo o pausa
var menu_pausa := 0
# ranking: lo que se está escribiendo, el cursor en el teclado de la pantalla y lo que se enseña
var ranking: Node
var nombre := ""
var tecla := Vector2i.ZERO          # columna y fila del cursor en el teclado
var nombre_aviso := ""
var enviando := false
var ranking_cargando := false
var ranking_nombre := ""           # nombre que se resalta en el ranking
var ranking_puesto := 0            # puesto que acaba de conseguir (0 si no viene de enviar)
var _tecla_escrita := false
# huevo de pascua: código Konami (↑ ↑ ↓ ↓ ← → ← → B A) para el modo piloto
const KONAMI := ["arriba", "arriba", "abajo", "abajo", "izquierda", "derecha", "izquierda", "derecha", "vuelta", "saltar"]
var _konami := 0
var aviso_huevo := ""
var aviso_hasta := 0

const Y_MENU := 102.0
const PASO_MENU := 10.0
const Y_BORRAR := 146.0
## Opciones de la pantalla «¿Empezar de cero?»: por defecto, no borrar.
const OPCIONES_BORRAR := ["no", "si"]
const OPCIONES_PAUSA := ["seguir", "opciones", "mapa"]
const Y_PAUSA := 104.0
const BICHOS_POR_PAGINA := 8
const PAGINAS_AYUDA := 3
## Teclado de la pantalla para escribir el nombre (como en las recreativas)
const TECLADO := ["ABCDEFGHIJKLM", "NÑOPQRSTUVWXY", "Z0123456789.-"]
const TECLAS := [["esp", "ESPACIO", 0, 2], ["borra", "BORRAR", 3, 5], ["salir", "SALIR", 6, 8], ["ok", "ACEPTAR", 9, 12]]
const TECLADO_X := 62.0
const TECLADO_Y := 88.0
const CELDA_W := 20.0
const CELDA_H := 15.0


func _ready() -> void:
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://assets/datos.json"))
	fichas = datos.bestiario
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -10
	add_child(capa_fondo)
	fondo_titulo = Node2D.new()
	fondo_titulo.set_script(load("res://scripts/fondo.gd"))
	capa_fondo.add_child(fondo_titulo)
	fondo_titulo.cam.y = 32.0
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	pantalla = Node2D.new()
	pantalla.set_script(load("res://scripts/pantalla.gd"))
	pantalla.principal = self
	capa.add_child(pantalla)
	ranking = Node.new()
	ranking.set_script(load("res://scripts/ranking.gd"))
	add_child(ranking)
	ranking.enviado.connect(_al_enviar)
	_crear_panel_codigo(capa)
	tactil = CanvasLayer.new()
	tactil.layer = 30
	tactil.set_script(load("res://scripts/tactil.gd"))
	tactil.principal = self
	add_child(tactil)
	ir_a_titulo()


func opciones_titulo() -> Array:
	var o := []
	if Juego.partida != null:
		o.append("continuar")
	o.append("nueva")
	if Juego.partida != null:
		o.append("borrar")
	o.append_array(["ranking", "codigo", "ayuda", "bestiario", "opciones"])
	return o


## Opciones de la pantalla de opciones (la pantalla completa solo en ordenador)
func lista_opciones() -> Array:
	var o := ["efectos", "musica", "tactil", "mando"]
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		o.append("pantalla_completa")
	o.append("volver")
	return o


func ir_a_titulo() -> void:
	_quitar_nivel()
	estado = "titulo"
	temporizador = 0
	menu = 0
	fondo_titulo.visible = true
	Sonido.parar_musica()


func _input(event: InputEvent) -> void:
	var raton: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION
	if (event is InputEventScreenTouch and event.pressed) or raton:
		_toque = event.position
	# al escribir el nombre, el teclado escribe directamente (Z, X, C... no son botones)
	if estado == "nombre" and not enviando and event is InputEventKey and event.pressed and not event.echo:
		var usada := true
		if event.keycode == KEY_BACKSPACE:
			_nombre_borrar()
		elif event.keycode == KEY_ESCAPE:
			_nombre_salir()
		else:
			var ch := String.chr(event.unicode).to_upper() if event.unicode > 0 else ""
			if ch.length() == 1 and ranking.LETRAS.contains(ch) and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
				_nombre_escribir(ch)
			else:
				usada = false
		if usada:
			_tecla_escrita = true
			get_viewport().set_input_as_handled()


func _pulsado(accion: String) -> bool:
	return Input.is_action_just_pressed(accion)


## Devuelve true si esta pulsación es la B o la A del final del código (y no debe hacer nada más)
func _paso_konami() -> bool:
	var p := ""
	for a in ["arriba", "abajo", "izquierda", "derecha", "vuelta", "saltar"]:
		if _pulsado(a):
			p = a
			break
	if p == "":
		return false
	if p == KONAMI[_konami]:
		_konami += 1
	else:
		_konami = 1 if p == KONAMI[0] else 0
	if _konami == KONAMI.size():
		_konami = 0
		Juego.opciones.piloto = not Juego.opciones.get("piloto", false)
		Juego.guardar_opciones()
		Sonido.tocar("ladrido")
		aviso_huevo = "¡MODO PILOTO!" if Juego.opciones.piloto else "MODO PILOTO DESACTIVADO"
		aviso_hasta = Engine.get_physics_frames() + 150
		return true
	return _konami == KONAMI.size() - 1 and p == "vuelta"


func _physics_process(_delta: float) -> void:
	temporizador += 1
	toque = _toque
	_toque = Vector2(-1, -1)
	var aceptar := _pulsado("saltar") or _pulsado("pausa") or toque.x >= 0.0
	var atras := _pulsado("pausa") or _pulsado("vuelta")
	var huevo := estado in ["titulo", "mapa"] and _paso_konami()
	if huevo:
		aceptar = false
	match estado:
		"titulo":
			_mover_fondo()
			var ops := opciones_titulo()
			menu = clampi(menu, 0, ops.size() - 1)
			if _pulsado("abajo"):
				menu = (menu + 1) % ops.size()
				Sonido.tocar("tic")
			if _pulsado("arriba"):
				menu = (menu + ops.size() - 1) % ops.size()
				Sonido.tocar("tic")
			var tocada := _fila_tocada(Y_MENU, PASO_MENU, ops.size())
			if toque.x >= 0.0:
				if tocada < 0:
					aceptar = false
				else:
					menu = tocada
			if aceptar and temporizador > 10:
				match ops[menu]:
					"continuar":
						Juego.continuar(Juego.partida)
						abrir_mapa(Juego.nivel)
					"nueva":
						Juego.nueva_partida()
						abrir_mapa(0)
					"borrar":
						_cambiar("borrar")
					"ranking":
						_abrir_ranking()
					"codigo":
						_abrir_codigo()
					"ayuda":
						pagina = 0
						_cambiar("ayuda")
					"bestiario":
						bicho = 0
						_cambiar("bestiario")
					"opciones":
						_abrir_opciones("titulo")
		"borrar":
			_mover_fondo()
			if _pulsado("abajo") or _pulsado("arriba"):
				menu = 1 - menu
				Sonido.tocar("tic")
			var tocada := _fila_tocada(Y_BORRAR, 13.0, 2)
			if toque.x >= 0.0:
				if tocada < 0:
					aceptar = false
				else:
					menu = tocada
			if aceptar and temporizador > 10:
				if OPCIONES_BORRAR[menu] == "si":
					# se borra la partida guardada y se empieza en la Dehesa 1-1
					Juego.borrar_partida()
					Juego.nueva_partida()
					abrir_mapa(0)
				else:
					_cambiar("titulo")
					menu = opciones_titulo().find("borrar")
		"ayuda":
			_mover_fondo()
			if _pulsado("derecha") or (toque.x >= VW / 2.0 and toque.y > 24.0):
				pagina = mini(pagina + 1, PAGINAS_AYUDA - 1)
				Sonido.tocar("tic")
			elif _pulsado("izquierda") or (toque.x >= 0.0 and toque.x < VW / 2.0 and toque.y > 24.0):
				pagina = maxi(pagina - 1, 0)
				Sonido.tocar("tic")
			if temporizador > 10 and (atras or _pulsado("saltar") and pagina == PAGINAS_AYUDA - 1 or (toque.x >= 0.0 and toque.y <= 24.0)):
				_cambiar("titulo")
				menu = opciones_titulo().find("ayuda")
		"bestiario":
			_mover_fondo()
			_paso_bestiario(atras)
		"opciones":
			if volver_a == "titulo":
				_mover_fondo()
			_paso_opciones(atras)
		"mapa":
			if not huevo:
				_paso_mapa()
		"mundo_superado":
			if temporizador > 90 and aceptar:
				abrir_mapa(Juego.nivel + 1, Juego.nivel)
		"intro":
			if temporizador > 110 or (temporizador > 20 and aceptar):
				_empezar_nivel()
		"jugando":
			if nivel and nivel.estado == "jugando":
				Juego.jugado += 1
			if nivel and nivel.estado == "pausa":
				_paso_pausa()
			elif nivel and toque.x >= 0.0:
				nivel.tocado = true
		"fin_partida":
			if (temporizador > 60 and aceptar) or temporizador > 420:
				_tras_partida()
		"final":
			_mover_fondo()
			if temporizador > 90 and aceptar:
				_tras_partida()
		"nombre":
			_paso_nombre()
		"ranking":
			if temporizador > 20 and (aceptar or atras):
				_cambiar("titulo")
				menu = opciones_titulo().find("ranking")
	pantalla.queue_redraw()


func _cambiar(nuevo: String) -> void:
	estado = nuevo
	temporizador = 0
	menu = 0


func _mover_fondo() -> void:
	fondo_titulo.cam.x = Engine.get_physics_frames() * 0.35
	fondo_titulo.tema = "dehesa"
	fondo_titulo.queue_redraw()


## Fila de un menú que se ha tocado con el dedo (o -1)
func _fila_tocada(y0: float, paso: float, n: int) -> int:
	if toque.x < 0.0:
		return -1
	for i in n:
		if absf(toque.y - (y0 + 3.0 + i * paso)) <= paso / 2.0:
			return i
	return -1


# ---------------------------------------------------------- mapa del mundo
## Abre el mapa con un nivel elegido. Si se viene de otro nivel del mismo mundo,
## Tizón camina por el camino hasta el nuevo.
func abrir_mapa(sel: int, desde := -1) -> void:
	_quitar_nivel()
	estado = "mapa"
	temporizador = 0
	fondo_titulo.visible = false
	var d := sel if desde < 0 else desde
	mapa = {"sel": sel, "desde": d, "t": 40 if (d == sel or Juego.mundo_de(d) != Juego.mundo_de(sel)) else 0}
	Sonido.musica(false)


func _paso_mapa() -> void:
	if mapa.t < 40:
		mapa.t += 1
		return
	var lejos := Juego.lejos
	if _pulsado("derecha") and mapa.sel < lejos:
		_mover_en_mapa(mapa.sel + 1)
	elif _pulsado("izquierda") and mapa.sel > 0:
		_mover_en_mapa(mapa.sel - 1)
	elif temporizador > 12 and (_pulsado("saltar") or _pulsado("pausa") or toque.x >= 0.0):
		Juego.entrar(mapa.sel)
		Sonido.parar_musica()
		_ir_a_intro()


func _mover_en_mapa(nuevo: int) -> void:
	mapa.desde = mapa.sel
	mapa.sel = nuevo
	mapa.t = 0 if Juego.mundo_de(mapa.desde) == Juego.mundo_de(nuevo) else 40
	Sonido.tocar("tic")


# ---------------------------------------------------------- niveles
func _ir_a_intro() -> void:
	estado = "intro"
	temporizador = 0
	fondo_titulo.visible = false


func _empezar_nivel() -> void:
	_quitar_nivel()
	var datos: Dictionary = Juego.NIVELES[Juego.nivel]
	nivel = load(datos.escena).instantiate()
	nivel.superado.connect(_nivel_superado)
	nivel.perdido.connect(_nivel_perdido)
	add_child(nivel)
	estado = "jugando"
	temporizador = 0
	menu_pausa = 0
	Sonido.musica(false)
	Sonido.tocar("ladrido")


func _quitar_nivel() -> void:
	if nivel:
		nivel.queue_free()
		nivel = null


func _nivel_perdido() -> void:
	_quitar_nivel()
	Juego.vidas -= 1
	if Juego.vidas <= 0:
		estado = "fin_partida"
		temporizador = 0
		Juego.guardar_record()
		Sonido.tocar("fin_partida")
		ranking.al_acabar(false)
	else:
		_ir_a_intro()


func _nivel_superado() -> void:
	_quitar_nivel()
	var siguiente := Juego.nivel + 1
	if siguiente >= Juego.NIVELES.size():
		estado = "final"
		temporizador = 0
		fondo_titulo.visible = true
		Sonido.tocar("nivel_superado")
		ranking.al_acabar(true)
	elif Juego.nuevo_mundo:
		estado = "mundo_superado"
		temporizador = 0
		Sonido.tocar("nivel_superado")
	else:
		abrir_mapa(siguiente, Juego.nivel)


# ---------------------------------------------------------- pausa
func _paso_pausa() -> void:
	if _pulsado("abajo"):
		menu_pausa = (menu_pausa + 1) % OPCIONES_PAUSA.size()
		Sonido.tocar("tic")
	if _pulsado("arriba"):
		menu_pausa = (menu_pausa + OPCIONES_PAUSA.size() - 1) % OPCIONES_PAUSA.size()
		Sonido.tocar("tic")
	var tocada := _fila_tocada(Y_PAUSA, 14.0, OPCIONES_PAUSA.size())
	if tocada >= 0:
		menu_pausa = tocada
	if _pulsado("pausa"):
		nivel.seguir()
		return
	if _pulsado("saltar") or tocada >= 0:
		match OPCIONES_PAUSA[menu_pausa]:
			"seguir":
				nivel.seguir()
			"opciones":
				_abrir_opciones("pausa")
			"mapa":
				# se sale del nivel sin perder una vida (la caseta sigue encendida)
				abrir_mapa(Juego.nivel)


# ---------------------------------------------------------- opciones
func _abrir_opciones(desde: String) -> void:
	volver_a = desde
	estado = "opciones"
	temporizador = 0
	opcion = 0
	if nivel:
		nivel.bloqueado = true


func _cerrar_opciones() -> void:
	Juego.guardar_opciones()
	if volver_a == "pausa" and nivel:
		estado = "jugando"
		nivel.bloqueado = false
		menu_pausa = 1
	else:
		_cambiar("titulo")
		menu = opciones_titulo().find("opciones")


func _paso_opciones(atras: bool) -> void:
	var ops := lista_opciones()
	opcion = clampi(opcion, 0, ops.size() - 1)
	if _pulsado("abajo"):
		opcion = (opcion + 1) % ops.size()
		Sonido.tocar("tic")
	if _pulsado("arriba"):
		opcion = (opcion + ops.size() - 1) % ops.size()
		Sonido.tocar("tic")
	var tocada := _fila_tocada(60.0, 18.0, ops.size())
	if tocada >= 0:
		opcion = tocada
	var cambiar := 0
	if _pulsado("derecha") or _pulsado("saltar") or tocada >= 0:
		cambiar = 1
	elif _pulsado("izquierda"):
		cambiar = -1
	if atras and temporizador > 5:
		_cerrar_opciones()
		return
	if cambiar == 0:
		return
	var o := Juego.opciones
	match ops[opcion]:
		"efectos", "musica", "pantalla_completa":
			o[ops[opcion]] = not o[ops[opcion]]
		"tactil":
			var valores := ["auto", "si", "no"]
			o.tactil = valores[(valores.find(o.tactil) + cambiar + 3) % 3]
		"mando":
			o.mando = "joystick" if o.mando == "cruceta" else "cruceta"
		"volver":
			if cambiar > 0:
				_cerrar_opciones()
				return
	Juego.guardar_opciones()
	Sonido.tocar("tic")


# ---------------------------------------------------------- bestiario
func paginas_bestiario() -> int:
	return ceili(fichas.size() / float(BICHOS_POR_PAGINA))


func _paso_bestiario(atras: bool) -> void:
	var n := fichas.size()
	var antes := bicho
	if _pulsado("derecha"):
		bicho = mini(bicho + 1, n - 1)
	if _pulsado("izquierda"):
		bicho = maxi(bicho - 1, 0)
	if _pulsado("abajo"):
		bicho = mini(bicho + 2, n - 1)
	if _pulsado("arriba"):
		bicho = maxi(bicho - 2, 0)
	if toque.x >= 0.0:
		if toque.y < 22.0:
			if toque.x < 80.0:
				atras = true
			elif toque.x > VW - 60.0:
				bicho = mini((bicho / BICHOS_POR_PAGINA + 1) * BICHOS_POR_PAGINA, n - 1)
			elif toque.x > VW - 120.0:
				bicho = maxi((bicho / BICHOS_POR_PAGINA - 1) * BICHOS_POR_PAGINA, 0)
		elif toque.y < 162.0:
			var col := 0 if toque.x < VW / 2.0 else 1
			var fila := clampi(int((toque.y - 26.0) / 34.0), 0, 3)
			bicho = mini((bicho / BICHOS_POR_PAGINA) * BICHOS_POR_PAGINA + fila * 2 + col, n - 1)
	if bicho != antes:
		Sonido.tocar("tic")
	if atras and temporizador > 5:
		_cambiar("titulo")
		menu = opciones_titulo().find("bestiario")


# ---------------------------------------------------------- ranking
func _abrir_ranking() -> void:
	_cambiar("ranking")
	fondo_titulo.visible = false
	ranking_nombre = Juego.opciones.nombre
	ranking_puesto = 0
	ranking_cargando = true
	ranking.pedir()


## Después del fin de partida o del final: si la puntuación entra en el ranking, se pide el nombre
func _tras_partida() -> void:
	if ranking.datos != null and ranking.estado == "cargando":
		return                      # aún se está mirando el ranking
	if ranking.entra():
		nombre = str(Juego.opciones.nombre).left(ranking.NOMBRE_MAX)
		tecla = Vector2i(9, 3) if nombre != "" else Vector2i.ZERO
		nombre_aviso = ""
		enviando = false
		_cambiar("nombre")
		fondo_titulo.visible = false
		Sonido.tocar("vida")
	else:
		ir_a_titulo()


func tecla_en(columna: int, fila: int):
	if fila < 3:
		return TECLADO[fila][columna]
	for b in TECLAS:
		if columna >= b[2] and columna <= b[3]:
			return b
	return TECLAS[0]


func _nombre_escribir(ch: String) -> void:
	if enviando:
		return
	if nombre.length() >= ranking.NOMBRE_MAX or (ch == " " and (nombre == "" or nombre.ends_with(" "))):
		Sonido.tocar("golpe")
		return
	nombre += ch
	nombre_aviso = ""
	Sonido.tocar("tic")
	if nombre.length() >= ranking.NOMBRE_MAX:
		tecla = Vector2i(9, 3)      # lleno: el cursor salta a ACEPTAR


func _nombre_borrar() -> void:
	if enviando or nombre == "":
		return
	nombre = nombre.left(nombre.length() - 1)
	nombre_aviso = ""
	Sonido.tocar("tic")


func _nombre_salir() -> void:
	if not enviando:
		ir_a_titulo()


func _nombre_activar() -> void:
	var t = tecla_en(tecla.x, tecla.y)
	if tecla.y < 3:
		_nombre_escribir(t)
		return
	match t[0]:
		"esp":
			_nombre_escribir(" ")
		"borra":
			_nombre_borrar()
		"salir":
			_nombre_salir()
		_:
			_nombre_aceptar()


func _nombre_aceptar() -> void:
	if enviando:
		return
	var limpio := nombre.strip_edges()
	while limpio.contains("  "):
		limpio = limpio.replace("  ", " ")
	var valido := false
	for ch in limpio:
		if ch != " " and ch != "." and ch != "-":
			valido = true
	if not valido:
		nombre_aviso = "ESCRIBE UN NOMBRE"
		Sonido.tocar("golpe")
		return
	enviando = true
	nombre_aviso = ""
	ranking.enviar(limpio)


func _al_enviar(r) -> void:
	if estado != "nombre":
		return
	enviando = false
	if r != null and r.get("ok", false) == true:
		Juego.opciones.nombre = str(r.get("nombre", nombre))
		Juego.guardar_opciones()
		ranking_nombre = Juego.opciones.nombre
		ranking_puesto = int(r.get("posicion", 0)) if r.get("posicion") != null else 0
		ranking_cargando = false
		_cambiar("ranking")
		Sonido.tocar("nivel_superado")
		return
	Sonido.tocar("golpe")
	var error: String = str(r.get("error", "")) if r != null else ""
	match error:
		"nombre":
			nombre_aviso = "ESE NOMBRE NO SE PUEDE USAR"
		"espera":
			nombre_aviso = "ESPERA UN POCO Y VUELVE A PROBAR"
		"imposible":
			nombre_aviso = "EL RANKING NO HA ACEPTADO ESTA PUNTUACIÓN"
		_:
			nombre_aviso = "NO HAY CONEXIÓN CON EL RANKING"


func _paso_nombre() -> void:
	if _tecla_escrita:
		_tecla_escrita = false      # esa pulsación ya ha escrito una letra
		return
	if enviando or temporizador < 15:
		return
	var dx := 0
	var dy := 0
	if _pulsado("izquierda"):
		dx = -1
	elif _pulsado("derecha"):
		dx = 1
	if _pulsado("arriba"):
		dy = -1
	elif _pulsado("abajo"):
		dy = 1
	if dx != 0 or dy != 0:
		if tecla.y == 3 and dx != 0:
			# en la fila de abajo se salta de botón en botón
			var i := 0
			for k in TECLAS.size():
				if tecla.x >= TECLAS[k][2] and tecla.x <= TECLAS[k][3]:
					i = k
			tecla.x = TECLAS[clampi(i + dx, 0, TECLAS.size() - 1)][2]
		else:
			tecla = Vector2i((tecla.x + dx + 13) % 13, (tecla.y + dy + 4) % 4)
		Sonido.tocar("tic")
	if toque.x >= 0.0:
		var c := int(floor((toque.x - TECLADO_X) / CELDA_W))
		var f := int(floor((toque.y - TECLADO_Y) / CELDA_H))
		if c >= 0 and c < 13 and f >= 0 and f < 4:
			tecla = Vector2i(tecla_en(c, f)[2] if f == 3 else c, f)
			_nombre_activar()
		return
	if _pulsado("saltar"):
		_nombre_activar()
	elif _pulsado("vuelta"):
		_nombre_borrar()
	elif _pulsado("pausa"):
		_nombre_aceptar()


# ---------------------------------------------------------- código de partida
func _crear_panel_codigo(capa: CanvasLayer) -> void:
	var tema := Theme.new()
	tema.default_font_size = 9
	panel_codigo = PanelContainer.new()
	panel_codigo.theme = tema
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("201a12")
	caja.border_color = Color("f2b632")
	caja.set_border_width_all(1)
	caja.set_content_margin_all(8)
	panel_codigo.add_theme_stylebox_override("panel", caja)
	panel_codigo.position = Vector2(42, 34)
	panel_codigo.custom_minimum_size = Vector2(300, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	panel_codigo.add_child(v)
	var titulo := Label.new()
	titulo.text = "Código de tu partida"
	titulo.add_theme_color_override("font_color", Color("f2b632"))
	v.add_child(titulo)
	var fila := HBoxContainer.new()
	_codigo_texto = Label.new()
	_codigo_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_codigo_texto)
	var copiar := Button.new()
	copiar.text = "Copiar"
	copiar.pressed.connect(func():
		if Juego.partida != null:
			DisplayServer.clipboard_set(Juego.codigo(Juego.partida))
			_mensaje.text = "Código copiado.")
	fila.add_child(copiar)
	v.add_child(fila)
	var ayuda := Label.new()
	ayuda.text = "Escribe el código de otro dispositivo (también vale el de la versión web y los códigos antiguos):"
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(ayuda)
	_entrada = LineEdit.new()
	_entrada.placeholder_text = "XXXXXXX-XXXXXXX-XXXXXXX"
	_entrada.max_length = 25
	_entrada.text_submitted.connect(func(_t): _cargar_codigo())
	v.add_child(_entrada)
	var botones := HBoxContainer.new()
	var cargar := Button.new()
	cargar.text = "Cargar"
	cargar.pressed.connect(_cargar_codigo)
	botones.add_child(cargar)
	var volver := Button.new()
	volver.text = "Volver"
	volver.pressed.connect(_cerrar_codigo)
	botones.add_child(volver)
	v.add_child(botones)
	_mensaje = Label.new()
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mensaje.add_theme_color_override("font_color", Color("9fe0ea"))
	v.add_child(_mensaje)
	panel_codigo.visible = false
	capa.add_child(panel_codigo)


func _abrir_codigo() -> void:
	estado = "codigo"
	_codigo_texto.text = Juego.codigo(Juego.partida) if Juego.partida != null else "Aún no hay partida guardada"
	_mensaje.text = ""
	_entrada.text = ""
	panel_codigo.visible = true
	_entrada.grab_focus()


func _cerrar_codigo() -> void:
	panel_codigo.visible = false
	estado = "titulo"
	temporizador = 0
	menu = 0 if _mensaje.text.begins_with("Código cargado") else opciones_titulo().find("codigo")


func _cargar_codigo() -> void:
	if Juego.cargar_codigo(_entrada.text):
		_mensaje.text = "Código cargado. Elige Continuar."
		_codigo_texto.text = Juego.codigo(Juego.partida)
		menu = 0
	else:
		_mensaje.text = "Ese código no es válido: revisa que tenga 21 letras y números (13 o 15 si es un código antiguo), sin O, I, 0 ni 1."


func _unhandled_input(event: InputEvent) -> void:
	if estado == "codigo" and event.is_action_pressed("pausa") and not _entrada.has_focus():
		_cerrar_codigo()
