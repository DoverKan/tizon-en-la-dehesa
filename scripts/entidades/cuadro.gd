# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/cuadro.gd
#  Qué es:   Retrato de Tizón dormido en su cojín, con su placa y el cartel
#            (sala secreta de Badajoz 1-3)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Pieza
## Solo decorado, detrás de Tizón. El origen es el centro de arriba del marco.

const TEX := preload("res://assets/decorado/cuadro_tizon.png")


func _ready() -> void:
	tipo = "cuadro"
	ancho = 56.0
	alto = 72.0
	activo = true
	z_index = -1


func caja() -> Rect2:
	return Rect2(global_position.x - 28.0, global_position.y, ancho, alto)


func paso(_delta: float) -> void:
	pass


func _draw() -> void:
	draw_texture(TEX, Vector2(-28, 0))
	# placa con el nombre
	draw_rect(Rect2(-12, 49, 24, 9), Color("8a5a12"))
	draw_rect(Rect2(-11, 50, 22, 7), Color("e9a21f"))
	FuentePixel.dibujar(self, "TIZÓN", Vector2(0, 50), Color("4a2608"), 1, FuentePixel.SIN_SOMBRA, FuentePixel.CENTRO)
	FuentePixel.dibujar(self, "HECHO CON CARIÑO POR NACHO", Vector2(0, 66), Color("4a2608"), 1, FuentePixel.SIN_SOMBRA, FuentePixel.CENTRO)
