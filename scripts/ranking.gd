# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/ranking.gd
#  Qué es:   Ranking de jugadores: lee el ranking y envía las puntuaciones a
#            la API (la misma que usa la versión web)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node
## Habla con la API del ranking (tizon_ranking/api.php en el servidor).
## GET devuelve los mejores (uno por nombre); POST guarda una puntuación.
## Las partidas cargadas con un código no entran en el ranking.

const URL := "https://www.doverkan.com/tizon_ranking/api.php"
var url := URL                      # (las pruebas lo cambian por un servidor local)
const ESPERA := 8.0                 # segundos antes de dar la conexión por perdida
const NOMBRE_MAX := 8
const LETRAS := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ0123456789 .-"

signal enviado(respuesta)           # Dictionary con la respuesta del servidor, o null si no hay conexión

var estado := "nada"                # nada, cargando, ok, error
var lista: Array = []
var puestos := 20
## Puntuación de la partida que acaba de terminar (o null si no puede entrar)
var datos = null

var _leer: HTTPRequest
var _enviar: HTTPRequest


func _ready() -> void:
	_leer = HTTPRequest.new()
	_leer.timeout = ESPERA
	_leer.request_completed.connect(_al_leer)
	add_child(_leer)
	_enviar = HTTPRequest.new()
	_enviar.timeout = ESPERA
	_enviar.request_completed.connect(_al_enviar)
	add_child(_enviar)


static func plataforma() -> String:
	match OS.get_name():
		"Windows":
			return "windows"
		"macOS":
			return "macos"
		"Android":
			return "android"
		"iOS":
			return "ios"
		"Web":
			return "godotweb"
	return "linux"


## ¿Puede entrar en el ranking la partida actual?
func puede_entrar() -> bool:
	return url != "" and not Juego.con_codigo and Juego.puntos > 0


## Al acabar la partida (fin de partida o final): se apunta la puntuación y se mira el ranking
func al_acabar(final: bool) -> void:
	datos = null
	if not puede_entrar():
		return
	datos = {
		"puntos": Juego.puntos, "final": final,
		"nivel": Juego.NIVELES.size() if final else mini(Juego.NIVELES.size(), Juego.lejos + 1),
		"calcetines": Juego.calcetines_totales(), "segundos": int(Juego.jugado / 60.0),
	}
	pedir()


func entra() -> bool:
	if datos == null or estado != "ok":
		return false
	return lista.size() < puestos or int(datos.puntos) > int(lista[lista.size() - 1].puntos)


func pedir() -> void:
	estado = "cargando"
	_leer.cancel_request()
	if _leer.request(url, ["Accept: application/json"], HTTPClient.METHOD_GET) != OK:
		estado = "error"


func enviar(nombre: String) -> void:
	var cuerpo: Dictionary = datos.duplicate()
	cuerpo.nombre = nombre
	cuerpo.plataforma = plataforma()
	_enviar.cancel_request()
	var e := _enviar.request(url, ["Content-Type: application/json", "Accept: application/json"], HTTPClient.METHOD_POST, JSON.stringify(cuerpo))
	if e != OK:
		enviado.emit(null)


static func _leer_json(resultado: int, cuerpo: PackedByteArray) -> Variant:
	if resultado != HTTPRequest.RESULT_SUCCESS:
		return null
	var j = JSON.parse_string(cuerpo.get_string_from_utf8())
	return j if typeof(j) == TYPE_DICTIONARY else null


## Solo se aceptan filas con la forma esperada (nada de fiarse de lo que llegue)
static func _limpiar(filas) -> Array:
	var r := []
	if typeof(filas) != TYPE_ARRAY:
		return r
	for f in filas:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var nombre := str(f.get("nombre", "")).to_upper().left(NOMBRE_MAX)
		var limpio := ""
		for ch in nombre:
			if LETRAS.contains(ch):
				limpio += ch
		r.append({
			"pos": int(f.get("pos", r.size() + 1)), "nombre": limpio, "puntos": int(f.get("puntos", 0)),
			"nivel": clampi(int(f.get("nivel", 1)), 1, 10), "final": f.get("final", false) == true,
			"calcetines": clampi(int(f.get("calcetines", 0)), 0, 50),
		})
	return r


func _al_leer(resultado: int, _codigo: int, _cabeceras: PackedStringArray, cuerpo: PackedByteArray) -> void:
	var j = _leer_json(resultado, cuerpo)
	if j != null and j.get("ok", false) == true:
		lista = _limpiar(j.get("ranking", []))
		puestos = int(j.get("puestos", 20))
		estado = "ok"
	else:
		estado = "error"


func _al_enviar(resultado: int, _codigo: int, _cabeceras: PackedStringArray, cuerpo: PackedByteArray) -> void:
	var j = _leer_json(resultado, cuerpo)
	if j != null and j.get("ok", false) == true:
		lista = _limpiar(j.get("ranking", []))
		puestos = int(j.get("puestos", 20))
		estado = "ok"
		datos = null
	enviado.emit(j)
