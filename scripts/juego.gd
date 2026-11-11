# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/juego.gd
#  Qué es:   Estado de la partida (autoload «Juego»): niveles, guardado, código y opciones
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node
## Estado global de la partida (autoload «Juego»): nivel, vidas, puntos, calcetines,
## partida guardada, código de partida y opciones. El código usa el mismo formato
## que la versión web, así que un código vale en las dos.

const NIVELES := [
	{"escena": "res://niveles/nivel_1_1.tscn", "nombre": "DEHESA 1-1", "subtitulo": "LAS ENCINAS"},
	{"escena": "res://niveles/nivel_1_2.tscn", "nombre": "DEHESA 1-2", "subtitulo": "EL ATARDECER"},
	{"escena": "res://niveles/nivel_1_3.tscn", "nombre": "BADAJOZ 1-3", "subtitulo": "DESAYUNO EN THE CEREAL CAFE", "dedicatoria": "DEDICADO A EDUARDO"},
	{"escena": "res://niveles/nivel_1_4.tscn", "nombre": "GUADIANA 1-4", "subtitulo": "EL PUENTE DE PALMAS"},
	{"escena": "res://niveles/nivel_1_5.tscn", "nombre": "ALCAZABA 1-5", "subtitulo": "TORRE DE ESPANTAPERROS"},
	{"escena": "res://niveles/nivel_2_1.tscn", "nombre": "MEIAC 2-1", "subtitulo": "LOS JARDINES DEL MUSEO"},
	{"escena": "res://niveles/nivel_2_2.tscn", "nombre": "FERIA 2-2", "subtitulo": "LA FERIA DE SAN JUAN"},
	{"escena": "res://niveles/nivel_2_3.tscn", "nombre": "CUEVAS 2-3", "subtitulo": "FUENTES DE LEÓN"},
	{"escena": "res://niveles/nivel_2_4.tscn", "nombre": "CIGÜEÑAS 2-4", "subtitulo": "EL VUELO DE LAS CIGÜEÑAS"},
	{"escena": "res://niveles/nivel_2_5.tscn", "nombre": "MÉRIDA 2-5", "subtitulo": "EL TEATRO ROMANO"},
]
const NIVELES_POR_MUNDO := 5
const RUTA_PARTIDA := "user://partida.json"
const RUTA_RECORD := "user://record.txt"
const RUTA_OPCIONES := "user://opciones.cfg"
const VERSION_PARTIDA := 4  # 4 = dos mundos de cinco niveles, con «lejos» (el nivel más lejano alcanzado)
const PUNTOS_MAX := 1048575  # 20 bits, lo que cabe en el código de partida
const VIDAS_MAX := 63

var nivel := 0
var lejos := 0              # nivel más lejano al que se ha llegado (en el mapa se puede volver a los anteriores)
var cp_nivel := -1          # nivel en el que está encendida la caseta (o -1)
var vidas := 5
var puntos := 0
var huesos := 0
var poder := 0            # 0 pequeño, 1 grande, 2 Zorongollo (fuego), 3 disco volador
var calcetines: Array = []  # un array de 5 booleanos por nivel
var desde_caseta := false
var nuevo_mundo := false    # se acaba de pasar un mundo por primera vez
var record := 0
var partida = null          # última partida guardada (Dictionary) o null
var mundos: Array = []      # nombre y posición de los niveles en el mapa de cada mundo
var opciones := {"efectos": true, "musica": true, "tactil": "auto", "mando": "cruceta", "pantalla_completa": false, "nombre": "", "piloto": false}
# para el ranking: fotogramas jugados y si la partida viene de un código (esas no cuentan)
var jugado := 0
var con_codigo := false
var salto_tactil := false    # el salto o la vuelta que se pulsa ahora viene de los botones táctiles


func _ready() -> void:
	Controles.asegurar()
	calcetines = calcetines_vacios()
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://assets/datos.json"))
	mundos = datos.mundos
	_cargar()
	_cargar_opciones()


func calcetines_vacios() -> Array:
	var a := []
	for i in NIVELES.size():
		a.append([false, false, false, false, false])
	return a


func mundo_de(i: int) -> int:
	return i / NIVELES_POR_MUNDO


func nueva_partida() -> void:
	nivel = 0
	lejos = 0
	cp_nivel = -1
	vidas = 5
	puntos = 0
	huesos = 0
	poder = 0
	desde_caseta = false
	calcetines = calcetines_vacios()
	jugado = 0
	con_codigo = false


func continuar(d: Dictionary) -> void:
	nivel = d.nivel
	lejos = d.lejos
	cp_nivel = d.nivel if d.caseta else -1
	vidas = d.vidas
	puntos = d.puntos
	huesos = d.huesos
	poder = d.poder
	calcetines = d.calcetines.duplicate(true)
	jugado = int(d.get("jugado", 0)) * 60
	con_codigo = d.get("codigo", false) == true


## Al elegir un nivel en el mapa: si su caseta estaba encendida, se empieza en ella.
func entrar(i: int) -> void:
	nivel = i
	desde_caseta = cp_nivel == i


## Se acaba de superar el nivel: se guarda la partida apuntando al siguiente.
func nivel_superado() -> void:
	var siguiente := nivel + 1
	nuevo_mundo = siguiente < NIVELES.size() and siguiente % NIVELES_POR_MUNDO == 0 and lejos < siguiente
	if cp_nivel == nivel:
		cp_nivel = -1
	desde_caseta = false
	guardar(siguiente if siguiente < NIVELES.size() else nivel, false)


func sumar_puntos(n: int) -> void:
	puntos = mini(puntos + n, PUNTOS_MAX)


func calcetines_totales() -> int:
	var n := 0
	for nv in calcetines:
		for c in nv:
			if c:
				n += 1
	return n


# ---------------------------------------------------------------- guardado
func guardar(nivel_guardado: int, caseta: bool) -> void:
	lejos = maxi(lejos, nivel_guardado)
	partida = {
		"v": VERSION_PARTIDA, "nivel": nivel_guardado, "lejos": lejos, "caseta": caseta, "vidas": vidas,
		"puntos": puntos, "huesos": huesos, "poder": poder,
		"calcetines": calcetines.duplicate(true), "t": int(Time.get_unix_time_from_system()),
		"jugado": int(jugado / 60.0), "codigo": con_codigo,
	}
	_escribir_partida()


func _escribir_partida() -> void:
	var f := FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(partida))


## Se han acabado las vidas: se puede seguir desde la partida guardada, pero quien continúa
## empieza con 0 puntos (y 5 vidas, como al empezar). Así no se suman puntos sin fin para el ranking.
func sin_vidas() -> void:
	if partida == null:
		return
	partida.puntos = 0
	partida.vidas = 5
	_escribir_partida()


## «Empezar de cero»: borra la partida guardada (el récord se queda).
func borrar_partida() -> void:
	partida = null
	if FileAccess.file_exists(RUTA_PARTIDA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_PARTIDA))


func guardar_record() -> void:
	if puntos > record:
		record = puntos
		var f := FileAccess.open(RUTA_RECORD, FileAccess.WRITE)
		if f:
			f.store_string(str(record))


func _cargar() -> void:
	if FileAccess.file_exists(RUTA_PARTIDA):
		var f := FileAccess.open(RUTA_PARTIDA, FileAccess.READ)
		if f:
			partida = sanear(JSON.parse_string(f.get_as_text()))
	if FileAccess.file_exists(RUTA_RECORD):
		var r := FileAccess.open(RUTA_RECORD, FileAccess.READ)
		if r:
			record = int(r.get_as_text())


## Quien iba por la Alcazaba en una partida antigua (cuando era el nivel 3) sigue por
## Badajoz, el primero de los niveles nuevos; los calcetines de la Alcazaba se conservan.
func _migrar_antigua(d: Dictionary) -> Dictionary:
	var viejos = d.get("calcetines", [])
	if typeof(viejos) != TYPE_ARRAY:
		viejos = []
	var era_castillo := int(d.get("nivel", 0)) >= 2
	var n := d.duplicate()
	n.v = 3
	n.nivel = 2 if era_castillo else int(d.get("nivel", 0))
	n.caseta = false if era_castillo else d.get("caseta", false)
	n.calcetines = [viejos[0] if viejos.size() > 0 else null, viejos[1] if viejos.size() > 1 else null, null, null, viejos[2] if viejos.size() > 2 else null]
	return n


## Valida una partida leída de disco o de un código: nada de fiarse de lo que venga.
func sanear(d) -> Variant:
	if typeof(d) != TYPE_DICTIONARY:
		return null
	if int(d.get("v", 0)) != VERSION_PARTIDA:
		if int(d.get("v", 0)) != 3:
			d = _migrar_antigua(d)
		d = d.duplicate()
		d.lejos = d.get("nivel", 0)
	var cal := []
	var origen = d.get("calcetines", [])
	for i in NIVELES.size():
		var fila := [false, false, false, false, false]
		if typeof(origen) == TYPE_ARRAY and i < origen.size() and typeof(origen[i]) == TYPE_ARRAY:
			for k in mini(5, origen[i].size()):
				fila[k] = origen[i][k] == true
		cal.append(fila)
	var n := clampi(int(d.get("nivel", 0)), 0, NIVELES.size() - 1)
	return {
		"v": VERSION_PARTIDA,
		"nivel": n,
		"lejos": maxi(n, clampi(int(d.get("lejos", 0)), 0, NIVELES.size() - 1)),
		"caseta": d.get("caseta", false) == true,
		"vidas": clampi(int(d.get("vidas", 5)), 1, VIDAS_MAX),
		"puntos": clampi(int(d.get("puntos", 0)), 0, PUNTOS_MAX),
		"huesos": clampi(int(d.get("huesos", 0)), 0, 99),
		"poder": clampi(int(d.get("poder", 0)), 0, 3),
		"calcetines": cal,
		"t": maxi(0, int(d.get("t", 0))),
		"jugado": clampi(int(d.get("jugado", 0)), 0, 360000),
		"codigo": d.get("codigo", false) == true,
	}


# ---------------------------------------------------------- código de partida
# Versión 4 (de más a menos significativo): versión 3 bits (=4) · nivel 4 · más lejano 4 ·
# caseta 1 · poder 2 · vidas 6 · huesos 7 · puntos 20 · calcetines 50 (5 por nivel) ·
# control 8 = 105 bits = 21 caracteres. No caben en un entero, así que se trabaja bit a bit.
# Los códigos antiguos (versiones 1 y 2 de 13 caracteres y 3 de 15) se siguen pudiendo cargar.
const ALFABETO := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODIGO_V1 := {"ver": 1, "bits_v": 2, "letras": 13, "campos": [["nivel", 3], ["caseta", 1], ["poder", 2], ["vidas", 7], ["huesos", 7], ["puntos", 23], ["calcetines", 10]],
	"bits_control": 8, "mul": 131, "mod": 251, "suma": 7, "niveles": 2}
const CODIGO_V2 := {"ver": 2, "bits_v": 2, "letras": 13, "campos": [["nivel", 3], ["caseta", 1], ["poder", 2], ["vidas", 6], ["huesos", 7], ["puntos", 20], ["calcetines", 15]],
	"bits_control": 7, "mul": 61, "mod": 127, "suma": 7, "niveles": 3}
const CODIGO_V3 := {"ver": 3, "bits_v": 2, "letras": 15, "campos": [["nivel", 3], ["caseta", 1], ["poder", 2], ["vidas", 6], ["huesos", 7], ["puntos", 20], ["calcetines", 25]],
	"bits_control": 9, "mul": 97, "mod": 509, "suma": 13, "niveles": 5}
const CODIGO_V4 := {"ver": 4, "bits_v": 3, "letras": 21, "campos": [["nivel", 4], ["lejos", 4], ["caseta", 1], ["poder", 2], ["vidas", 6], ["huesos", 7], ["puntos", 20], ["calcetines", 50]],
	"bits_control": 8, "mul": 89, "mod": 251, "suma": 17, "niveles": 10}


static func _bits(valor: int, n: int) -> Array:
	var r := []
	for i in range(n - 1, -1, -1):
		r.append((valor >> i) & 1)
	return r


static func _numero(bits: Array, desde: int, n: int) -> int:
	var v := 0
	for i in n:
		v = (v << 1) | int(bits[desde + i])
	return v


## Resto de dividir el número (escrito en bits) entre m, sin pasarse de un entero
static func _resto(bits: Array, m: int) -> int:
	var r := 0
	for b in bits:
		r = (r * 2 + int(b)) % m
	return r


func codigo(d: Dictionary) -> String:
	var F: Dictionary = CODIGO_V4
	var bits := _bits(F.ver, F.bits_v)
	for campo in F.campos:
		var nombre: String = campo[0]
		var n: int = campo[1]
		var v := 0
		if nombre == "caseta":
			v = 1 if d.caseta else 0
		elif nombre == "lejos":
			v = maxi(int(d.get("lejos", 0)), int(d.nivel))
		elif nombre == "calcetines":
			for li in mini(F.niveles, d.calcetines.size()):
				for i in 5:
					if d.calcetines[li][i]:
						v |= 1 << (li * 5 + i)
		else:
			v = int(d[nombre])
		bits.append_array(_bits(clampi(v, 0, (1 << n) - 1), n))
	var control: int = (_resto(bits, F.mod) * F.mul + F.suma) % F.mod
	bits.append_array(_bits(control, F.bits_control))
	var s := ""
	for i in F.letras:
		s += ALFABETO[_numero(bits, i * 5, 5)]
	return s.substr(0, 7) + "-" + s.substr(7, 7) + "-" + s.substr(14)


func leer_codigo(texto: String) -> Variant:
	var s := texto.to_upper().replace("-", "").replace(" ", "")
	var candidatos := {13: [CODIGO_V1, CODIGO_V2], 15: [CODIGO_V3], 21: [CODIGO_V4]}
	if not candidatos.has(s.length()):
		return null
	var bits := []
	for ch in s:
		var i := ALFABETO.find(ch)
		if i < 0:
			return null
		bits.append_array(_bits(i, 5))
	for F in candidatos[s.length()]:
		var total: int = F.bits_v + F.bits_control
		for campo in F.campos:
			total += campo[1]
		var sobra: int = bits.size() - total
		for i in sobra:
			if bits[i] != 0:
				return null        # sobran bits por arriba
		if _numero(bits, sobra, F.bits_v) != F.ver:
			continue
		var cuerpo := bits.slice(sobra, bits.size() - F.bits_control)
		var control := _numero(bits, bits.size() - F.bits_control, F.bits_control)
		if (_resto(cuerpo, F.mod) * F.mul + F.suma) % F.mod != control:
			return null
		var d := {}
		var pos: int = F.bits_v
		for campo in F.campos:
			if campo[0] == "calcetines":
				var cal := []
				var b := cuerpo.slice(pos, pos + campo[1])
				b.reverse()      # el bit menos significativo es el primer calcetín del primer nivel
				for li in F.niveles:
					var fila := []
					for i in 5:
						fila.append(b[li * 5 + i] == 1)
					cal.append(fila)
				d.calcetines = cal
			else:
				d[campo[0]] = _numero(cuerpo, pos, campo[1])
			pos += campo[1]
		d.caseta = d.caseta == 1
		d.t = int(Time.get_unix_time_from_system())
		d.v = VERSION_PARTIDA if F.ver == 4 else (3 if F.ver == 3 else 0)
		return sanear(d)
	return null


func cargar_codigo(texto: String) -> bool:
	var d = leer_codigo(texto)
	if d == null:
		return false
	d.codigo = true           # las partidas cargadas con código no entran en el ranking
	partida = d
	_escribir_partida()
	return true


# ---------------------------------------------------------- opciones
func _cargar_opciones() -> void:
	var cf := ConfigFile.new()
	if cf.load(RUTA_OPCIONES) == OK:
		for k in opciones:
			var v = cf.get_value("opciones", k, opciones[k])
			if typeof(v) == typeof(opciones[k]):
				opciones[k] = v
	if not opciones.tactil in ["auto", "si", "no"]:
		opciones.tactil = "auto"
	if not opciones.mando in ["cruceta", "joystick"]:
		opciones.mando = "cruceta"
	aplicar_opciones()


func guardar_opciones() -> void:
	var cf := ConfigFile.new()
	for k in opciones:
		cf.set_value("opciones", k, opciones[k])
	cf.save(RUTA_OPCIONES)
	aplicar_opciones()


func aplicar_opciones() -> void:
	Sonido.efectos_activos = opciones.efectos
	Sonido.poner_musica_activa(opciones.musica)
	if not OS.has_feature("mobile") and not OS.has_feature("web") and DisplayServer.get_name() != "headless":
		var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if opciones.pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != modo and not (modo == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(modo)


## ¿Se enseñan los botones táctiles?
func con_tactil() -> bool:
	if opciones.tactil == "si":
		return true
	if opciones.tactil == "no":
		return false
	return DisplayServer.is_touchscreen_available()
