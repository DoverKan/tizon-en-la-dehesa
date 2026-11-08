# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/principal.gd
#  Qué es:   Escena principal: menús, mapa del mundo, presentación de niveles y pausa
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node
## Escena principal: pantalla de inicio, código de partida, ayuda, bestiario,
## opciones, mapa de cada mundo, presentación de cada nivel, menú de pausa, fin de
## partida y final. Carga los niveles de Juego.NIVELES.

const VW := 384
const VH := 224

## titulo, codigo, borrar, ayuda, bestiario, opciones, mapa, mundo_superado, intro,
## jugando, fin_partida, final
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

const Y_MENU := 102.0
const PASO_MENU := 11.0
const Y_BORRAR := 146.0
## Opciones de la pantalla «¿Empezar de cero?»: por defecto, no borrar.
const OPCIONES_BORRAR := ["no", "si"]
const OPCIONES_PAUSA := ["seguir", "opciones", "mapa"]
const Y_PAUSA := 104.0
const BICHOS_POR_PAGINA := 8
const PAGINAS_AYUDA := 3


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
	o.append_array(["codigo", "ayuda", "bestiario", "opciones"])
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


func _pulsado(accion: String) -> bool:
	return Input.is_action_just_pressed(accion)


func _physics_process(_delta: float) -> void:
	temporizador += 1
	toque = _toque
	_toque = Vector2(-1, -1)
	var aceptar := _pulsado("saltar") or _pulsado("pausa") or toque.x >= 0.0
	var atras := _pulsado("pausa") or _pulsado("vuelta")
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
			_paso_mapa()
		"mundo_superado":
			if temporizador > 90 and aceptar:
				abrir_mapa(Juego.nivel + 1, Juego.nivel)
		"intro":
			if temporizador > 110 or (temporizador > 20 and aceptar):
				_empezar_nivel()
		"jugando":
			if nivel and nivel.estado == "pausa":
				_paso_pausa()
			elif nivel and toque.x >= 0.0:
				nivel.tocado = true
		"fin_partida":
			if (temporizador > 60 and aceptar) or temporizador > 420:
				ir_a_titulo()
		"final":
			_mover_fondo()
			if temporizador > 90 and aceptar:
				ir_a_titulo()
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
