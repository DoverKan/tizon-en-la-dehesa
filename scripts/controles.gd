# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/controles.gd
#  Qué es:   Controles del juego: teclado y mando
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Controles
extends RefCounted
## Controles del juego: teclado y mando. El constructor los guarda en
## project.godot (Proyecto > Configuración > Mapa de entrada) y el juego
## los crea al arrancar si faltan.

const TECLAS := {
	"izquierda": [KEY_LEFT, KEY_A],
	"derecha": [KEY_RIGHT, KEY_D],
	"arriba": [KEY_UP, KEY_W],
	"abajo": [KEY_DOWN, KEY_S],
	"saltar": [KEY_Z, KEY_SPACE, KEY_K],
	"correr": [KEY_X, KEY_SHIFT, KEY_J],
	"vuelta": [KEY_C, KEY_L],
	"pausa": [KEY_ENTER, KEY_P, KEY_ESCAPE],
}
const BOTONES := {
	"izquierda": [JOY_BUTTON_DPAD_LEFT],
	"derecha": [JOY_BUTTON_DPAD_RIGHT],
	"arriba": [JOY_BUTTON_DPAD_UP],
	"abajo": [JOY_BUTTON_DPAD_DOWN],
	"saltar": [JOY_BUTTON_A],
	"vuelta": [JOY_BUTTON_B],
	"correr": [JOY_BUTTON_X, JOY_BUTTON_Y],
	"pausa": [JOY_BUTTON_START],
}
const EJES := {
	"izquierda": [JOY_AXIS_LEFT_X, -1.0],
	"derecha": [JOY_AXIS_LEFT_X, 1.0],
	"arriba": [JOY_AXIS_LEFT_Y, -1.0],
	"abajo": [JOY_AXIS_LEFT_Y, 1.0],
}


static func eventos(accion: String) -> Array:
	var lista := []
	for k in TECLAS.get(accion, []):
		var e := InputEventKey.new()
		e.physical_keycode = k
		lista.append(e)
	for b in BOTONES.get(accion, []):
		var j := InputEventJoypadButton.new()
		j.button_index = b
		lista.append(j)
	if EJES.has(accion):
		var m := InputEventJoypadMotion.new()
		m.axis = EJES[accion][0]
		m.axis_value = EJES[accion][1]
		lista.append(m)
	return lista


## Crea en tiempo de ejecución las acciones que falten.
static func asegurar() -> void:
	for accion in TECLAS:
		if InputMap.has_action(accion) and not InputMap.action_get_events(accion).is_empty():
			continue
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.4)
		for e in eventos(accion):
			InputMap.action_add_event(accion, e)
