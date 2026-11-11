# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/carpa.gd
#  Qué es:   Carpa del Guadiana: salta del agua
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Carpa del Guadiana: espera bajo el agua y salta en vertical cuando menos te lo
## esperas. Se puede pisar. Se dibuja detrás del agua, así que dentro no se ve.

var estado := "espera"     # espera, salto
var reloj := 0
var base_y := 0.0
var vy := 0.0


func _ready() -> void:
	tipo = "carpa"
	ancho = 12.0
	alto = 16.0
	z_index = -1
	base_y = position.y
	reloj = 40 + (int(position.x / 16.0) * 37) % 90
	visible = false


func paso(_delta: float) -> void:
	t += 1
	if estado == "espera":
		position.y = base_y
		reloj -= 1
		if reloj <= 0 and nivel.en_pantalla(caja(), 0.0):
			estado = "salto"
			vy = -(5.4 + ((t * 7) % 9) / 10.0)
			nivel.salpicar(Vector2(position.x, base_y - 22.0), true)
	else:
		position.y += vy
		vy += 0.2
		if vy > 0.0 and position.y >= base_y:
			position.y = base_y
			estado = "espera"
			reloj = 70 + (t * 13) % 80
			nivel.salpicar(Vector2(position.x, base_y - 22.0), true)
	visible = estado != "espera"
	sprite.frame = 0 if ((t >> 2) & 1) != 0 else 1
	sprite.flip_v = vy > 0.0


func matar_volteo(direccion: float) -> void:
	super.matar_volteo(direccion)
	visible = true
