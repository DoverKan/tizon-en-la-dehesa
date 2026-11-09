# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/pantalla.gd
#  Qué es:   Dibujo de los menús, la ayuda, el bestiario, las opciones, el mapa y la pausa
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node2D
## Dibuja la pantalla de inicio, la ayuda, el bestiario, las opciones, el mapa de cada
## mundo, la presentación de cada nivel, el menú de pausa, el fin de partida, el final,
## la pantalla para escribir el nombre y el ranking.

const VW := 384
const VH := 224
const ORO := Color("f2b632")
const AMARILLO := Color("ffd25e")
const CREMA := Color("fbf0da")
const CELESTE := Color("9fe0ea")
const OSCURO := Color("120d08")
const EFECTOS := preload("res://scripts/efectos.gd")
var principal: Node = null
var _losetas: Texture2D = preload("res://assets/tiles/losetas.png")
var _grande: Texture2D = preload("res://assets/sprites/tizon_grande_normal.png")
var _pequeno: Texture2D = preload("res://assets/sprites/tizon_pequeno.png")
var _calcetin: Texture2D = preload("res://assets/sprites/calcetin.png")
var _zoro: Texture2D = preload("res://assets/sprites/zorongollo.png")
var _pelotero: Texture2D = preload("res://assets/sprites/pelotero.png")
var _mapas: Array[Texture2D] = [preload("res://assets/mapas/mundo_1.png"), preload("res://assets/mapas/mundo_2.png")]
var _iconos := {}

const AYUDA := [
	["CONTROLES", [
		["← →", "MOVERSE"],
		["▼", "AGACHARSE O METERSE POR EL AGUJERO DE UNA ENCINA"],
		["Z  ESPACIO  (A)", "SALTAR. MANTÉN PARA SUBIR MÁS, TAMBIÉN AL REBOTAR EN UN TOLDO"],
		["X  MAYÚS  (X O Y)", "CORRER, ESCUPIR FUEGO Y COGER CONCHAS CON LA BOCA"],
		["C  (B)", "VUELTA EN EL AIRE: ACABA CON EL CARDO Y ROMPE EL CORCHO"],
		["ENTER  ESC  (START)", "PAUSA"],
	]],
	["CÓMO SE JUEGA", [
		["", "LLEGA AL FINAL DE CADA NIVEL: AL NIDO DE CIGÜEÑA O A LA PUERTA DE THE CEREAL CAFE."],
		["", "PISA A LOS BICHOS. A LOS QUE NO SE PUEDEN PISAR, DALES CON LA VUELTA, EL FUEGO O UNA CONCHA."],
		["", "AL SOLTAR CORRER CON UNA CONCHA EN LA BOCA, TIZÓN LA LANZA. CON ARRIBA LA TIRA HACIA ARRIBA."],
		["", "CIEN HUESITOS DAN UNA VIDA. HAY CINCO CALCETINES ESCONDIDOS EN CADA NIVEL."],
		["", "LAS ENCINAS QUE ECHAN DESTELLOS TIENEN PASADIZO: PONTE ENCIMA Y PULSA ABAJO."],
	]],
	["PARTIDA Y MANDOS", [
		["", "LA PARTIDA SE GUARDA SOLA AL TOCAR LA CASETA Y AL PASAR UN NIVEL."],
		["", "EN EL MAPA PUEDES VOLVER A JUGAR LOS NIVELES QUE YA HAS PASADO."],
		["", "EL CÓDIGO DE PARTIDA (21 LETRAS Y NÚMEROS) SIRVE PARA SEGUIR EN OTRO DISPOSITIVO O EN LA VERSIÓN WEB."],
		["", "SI AL ACABAR LA PARTIDA TU PUNTUACIÓN ENTRA EN EL RANKING, ESCRIBE TU NOMBRE. LAS PARTIDAS CARGADAS CON CÓDIGO NO CUENTAN."],
		["", "EN PANTALLA TÁCTIL: CRUCETA O JOYSTICK A LA IZQUIERDA. A SALTA, B DA LA VUELTA, X E Y CORREN."],
	]],
]


func _draw() -> void:
	if principal == null:
		return
	var t: int = Engine.get_physics_frames()
	match principal.estado:
		"titulo", "codigo", "borrar":
			_titulo(t)
		"ayuda":
			_ayuda()
		"bestiario":
			_bestiario()
		"opciones":
			_opciones()
		"mapa":
			_mapa(t)
		"mundo_superado":
			_mundo_superado(t)
		"intro":
			_intro()
		"jugando":
			if principal.nivel and principal.nivel.estado == "pausa":
				_pausa(t)
		"fin_partida":
			draw_rect(Rect2(0, 0, VW, VH), OSCURO)
			FuentePixel.dibujar(self, "FIN DE LA PARTIDA", Vector2(VW / 2.0, 90), ORO, 2, Color("5a3510"), FuentePixel.CENTRO)
			FuentePixel.dibujar(self, "PUNTOS %07d" % Juego.puntos, Vector2(VW / 2.0, 120), CREMA, 1, FuentePixel.SIN_SOMBRA, FuentePixel.CENTRO)
			_estado_ranking(150)
		"final":
			_final(t)
		"nombre":
			_nombre(t)
		"ranking":
			_ranking(t)


func _centro(texto: String, y: float, c: Color = CREMA, escala := 1, sombra: Color = FuentePixel.SOMBRA) -> void:
	FuentePixel.dibujar(self, texto, Vector2(VW / 2.0, y), c, escala, sombra, FuentePixel.CENTRO)


func _cursor(etiqueta: String, y: float, t: int, x_centro := VW / 2.0) -> void:
	if ((t >> 4) & 1) != 0:
		FuentePixel.dibujar(self, ">", Vector2(x_centro - FuentePixel.ancho(etiqueta) / 2.0 - 12.0, y), AMARILLO)


func _panel(r: Rect2) -> void:
	draw_rect(r, Color(0.08, 0.05, 0.02, 0.86))
	draw_rect(r, Color(ORO, 0.6), false, 1.0)


# ---------------------------------------------------------- inicio
func _titulo(t: int) -> void:
	_suelo(t * 0.35)
	var gy := 176.0
	var paso := 1 + ((t >> 3) & 1)
	draw_texture_rect_region(_grande, Rect2(88, gy - 24, 24, 24), Rect2(paso * 24, 0, 24, 24))
	draw_texture_rect_region(_pelotero, Rect2(60 + fmod(t * 0.2, 8.0), gy - 14, 16, 16), Rect2(((t >> 3) & 1) * 16, 0, 16, 16))
	draw_texture(_calcetin, Vector2(300, gy - 60 + roundf(sin(t * 0.06) * 2.0)))
	draw_texture_rect_region(_zoro, Rect2(266 - fmod(t * 0.4, 60.0), gy - 16, -16, 16), Rect2(((t >> 3) & 1) * 16, 0, 16, 16))
	FuentePixel.dibujar_contorno(self, "TIZÓN", VW / 2.0, 26, Color("e9a21f"), Color("4a2608"), 6, Color("2b1a10"))
	FuentePixel.dibujar_contorno(self, "EN LA DEHESA", VW / 2.0, 78, CREMA, Color("4a2608"), 2, Color("2b1a10"))
	if principal.estado == "titulo":
		var ops: Array = principal.opciones_titulo()
		for i in ops.size():
			var etiqueta := ""
			match ops[i]:
				"continuar":
					var d: Dictionary = Juego.partida
					etiqueta = "CONTINUAR · " + Juego.NIVELES[d.nivel].nombre + (" (CASETA)" if d.caseta else "")
				"nueva":
					etiqueta = "NUEVA PARTIDA"
				"borrar":
					etiqueta = "EMPEZAR DE CERO"
				"ranking":
					etiqueta = "RANKING"
				"codigo":
					etiqueta = "CÓDIGO DE PARTIDA"
				"ayuda":
					etiqueta = "AYUDA"
				"bestiario":
					etiqueta = "BESTIARIO"
				"opciones":
					etiqueta = "OPCIONES"
			var y: float = principal.Y_MENU + i * principal.PASO_MENU
			var sel: bool = i == principal.menu
			_centro(etiqueta, y, AMARILLO if sel else CREMA)
			if sel:
				_cursor(etiqueta, y, t)
		if Juego.record > 0:
			_centro("MEJOR PUNTUACIÓN %07d" % Juego.record, 208)
	elif principal.estado == "borrar":
		_panel(Rect2(52, 102, VW - 104, 76))
		_centro("¿BORRAR LA PARTIDA GUARDADA?", 110, AMARILLO)
		_centro("EMPIEZAS DE CERO EN LA DEHESA 1-1", 124)
		for i in 2:
			var etiqueta := "NO, VOLVER" if i == 0 else "SÍ, BORRAR"
			var y: float = principal.Y_BORRAR + i * 13.0
			var sel: bool = i == principal.menu
			_centro(etiqueta, y, AMARILLO if sel else CREMA)
			if sel:
				_cursor(etiqueta, y, t)


func _suelo(scroll: float) -> void:
	# franja de suelo de la pantalla de inicio (losetas de suelo con hierba)
	var ox := -fposmod(scroll, 16.0)
	var x := ox
	var i := int(scroll / 16.0)
	while x < VW:
		for fila in 3:
			var v := (i * 7 + fila * 13) & 3
			var atlas := Vector2(4 if fila == 0 else 0, v)
			draw_texture_rect_region(_losetas, Rect2(roundf(x), 176 + fila * 16, 16, 16), Rect2(atlas * 16, Vector2(16, 16)))
		x += 16.0
		i += 1


# ---------------------------------------------------------- ayuda
func _ayuda() -> void:
	_panel(Rect2(10, 8, VW - 20, VH - 16))
	var p: Array = AYUDA[principal.pagina]
	FuentePixel.dibujar(self, "< VOLVER", Vector2(18, 14), CELESTE)
	FuentePixel.dibujar(self, "%d/%d" % [principal.pagina + 1, AYUDA.size()], Vector2(VW - 18, 14), CELESTE, 1, FuentePixel.SOMBRA, FuentePixel.DERECHA)
	_centro("AYUDA · " + p[0], 14, ORO)
	var y := 34.0
	for linea in p[1]:
		var tecla: String = linea[0]
		var x := 22.0
		var ancho := VW - 44.0
		if tecla != "":
			FuentePixel.dibujar(self, tecla, Vector2(22, y), AMARILLO)
			x = 140.0
			ancho = VW - 22.0 - x
		else:
			draw_rect(Rect2(22, y + 2, 3, 3), ORO)
			x = 30.0
			ancho = VW - 22.0 - x
		for l in FuentePixel.partir(linea[1], ancho):
			FuentePixel.dibujar(self, l, Vector2(x, y), CREMA)
			y += 10.0
		y += 6.0
	_centro("← →  PÁGINA · B O ESC  VOLVER", VH - 20, CELESTE)


# ---------------------------------------------------------- bestiario
func _icono(nombre: String) -> Texture2D:
	if not _iconos.has(nombre):
		_iconos[nombre] = load("res://assets/bestiario/" + nombre)
	return _iconos[nombre]


func _bestiario() -> void:
	_panel(Rect2(6, 4, VW - 12, VH - 8))
	var fichas: Array = principal.fichas
	var sel: int = principal.bicho
	var pagina: int = sel / principal.BICHOS_POR_PAGINA
	FuentePixel.dibujar(self, "< VOLVER", Vector2(14, 10), CELESTE)
	_centro("BESTIARIO", 10, ORO)
	FuentePixel.dibujar(self, "<  %d/%d  >" % [pagina + 1, principal.paginas_bestiario()], Vector2(VW - 14, 10), CELESTE, 1, FuentePixel.SOMBRA, FuentePixel.DERECHA)
	for k in principal.BICHOS_POR_PAGINA:
		var i: int = pagina * principal.BICHOS_POR_PAGINA + k
		if i >= fichas.size():
			break
		var f: Dictionary = fichas[i]
		var r := Rect2(12 + (k % 2) * 182, 26 + (k / 2) * 34, 176, 32)
		draw_rect(r, Color(1, 1, 1, 0.08) if i != sel else Color(ORO, 0.25))
		if i == sel:
			draw_rect(r, AMARILLO, false, 1.0)
		var tex := _icono(f.imagen)
		var s := 2.0 if maxi(tex.get_width(), tex.get_height()) <= 16 else 1.0
		var tam := Vector2(tex.get_width(), tex.get_height()) * s
		if tam.x > 32.0 or tam.y > 30.0:
			var k2 := minf(32.0 / tam.x, 30.0 / tam.y)
			tam *= k2
		draw_texture_rect(tex, Rect2((r.position + Vector2(18, 16) - tam / 2.0).round(), tam.round()), false)
		FuentePixel.dibujar(self, f.nombre, Vector2(r.position.x + 38, r.position.y + 7), AMARILLO if i == sel else CREMA)
		FuentePixel.dibujar(self, f.papel, Vector2(r.position.x + 38, r.position.y + 19), CELESTE)
	var f: Dictionary = fichas[sel]
	draw_rect(Rect2(12, 166, VW - 24, 50), Color(0, 0, 0, 0.35))
	var y := 172.0
	for l in FuentePixel.partir(String(f.texto).to_upper(), VW - 40.0):
		FuentePixel.dibujar(self, l, Vector2(20, y), CREMA)
		y += 11.0


# ---------------------------------------------------------- opciones
func _valor_opcion(clave: String) -> String:
	var o: Dictionary = Juego.opciones
	match clave:
		"efectos", "musica", "pantalla_completa":
			return "SÍ" if o[clave] else "NO"
		"tactil":
			return {"auto": "AUTOMÁTICO", "si": "SIEMPRE", "no": "NUNCA"}[o.tactil]
		"mando":
			return "CRUCETA" if o.mando == "cruceta" else "JOYSTICK"
	return ""


func _opciones() -> void:
	if principal.volver_a == "pausa":
		draw_rect(Rect2(0, 0, VW, VH), Color(0.06, 0.04, 0.02, 0.7))
	_panel(Rect2(40, 24, VW - 80, 180))
	_centro("OPCIONES", 32, ORO)
	var nombres := {"efectos": "EFECTOS DE SONIDO", "musica": "MÚSICA", "tactil": "BOTONES TÁCTILES", "mando": "MANDO TÁCTIL",
		"pantalla_completa": "PANTALLA COMPLETA", "volver": "VOLVER"}
	var ops: Array = principal.lista_opciones()
	var t := Engine.get_physics_frames()
	for i in ops.size():
		var y := 60.0 + i * 18.0
		var sel: bool = i == principal.opcion
		var c := AMARILLO if sel else CREMA
		if ops[i] == "volver":
			_centro("VOLVER", y, c)
			if sel:
				_cursor("VOLVER", y, t)
			continue
		FuentePixel.dibujar(self, nombres[ops[i]], Vector2(56, y), c)
		var v := _valor_opcion(ops[i])
		if sel:
			v = "< " + v + " >"
		FuentePixel.dibujar(self, v, Vector2(VW - 56, y), CELESTE if not sel else AMARILLO, 1, FuentePixel.SOMBRA, FuentePixel.DERECHA)
	_centro("ARRIBA Y ABAJO ELEGIR · ← → CAMBIAR · B O ESC VOLVER", 190, CELESTE)


# ---------------------------------------------------------- mapa del mundo
func _mapa(t: int) -> void:
	var m: Dictionary = principal.mapa
	var w := Juego.mundo_de(m.sel)
	var M: Dictionary = Juego.mundos[w]
	draw_texture(_mapas[w], Vector2.ZERO)
	draw_rect(Rect2(0, 0, VW, 22), Color(30 / 255.0, 20 / 255.0, 10 / 255.0, 0.65))
	_centro(M.nombre, 8, ORO)
	var nodos: Array = M.nodos
	for k in nodos.size():
		var x: float = nodos[k][0]
		var y: float = nodos[k][1]
		var i := w * Juego.NIVELES_POR_MUNDO + k
		var hecho := i < Juego.lejos
		var abierto := i <= Juego.lejos
		draw_rect(Rect2(x - 7, y - 5, 14, 10), Color("2b1a10"))
		draw_rect(Rect2(x - 5, y - 7, 10, 14), Color("2b1a10"))
		var c := Color("d9432f") if hecho else (Color("f2c94c") if abierto else Color("8a8a90"))
		draw_rect(Rect2(x - 6, y - 4, 12, 8), c)
		draw_rect(Rect2(x - 4, y - 6, 8, 12), c)
		draw_rect(Rect2(x - 3, y - 4, 4, 2), Color(1, 1, 1, 0.45))
		if k == 4:
			# el castillo o el teatro del jefe
			draw_rect(Rect2(x - 6, y - 22, 12, 14), Color("2b1a10"))
			draw_rect(Rect2(x - 5, y - 21, 10, 12), Color("9a9890") if hecho else Color("cdb88e"))
			for q in 3:
				draw_rect(Rect2(x - 6 + q * 5, y - 25, 3, 3), Color("2b1a10"))
		var cogidos := 0
		for b in Juego.calcetines[i]:
			if b:
				cogidos += 1
		if abierto and cogidos > 0:
			FuentePixel.dibujar(self, str(cogidos), Vector2(x + 7, y - 2), CELESTE if cogidos == 5 else Color.WHITE)
	# Tizón camina por el camino
	var destino: Array = nodos[m.sel % Juego.NIVELES_POR_MUNDO]
	var p := Vector2(destino[0], destino[1])
	if m.t < 40 and Juego.mundo_de(m.desde) == w:
		var origen: Array = nodos[m.desde % Juego.NIVELES_POR_MUNDO]
		p = Vector2(origen[0], origen[1]).lerp(p, m.t / 40.0)
	var anda: bool = m.t < 40
	var marco := (1 if ((t >> 3) & 1) != 0 else 2) if anda else 0
	var bote := 0.0 if anda else float((t >> 4) & 1)
	var izq: bool = m.sel < m.desde
	draw_texture_rect_region(_pequeno, Rect2(roundf(p.x + 8) if izq else roundf(p.x - 8), roundf(p.y - 18 - bote), -16 if izq else 16, 16), Rect2(marco * 16, 0, 16, 16))
	# nombre del nivel elegido
	var lv: Dictionary = Juego.NIVELES[m.sel]
	draw_rect(Rect2(0, VH - 42, VW, 42), Color(30 / 255.0, 20 / 255.0, 10 / 255.0, 0.75))
	_centro(lv.nombre, VH - 36, AMARILLO)
	_centro(lv.subtitulo, VH - 24, CREMA)
	if m.t >= 40 and ((t >> 5) & 1) != 0:
		_centro(("← →  ELEGIR · " if Juego.lejos > 0 else "") + "SALTA PARA ENTRAR", VH - 12, CELESTE)
	FuentePixel.dibujar(self, "TIZÓN ×" + str(Juego.vidas), Vector2(8, VH - 36), Color.WHITE)


func _mundo_superado(t: int) -> void:
	draw_rect(Rect2(0, 0, VW, VH), OSCURO)
	FuentePixel.dibujar_contorno(self, "¡MUNDO 1 SUPERADO!", VW / 2.0, 44, AMARILLO, Color("4a2608"), 2)
	_centro("MICIFUZ HA HUIDO DE LA ALCAZABA", 74, CREMA, 1, FuentePixel.SIN_SOMBRA)
	_centro("Y TIZÓN SIGUE SU CAMINO HACIA MÉRIDA", 86, CREMA, 1, FuentePixel.SIN_SOMBRA)
	draw_texture_rect_region(_grande, Rect2(VW / 2.0 - 12, 104, 24, 24), Rect2((1 + ((t >> 3) & 1)) * 24, 0, 24, 24))
	_centro(Juego.mundos[1].nombre, 144, CELESTE, 1, FuentePixel.SIN_SOMBRA)
	if principal.temporizador > 90 and ((t >> 5) & 1) != 0:
		_centro("PULSA PARA SEGUIR", 176, ORO, 1, FuentePixel.SIN_SOMBRA)


# ---------------------------------------------------------- presentación del nivel
func _intro() -> void:
	draw_rect(Rect2(0, 0, VW, VH), OSCURO)
	var datos: Dictionary = Juego.NIVELES[Juego.nivel]
	FuentePixel.dibujar(self, datos.nombre, Vector2(VW / 2.0, 70), ORO, 2, Color("5a3510"), FuentePixel.CENTRO)
	_centro(datos.subtitulo, 96, CREMA, 1, FuentePixel.SIN_SOMBRA)
	draw_texture_rect_region(_pequeno, Rect2(VW / 2.0 - 32, 124, 16, 16), Rect2(0, 0, 16, 16))
	FuentePixel.dibujar(self, "× " + str(Juego.vidas), Vector2(VW / 2.0 - 6, 130), Color.WHITE, 1, FuentePixel.SIN_SOMBRA)
	var dedicatoria: String = datos.get("dedicatoria", "")
	if dedicatoria != "":
		_centro(dedicatoria, 166, Color("ffb08a"), 1, FuentePixel.SIN_SOMBRA)
		var w := FuentePixel.ancho(dedicatoria)
		EFECTOS._corazon(self, Vector2(roundf(VW / 2.0 - w / 2.0 - 12.0), 167))
		EFECTOS._corazon(self, Vector2(roundf(VW / 2.0 + w / 2.0 + 6.0), 167))


# ---------------------------------------------------------- pausa
func _pausa(t: int) -> void:
	draw_rect(Rect2(0, 0, VW, VH), Color(0.06, 0.04, 0.02, 0.55))
	FuentePixel.dibujar(self, "PAUSA", Vector2(VW / 2.0, 72), ORO, 2, Color("5a3510"), FuentePixel.CENTRO)
	var nombres := {"seguir": "SEGUIR", "opciones": "OPCIONES", "mapa": "SALIR AL MAPA"}
	for i in principal.OPCIONES_PAUSA.size():
		var etiqueta: String = nombres[principal.OPCIONES_PAUSA[i]]
		var y: float = principal.Y_PAUSA + i * 14.0
		var sel: bool = i == principal.menu_pausa
		_centro(etiqueta, y, AMARILLO if sel else Color.WHITE)
		if sel:
			_cursor(etiqueta, y, t)


# ---------------------------------------------------------- final
func _final(t: int) -> void:
	draw_rect(Rect2(0, 0, VW, VH), OSCURO)
	FuentePixel.dibujar_contorno(self, "¡ENHORABUENA!", VW / 2.0, 40, AMARILLO, Color("4a2608"), 2)
	_centro("HAS VENCIDO A LA URRACA EN EL TEATRO ROMANO", 66, CREMA, 1, FuentePixel.SIN_SOMBRA)
	_centro("TIZÓN HA IDO DE LA DEHESA HASTA MÉRIDA", 78, CREMA, 1, FuentePixel.SIN_SOMBRA)
	draw_texture_rect_region(_grande, Rect2(VW / 2.0 - 12, 92, 24, 24), Rect2((1 + ((t >> 3) & 1)) * 24, 0, 24, 24))
	_centro("CALCETINES %d/%d" % [Juego.calcetines_totales(), Juego.NIVELES.size() * 5], 128, Color.WHITE, 1, FuentePixel.SIN_SOMBRA)
	_centro("PUNTOS %07d" % Juego.puntos, 142, Color.WHITE, 1, FuentePixel.SIN_SOMBRA)
	_centro("GRACIAS POR LOS DESAYUNOS, EDUARDO", 160, Color("ffb08a"), 1, FuentePixel.SIN_SOMBRA)
	if principal.temporizador > 90 and ((t >> 5) & 1) != 0:
		_centro("PULSA PARA SEGUIR" if principal.ranking.entra() else "PULSA PARA VOLVER AL INICIO", 182, ORO, 1, FuentePixel.SIN_SOMBRA)
	_estado_ranking(198)


# ---------------------------------------------------------- ranking
## Debajo del fin de partida y del final: si entra en el ranking, si no hay conexión...
func _estado_ranking(y: float) -> void:
	var r: Node = principal.ranking
	var texto := ""
	if Juego.con_codigo and Juego.puntos > 0:
		texto = "LAS PARTIDAS CARGADAS CON CÓDIGO NO ENTRAN EN EL RANKING"
	elif r.datos != null and r.estado == "cargando":
		texto = "MIRANDO EL RANKING..."
	elif r.datos != null and r.estado == "error":
		texto = "SIN CONEXIÓN CON EL RANKING"
	elif r.entra():
		texto = "¡ENTRAS EN EL RANKING!"
	if texto != "":
		_centro(texto, y, AMARILLO if r.entra() else CELESTE, 1, FuentePixel.SIN_SOMBRA)


func _nombre(t: int) -> void:
	var p: Node = principal
	draw_rect(Rect2(0, 0, VW, VH), OSCURO)
	FuentePixel.dibujar_contorno(self, "¡ENTRAS EN EL RANKING!", VW / 2.0, 10, AMARILLO, Color("4a2608"), 2)
	var puntos: int = p.ranking.datos.puntos if p.ranking.datos != null else Juego.puntos
	_centro("PUNTOS %07d" % puntos, 36, CREMA, 1, FuentePixel.SIN_SOMBRA)
	# casillas del nombre (la raya solo en las libres, así un espacio no parece un guion bajo)
	var maximo: int = p.ranking.NOMBRE_MAX
	var x0 := roundf(VW / 2.0 - (maximo * 14 - 4) / 2.0)
	for i in maximo:
		var x := x0 + i * 14
		if i < p.nombre.length():
			FuentePixel.dibujar(self, p.nombre[i], Vector2(x, 54), Color.WHITE, 2)
			continue
		var cursor: bool = i == p.nombre.length() and not p.enviando
		var c := (AMARILLO if ((t >> 4) & 1) != 0 else Color("6b5330")) if cursor else Color("4a3a24")
		draw_rect(Rect2(x, 70, 10, 2), c)
	# teclado
	for f in 3:
		for c in 13:
			var x: float = p.TECLADO_X + c * p.CELDA_W
			var y: float = p.TECLADO_Y + f * p.CELDA_H
			var sel: bool = p.tecla == Vector2i(c, f)
			if sel:
				draw_rect(Rect2(x + 2, y, p.CELDA_W - 4, p.CELDA_H - 2), ORO)
			FuentePixel.dibujar(self, p.TECLADO[f][c], Vector2(x + p.CELDA_W / 2.0, y + 4), Color("1b130a") if sel else CREMA, 1,
				FuentePixel.SIN_SOMBRA if sel else FuentePixel.SOMBRA, FuentePixel.CENTRO)
	for b in p.TECLAS:
		var x: float = p.TECLADO_X + b[2] * p.CELDA_W + 2
		var w: float = (b[3] - b[2] + 1) * p.CELDA_W - 4
		var y: float = p.TECLADO_Y + 3 * p.CELDA_H + 2
		var sel: bool = p.tecla.y == 3 and p.tecla.x >= b[2] and p.tecla.x <= b[3]
		draw_rect(Rect2(x, y, w, p.CELDA_H - 2), ORO if sel else Color("2a2218"))
		var col := Color("1b130a") if sel else (AMARILLO if b[0] == "ok" else CREMA)
		FuentePixel.dibujar(self, b[1], Vector2(x + w / 2.0, y + 4), col, 1, FuentePixel.SIN_SOMBRA, FuentePixel.CENTRO)
	var pie: float = p.TECLADO_Y + 4 * p.CELDA_H + 14
	if p.enviando:
		_centro("ENVIANDO...", pie, CELESTE, 1, FuentePixel.SIN_SOMBRA)
	elif p.nombre_aviso != "":
		_centro(p.nombre_aviso, pie, Color("ffb08a"), 1, FuentePixel.SIN_SOMBRA)
	else:
		_centro("A ESCRIBE · B BORRA · START ACEPTA", pie, Color("b2a283"), 1, FuentePixel.SIN_SOMBRA)
		if not OS.has_feature("mobile"):
			_centro("CON TECLADO PUEDES ESCRIBIR DIRECTAMENTE", pie + 12, Color("b2a283"), 1, FuentePixel.SIN_SOMBRA)


func _ranking(t: int) -> void:
	var p: Node = principal
	var r: Node = p.ranking
	draw_rect(Rect2(0, 0, VW, VH), OSCURO)
	FuentePixel.dibujar_contorno(self, "RANKING", VW / 2.0, 8, AMARILLO, Color("4a2608"), 2)
	if r.estado == "cargando":
		_centro("CARGANDO...", 100, CELESTE, 1, FuentePixel.SIN_SOMBRA)
	elif r.estado == "error":
		_centro("NO HAY CONEXIÓN CON EL RANKING", 100, Color("ffb08a"), 1, FuentePixel.SIN_SOMBRA)
	elif r.lista.is_empty():
		_centro("TODAVÍA NO HAY PUNTUACIONES. ¡SÉ EL PRIMERO!", 100, CREMA, 1, FuentePixel.SIN_SOMBRA)
	else:
		var gris := Color("b2a283")
		for col in ([0, 1] if r.lista.size() > 10 else [0]):
			var x := 200.0 if col == 1 else 14.0
			FuentePixel.dibujar(self, "NOMBRE", Vector2(x + 18, 32), gris, 1, FuentePixel.SIN_SOMBRA)
			FuentePixel.dibujar(self, "PUNTOS", Vector2(x + 116, 32), gris, 1, FuentePixel.SIN_SOMBRA, FuentePixel.DERECHA)
			FuentePixel.dibujar(self, "NIVEL", Vector2(x + 122, 32), gris, 1, FuentePixel.SIN_SOMBRA)
			draw_texture(_calcetin, Vector2(x + 156, 29))
		var colores := [AMARILLO, Color("d9dde6"), Color("e0a070")]
		for i in mini(20, r.lista.size()):
			var f: Dictionary = r.lista[i]
			var x := 14.0 if i < 10 else 200.0
			var y := 46.0 + (i % 10) * 13
			var yo: bool = p.ranking_nombre != "" and f.nombre == p.ranking_nombre
			if yo and ((t >> 4) & 1) != 0:
				draw_rect(Rect2(x - 4, y - 3, 182, 13), Color(ORO, 0.18))
			var c := AMARILLO if yo else CREMA
			FuentePixel.dibujar(self, str(f.pos), Vector2(x + 10, y), colores[i] if i < 3 else gris, 1, FuentePixel.SIN_SOMBRA, FuentePixel.DERECHA)
			FuentePixel.dibujar(self, f.nombre, Vector2(x + 18, y), c, 1, FuentePixel.SIN_SOMBRA)
			FuentePixel.dibujar(self, "%07d" % f.puntos, Vector2(x + 116, y), c, 1, FuentePixel.SIN_SOMBRA, FuentePixel.DERECHA)
			var nv: int = f.nivel
			FuentePixel.dibujar(self, "FIN" if f.final else "%d-%d" % [(nv - 1) / 5 + 1, (nv - 1) % 5 + 1], Vector2(x + 122, y), c, 1, FuentePixel.SIN_SOMBRA)
			FuentePixel.dibujar(self, str(f.calcetines), Vector2(x + 174, y), c, 1, FuentePixel.SIN_SOMBRA, FuentePixel.DERECHA)
	if p.ranking_puesto > 0:
		_centro(("¡ESTÁS EN EL PUESTO %d!" if p.ranking_puesto <= 20 else "ESTÁS EN EL PUESTO %d") % p.ranking_puesto, 182, AMARILLO, 1, FuentePixel.SIN_SOMBRA)
	if p.temporizador > 20 and ((t >> 5) & 1) != 0:
		_centro("PULSA PARA VOLVER", 200, ORO, 1, FuentePixel.SIN_SOMBRA)
