# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/cardo.gd
#  Qué es:   Cardo mordedor que sale de las encinas
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.2 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Cardo mordedor: sale del agujero de la encina y vuelve a esconderse.
## No sale si Tizón está muy cerca. No se puede pisar: solo la vuelta, el
## fuego o una concha acaban con él. Se dibuja detrás de las losetas.

var fuera := 0.0
var estado := "escondido"
var espera := 60


func _ready() -> void:
	tipo = "cardo"
	ancho = 12.0
	alto = 1.0
	z_index = -1
	sprite.position.y = 12.0


func paso(_delta: float) -> void:
	t += 1
	espera -= 1
	var cerca: bool = absf(nivel.jugador.global_position.x - global_position.x) < 30.0
	match estado:
		"escondido":
			if espera <= 0:
				if cerca:
					espera = 20
				else:
					estado = "subiendo"
		"subiendo":
			fuera = minf(24.0, fuera + 0.8)
			if fuera >= 24.0:
				estado = "fuera"
				espera = 70
		"fuera":
			if espera <= 0:
				estado = "bajando"
		"bajando":
			fuera = maxf(0.0, fuera - 0.8)
			if fuera <= 0.0:
				estado = "escondido"
				espera = 90
	alto = maxf(1.0, minf(22.0, fuera))
	sprite.position.y = 12.0 - fuera
	sprite.frame = (t >> 4) & 1


func caja() -> Rect2:
	return Rect2(global_position.x - ancho / 2.0, global_position.y - alto, ancho, alto)
