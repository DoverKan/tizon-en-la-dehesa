# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/globo.gd
#  Qué es:   Globo de la Feria: sube a Tizón un rato
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Globo de la Feria: si Tizón lo coge (vale tocar la cuerda), sube despacio un
## rato. Con ↓ lo suelta; si le hacen daño, el globo explota.

@export_range(0, 3) var color := 0
var base_y := 0.0


func _ready() -> void:
	tipo = "globo"
	ancho = 14.0
	alto = 18.0
	activo = true
	base_y = position.y
	sprite.frame = color


func paso(_delta: float) -> void:
	t += 1
	position.y = base_y + roundf(sin(t * 0.05) * 2.0)


## El globo se coge tocando el globo o la cuerda, que llega casi al suelo.
func caja_cuerda() -> Rect2:
	return Rect2(global_position.x - 5.0, global_position.y - alto, 10.0, 30.0)
