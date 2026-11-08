# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/cuerpo.gd
#  Qué es:   Base de lo que anda con física: enemigos, objetos que caen y bolas de fuego
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

class_name Cuerpo
extends CharacterBody2D
## Base de todo lo que anda con física (enemigos, objetos que caen, bolas de fuego).
## El origen del nodo está en los pies, en el centro: así cambiar de tamaño no lo mueve.
## El nivel llama a paso(delta) en cada fotograma de física.

const GRAVEDAD := 1350.0
const CAIDA_MAX := 276.0

@export var ancho := 14.0
@export var alto := 12.0

var tipo := ""
var nivel: Nivel = null
var vivo := true
var activo := false
var muriendo := ""      # "", "volteo", "aplastado"
var t := 0
var dir := -1
var espera := 0         # fotogramas restantes de "aplastado"
@onready var sprite: Sprite2D = get_node_or_null("Sprite")


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 4.0
	poner_forma(ancho, alto)


func poner_forma(w: float, h: float) -> void:
	ancho = w
	alto = h
	var forma := get_node_or_null("Forma") as CollisionShape2D
	if forma == null:
		forma = CollisionShape2D.new()
		forma.name = "Forma"
		add_child(forma)
	var r := RectangleShape2D.new()
	r.size = Vector2(w, h)
	forma.shape = r
	forma.position = Vector2(0, -h / 2.0)


func caja() -> Rect2:
	return Rect2(global_position.x - ancho / 2.0, global_position.y - alto, ancho, alto)


func caer(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVEDAD * delta, CAIDA_MAX)


## Andar en una dirección y dar la vuelta al chocar con una pared.
func andar(delta: float, velocidad: float) -> void:
	velocity.x = velocidad * dir
	caer(delta)
	move_and_slide()
	if is_on_wall():
		dir = -dir
	if nivel and nivel.al_agua(self):
		return
	if nivel and global_position.y > nivel.fondo_zona(self) + 32:
		quitar()


func matar_volteo(direccion: float) -> void:
	muriendo = "volteo"
	velocity = Vector2(direccion * 66.0, -216.0)
	collision_mask = 0
	if sprite:
		sprite.flip_v = true
	z_index = 5


func paso_muriendo(delta: float) -> void:
	if muriendo == "volteo":
		velocity.y += 1080.0 * delta
		position += velocity * delta
		if nivel and global_position.y > nivel.camara.position.y + 260:
			quitar()
	elif muriendo == "aplastado":
		espera -= 1
		if espera <= 0:
			quitar()


func quitar() -> void:
	vivo = false
	queue_free()


func mirar(izquierda_por_defecto := true) -> void:
	# Los sprites de enemigos miran a la izquierda; los de objetos, a la derecha
	if sprite:
		sprite.flip_h = (dir > 0) if izquierda_por_defecto else (dir < 0)
