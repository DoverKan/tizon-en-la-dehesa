# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/entidades/micifuz.gd
#  Qué es:   Micifuz, jefe de la Alcazaba (Mundo 1)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.4 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Cuerpo
## Micifuz, el gato de la Torre de Espantaperros: el jefe de la Alcazaba.
## Espera quieto hasta que Tizón cruza la puerta de su sala; entonces la puerta
## se cierra y empieza la pelea. Hay que pisarle tres veces. Con cada pisotón
## corre y salta más. Las bolas de fuego y las conchas no le hacen nada.

var nombre := "MICIFUZ"
var vidas := 3
var estado := "espera"     # espera, anda, salta, herido, vencido
var reloj := 0
var vx := 0.0              # en píxeles por fotograma, como en la versión web
var vy := 0.0


func _ready() -> void:
	tipo = "micifuz"
	ancho = 28.0
	alto = 24.0
	super._ready()
	activo = true


func _hacia_tizon() -> int:
	return -1 if nivel.jugador.global_position.x < global_position.x else 1


func paso(_delta: float) -> void:
	t += 1
	if estado == "espera":
		var puertas: Array = nivel.puertas()
		if not puertas.is_empty() and nivel.jugador.caja().position.x > (puertas[0].x + 2) * 16.0:
			nivel.empezar_jefe(self)
			estado = "anda"
			reloj = 0
			dir = _hacia_tizon()
		_dibujo()
		return
	reloj += 1
	if estado == "vencido":
		vy += 0.25
		position += Vector2(vx, vy)
		if reloj > 120:
			vivo = false
			nivel.jefe_vencido()
			queue_free()
		_dibujo()
		return
	var rapidez := 0.85 + (3 - vidas) * 0.4
	if estado == "herido":
		vx = move_toward(vx, 0.0, 0.05)
		if reloj > 60:
			estado = "anda"
			reloj = 0
	else:
		if estado == "anda" and reloj % 50 == 0:
			dir = _hacia_tizon()
		vx = rapidez * dir
	vy = minf(vy + 0.375, 4.6)
	velocity = Vector2(vx, vy) * 60.0
	move_and_slide()
	vy = velocity.y / 60.0
	if is_on_wall():
		dir = 1 if get_wall_normal().x > 0.0 else -1
	var suelo := is_on_floor()
	if estado == "salta" and suelo:
		estado = "anda"
		reloj = 1
		Sonido.tocar("golpazo")
	if estado == "anda" and suelo and reloj % maxi(60, 120 - (3 - vidas) * 25) == 0:
		estado = "salta"
		vy = -6.3
		dir = _hacia_tizon()
		if randf() < 0.5:
			Sonido.tocar("maullido")
	_dibujo()


## Tizón le ha pisado y aún le quedan vidas: retrocede y parpadea un rato.
func herir(lado: float) -> void:
	estado = "herido"
	reloj = 0
	vx = lado * 2.2


func vencer(lado: float) -> void:
	estado = "vencido"
	reloj = 0
	vy = -4.0
	vx = lado * 0.6
	collision_mask = 0
	z_index = 5


func _dibujo() -> void:
	sprite.visible = not (estado == "herido" and (t & 2) != 0)
	if estado in ["vencido", "herido"]:
		sprite.frame = 3
	elif estado == "salta":
		sprite.frame = 2
	else:
		sprite.frame = 0 if ((t >> 3) & 1) != 0 else 1
	sprite.flip_h = dir > 0
	sprite.flip_v = estado == "vencido"
