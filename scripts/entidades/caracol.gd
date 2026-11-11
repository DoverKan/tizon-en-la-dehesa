# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/caracol.gd
#  Qué es:   Caracol y su concha (y la pelota de tenis del MEIAC)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Caracol. Si le saltas encima se mete en la concha: la concha se puede patear,
## coger con la boca (mantén correr) y lanzar. Una concha lanzada rompe corcho,
## abre colmenas y se lleva por delante a los demás enemigos.

const VELOCIDAD_CONCHA := 216.0

var estado := "caracol"   # caracol, concha
var pateada := false
var en_boca := false
var gracia := 0
var quieta := 0
var cadena := 0
## La pelota de tenis del MEIAC se porta como una concha que nunca vuelve a ser caracol.
@export var pelota := false


func _ready() -> void:
	tipo = "caracol"
	ancho = 14.0
	alto = 14.0
	super._ready()
	if pelota:
		sprite.texture = load("res://assets/sprites/pelota.png")
		sprite.hframes = 2
		meterse()
		poner_forma(12.0, 13.0)
		gracia = 0


func meterse() -> void:
	estado = "concha"
	tipo = "concha"
	poner_forma(14.0, 13.0)
	pateada = false
	velocity.x = 0.0
	quieta = 0
	gracia = 8


func lanzar(direccion: float, vx: float, vy: float) -> void:
	en_boca = false
	collision_mask = 1
	if direccion != 0.0:
		pateada = true
		cadena = 0
		velocity = Vector2(VELOCIDAD_CONCHA * direccion, 0.0)
	else:
		pateada = false
		velocity = Vector2(vx, vy)
	quieta = 0


func paso(delta: float) -> void:
	t += 1
	if estado == "caracol":
		andar(delta, 30.0)
		sprite.frame = (t >> 4) & 1
		sprite.rotation = 0.0
		sprite.position = Vector2(0, -7)
		mirar()
		return
	# concha
	sprite.frame = (((t >> 2) & 1) if pateada else 0) if pelota else 2
	sprite.position = Vector2(0, -6)
	sprite.flip_h = false
	if gracia > 0:
		gracia -= 1
	if en_boca:
		collision_mask = 0
		return
	caer(delta)
	var vx_antes := velocity.x
	move_and_slide()
	if pateada:
		sprite.rotation = 0.0 if pelota else deg_to_rad(90.0 * ((t >> 2) % 4) * signf(vx_antes))
		if is_on_wall():
			var lado := signf(vx_antes)
			if nivel.en_pantalla(caja(), 8.0):
				var celda: Vector2i = nivel.celda_en(global_position + Vector2(lado * (ancho / 2.0 + 2.0), -alto / 2.0))
				if nivel.tipo_en(celda) in ["corcho", "colmena", "colmena_poder", "colmena_disco", "corcho_multi"]:
					nivel.golpear_bloque(celda, "concha")
				Sonido.tocar("golpe")
			velocity.x = -lado * VELOCIDAD_CONCHA
		else:
			velocity.x = vx_antes
		if not nivel.en_pantalla(caja(), 384.0):
			quitar()
	else:
		sprite.rotation = 0.0
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 432.0 * delta)
		quieta += 1
		if quieta > 600 and not pelota:
			sprite.position.x = float((t >> 1) & 1)
		if quieta > 720 and not pelota:
			estado = "caracol"
			tipo = "caracol"
			poner_forma(14.0, 14.0)
			dir = -1 if nivel.jugador.global_position.x < global_position.x else 1
	if nivel.al_agua(self):
		return
	if global_position.y > nivel.fondo_zona(self) + 32:
		quitar()
