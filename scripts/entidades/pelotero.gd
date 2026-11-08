# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/pelotero.gd
#  Qué es:   Pelotero: el enemigo básico
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Pelotero: el enemigo básico. Anda y se aplasta si le saltas encima.

func _ready() -> void:
	tipo = "pelotero"
	ancho = 14.0
	alto = 12.0
	super._ready()


func paso(delta: float) -> void:
	t += 1
	andar(delta, 30.0)
	sprite.frame = 2 if muriendo == "aplastado" else (t >> 3) & 1
	mirar()


func aplastar() -> void:
	muriendo = "aplastado"
	espera = 30
	sprite.frame = 2
	collision_mask = 0
