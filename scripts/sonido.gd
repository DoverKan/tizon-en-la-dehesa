# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  scripts/sonido.gd
#  Qué es:   Efectos de sonido y música (autoload «Sonido»)
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.3 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

extends Node
## Efectos y música (autoload «Sonido»). Los WAV se generaron con la misma
## síntesis que la versión web. Los efectos y la música se pueden apagar por
## separado en las opciones.

const EFECTOS := [
	"saltar", "vuelta", "hueso", "pisar", "patada", "golpe", "romper", "brotar", "poder",
	"perder_poder", "fuego", "vida", "calcetin", "caseta", "tic", "pausa", "prisa", "morir",
	"nivel_superado", "fin_partida", "ladrido", "pasadizo", "golpazo", "maullido", "golpe_jefe",
	# Badajoz, el Guadiana y el Mundo 2
	"rebote", "chapoteo", "plof", "aleteo", "interruptor", "reventar", "chorro", "graznido",
	"campanilla", "derrumbe",
]

var efectos_activos := true
var musica_activa := true
var _efectos := {}
var _canales: Array[AudioStreamPlayer] = []
var _siguiente := 0
var _musica: AudioStreamPlayer
var _prisa := false
var _sonando := false        # el juego quiere música ahora (aunque esté apagada en las opciones)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in EFECTOS:
		_efectos[n] = load("res://assets/sonido/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -3.0
		add_child(p)
		_canales.append(p)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -6.0
	var m: AudioStreamWAV = load("res://assets/sonido/musica.wav")
	m.loop_mode = AudioStreamWAV.LOOP_FORWARD
	m.loop_begin = 0
	m.loop_end = int(m.get_length() * m.mix_rate)
	_musica.stream = m
	add_child(_musica)


func tocar(nombre: String) -> void:
	if not efectos_activos or not _efectos.has(nombre):
		return
	var p := _canales[_siguiente]
	_siguiente = (_siguiente + 1) % _canales.size()
	p.stream = _efectos[nombre]
	p.play()


func musica(prisa := false) -> void:
	_prisa = prisa
	_sonando = true
	_musica.pitch_scale = 1.24 if prisa else 1.0
	if not _musica.playing and musica_activa:
		_musica.play()


func parar_musica() -> void:
	_sonando = false
	_musica.stop()


func poner_musica_activa(si: bool) -> void:
	musica_activa = si
	if not si:
		_musica.stop()
	elif _sonando and not _musica.playing:
		_musica.play()
