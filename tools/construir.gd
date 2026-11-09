# ============================================================================
#  Tizón en la Dehesa
#  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
#
#  Archivo:  tools/construir.gd
#  Qué es:   Constructor: genera el TileSet y las escenas a partir de los mapas de texto
#  Autor:    Nacho Cano (DoverKan)
#  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
#  Versión:  1.0 (noviembre de 2026)
#  © 2026 Nacho Cano
# ============================================================================

@tool
extends SceneTree
## Constructor del proyecto. Genera:
##   - el mapa de controles en project.godot
##   - tiles/losetas.tres (TileSet con colisiones y el dato «tipo» de cada loseta)
##   - las escenas de Tizón, enemigos, objetos y decorado (escenas/...)
##   - las escenas de nivel (niveles/nivel_*.tscn) a partir de niveles/mapas/*.txt
## Ejecútalo en terminal:  godot --headless --path . --script res://tools/construir.gd
## Ojo: vuelve a escribir las escenas de nivel; si las has editado a mano en el
## editor, esos cambios se pierden. Edita o el .txt o la escena, no las dos.

const T := 16
var tileset: TileSet
var fuente: TileSetAtlasSource
var datos: Dictionary


func _initialize() -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string("res://assets/datos.json"))
	_controles()
	_crear_tileset()
	_crear_escenas()
	for f in DirAccess.get_files_at("res://niveles"):
		if f.ends_with(".tscn"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("res://niveles/" + f))
	for f in DirAccess.get_files_at("res://niveles/mapas"):
		if f.ends_with(".txt"):
			_crear_nivel("res://niveles/mapas/" + f, "res://niveles/" + f.get_basename() + ".tscn")
	print("Construcción terminada")
	quit()


# ------------------------------------------------------------------ controles
func _controles() -> void:
	for accion in Controles.TECLAS:
		ProjectSettings.set_setting("input/" + accion, {"deadzone": 0.4, "events": Controles.eventos(accion)})
	ProjectSettings.save()


# ------------------------------------------------------------------ tileset
## Las losetas nuevas van a partir de la fila 16 del atlas (ver la tabla del README).
func _crear_tileset() -> void:
	tileset = TileSet.new()
	tileset.tile_size = Vector2i(T, T)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "tipo")
	tileset.set_custom_data_layer_type(0, TYPE_STRING)
	fuente = TileSetAtlasSource.new()
	fuente.texture = load("res://assets/tiles/losetas.png")
	fuente.texture_region_size = Vector2i(T, T)
	tileset.add_source(fuente, 0)
	# suelo de cada tema: 4 filas de variantes; la columna es la forma (borde arriba, izquierda, derecha)
	for fila in [0, 4, 11, 16, 20, 24, 28]:
		for v in 4:
			for m in 8:
				_loseta(Vector2i(m, fila + v), "suelo", "solido")
	var fila8 := ["corcho", "corcho_multi", "usado", "piedra", "tablon", "tronco", "tronco", "tronco", "tronco", "flor", "flor", "flor", "matorral", "matorral"]
	for i in fila8.size():
		var tipo: String = fila8[i]
		var col := "solido"
		if tipo == "tablon":
			col = "una_cara"
		elif tipo in ["flor", "matorral"]:
			col = ""
		_loseta(Vector2i(i, 8), tipo, col)
	_loseta(Vector2i(0, 9), "colmena", "solido", 4)
	_loseta(Vector2i(4, 9), "colmena_poder", "solido", 4)
	_loseta(Vector2i(8, 9), "colmena_disco", "solido", 4)
	_loseta(Vector2i(0, 10), "hueso", "", 4)
	_loseta(Vector2i(13, 10), "invisible", "solido")
	_loseta(Vector2i(14, 10), "toldo", "una_cara")      # toldo mientras rebota (se dibuja aparte)
	_loseta(Vector2i(0, 15), "pinchos", "")
	# Badajoz y el Guadiana
	for v in 4:
		for m in 8:
			_loseta(Vector2i(m, 32 + v), "granito", "solido")
	for k in 4:
		for c in 16:
			_loseta(Vector2i(c, 36 + k), "pared", "")
	for e in 4:
		_loseta(Vector2i(e, 40), "tejado", "una_cara")
		_loseta(Vector2i(4 + e, 40), "toldo", "una_cara")
		_loseta(Vector2i(8 + e, 40), "toldo", "una_cara")
	_loseta(Vector2i(12, 40), "tablon", "una_cara")       # balcón
	_loseta(Vector2i(13, 40), "tablon", "una_cara")
	_loseta(Vector2i(14, 40), "valla", "")
	_loseta(Vector2i(15, 40), "seto", "")
	_loseta(Vector2i(0, 41), "agua", "", 4, 0.1333)
	_loseta(Vector2i(4, 41), "agua", "")
	# Mundo 2
	_loseta(Vector2i(5, 41), "seta", "")
	_loseta(Vector2i(6, 41), "interruptor", "solido")
	_loseta(Vector2i(7, 41), "interruptor", "solido")
	_loseta(Vector2i(8, 41), "rojo", "solido")
	_loseta(Vector2i(9, 41), "rojo_hueco", "")
	_loseta(Vector2i(10, 41), "azul", "solido")
	_loseta(Vector2i(11, 41), "azul_hueco", "")
	_loseta(Vector2i(12, 41), "desmorona", "solido")
	_loseta(Vector2i(13, 41), "desmorona", "solido")
	for e in 4:
		_loseta(Vector2i(e, 42), "nube", "una_cara")
		_loseta(Vector2i(4 + e, 42), "columna", "solido")
		_loseta(Vector2i(e, 43), "poste", "")
	_loseta(Vector2i(8, 42), "guirnalda", "", 4, 0.2667)
	for n in datos.arcos:
		var base: Array = datos.arcos[n]
		for a in int(n):
			_loseta(Vector2i(int(base[0]) + a, int(base[1])), "arco", "")
	ResourceSaver.save(tileset, "res://tiles/losetas.tres")
	tileset = load("res://tiles/losetas.tres")


func _loseta(c: Vector2i, tipo: String, colision: String, frames := 1, duracion := 0.13) -> void:
	fuente.create_tile(c)
	if frames > 1:
		fuente.set_tile_animation_columns(c, frames)
		fuente.set_tile_animation_frames_count(c, frames)
		for i in frames:
			fuente.set_tile_animation_frame_duration(c, i, duracion)
	var td := fuente.get_tile_data(c, 0)
	td.set_custom_data("tipo", tipo)
	if colision == "solido":
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	elif colision == "una_cara":
		# tablón, tejado, toldo y nube: se atraviesan desde abajo y se pisan desde arriba
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, -2), Vector2(-8, -2)]))
		td.set_collision_polygon_one_way(0, 0, true)


# ------------------------------------------------------------------ escenas
func _guardar(raiz: Node, ruta: String) -> void:
	_poner_dueno(raiz, raiz)
	var ps := PackedScene.new()
	var err := ps.pack(raiz)
	if err != OK:
		push_error("No se pudo empaquetar " + ruta)
	ResourceSaver.save(ps, ruta)
	raiz.free()


func _poner_dueno(n: Node, dueno: Node) -> void:
	for h in n.get_children():
		h.owner = dueno
		_poner_dueno(h, dueno)


func _sprite(raiz: Node, tex: String, hframes: int, pos: Vector2, centrado := true, vframes := 1) -> void:
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.texture = load(tex)
	s.hframes = hframes
	s.vframes = vframes
	s.centered = centrado
	s.position = pos
	raiz.add_child(s)


func _forma(raiz: Node, w: float, h: float) -> void:
	var f := CollisionShape2D.new()
	f.name = "Forma"
	var r := RectangleShape2D.new()
	r.size = Vector2(w, h)
	f.shape = r
	f.position = Vector2(0, -h / 2.0)
	raiz.add_child(f)


func _entidad(nombre: String, clase: String, script: String, tex: String, hframes: int, pos: Vector2, forma := Vector2.ZERO, vframes := 1) -> void:
	var r: Node2D = CharacterBody2D.new() if clase == "cuerpo" else Node2D.new()
	r.name = nombre.capitalize().replace(" ", "")
	r.set_script(load(script))
	if tex != "":
		_sprite(r, tex, hframes, pos, true, vframes)
	if forma != Vector2.ZERO:
		_forma(r, forma.x, forma.y)
	_guardar(r, "res://escenas/entidades/%s.tscn" % nombre)


## Decorado grande (farolas, naranjos, esculturas...): solo un dibujo detrás de Tizón.
## El origen es la esquina de arriba a la izquierda de su casilla.
func _decorado(nombre: String, tex: String, desplazamiento: Vector2, hframes := 1) -> void:
	var s := Sprite2D.new()
	s.name = nombre.capitalize()
	s.texture = load(tex)
	s.hframes = hframes
	s.centered = false
	s.offset = desplazamiento
	s.z_index = -1
	_guardar(s, "res://escenas/decorado/%s.tscn" % nombre)


func _crear_escenas() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://escenas/decorado"))
	var S := "res://assets/sprites/"
	var E := "res://scripts/entidades/"
	_entidad("pelotero", "cuerpo", E + "pelotero.gd", S + "pelotero.png", 3, Vector2(0, -6), Vector2(14, 12))
	_entidad("caracol", "cuerpo", E + "caracol.gd", S + "caracol.png", 3, Vector2(0, -7), Vector2(14, 14))
	_entidad("abejorro", "pieza", E + "abejorro.gd", S + "abejorro.png", 2, Vector2(0, -5))
	_entidad("cardo", "pieza", E + "cardo.gd", S + "cardo.png", 2, Vector2(0, -12))
	_entidad("calcetin", "pieza", E + "calcetin.gd", S + "calcetin.png", 1, Vector2(0, -7))
	_entidad("caseta", "pieza", E + "caseta.gd", S + "caseta.png", 2, Vector2(0, -13.5))
	_entidad("objeto", "cuerpo", E + "objeto.gd", S + "galleta.png", 1, Vector2(0, -6), Vector2(14, 13))
	_entidad("disco", "pieza", E + "disco.gd", S + "disco.png", 1, Vector2(0, -3))
	_entidad("bola_fuego", "cuerpo", E + "bola_fuego.gd", S + "bola_fuego.png", 2, Vector2(0, -4), Vector2(8, 8))
	_entidad("hueso_saltarin", "pieza", E + "hueso_saltarin.gd", S + "hueso.png", 4, Vector2(0, -8))
	_entidad("meta", "pieza", E + "meta.gd", "", 1, Vector2.ZERO)
	_entidad("plataforma", "pieza", E + "plataforma.gd", "", 1, Vector2.ZERO)
	_entidad("pasadizo", "pieza", E + "pasadizo.gd", "", 1, Vector2.ZERO)
	_entidad("cuadro", "pieza", E + "cuadro.gd", "", 1, Vector2.ZERO)
	# Alcazaba
	_entidad("antorcha", "pieza", E + "antorcha.gd", S + "antorcha.png", 3, Vector2(8, 6))
	_entidad("barra_fuego", "pieza", E + "barra_fuego.gd", "", 1, Vector2.ZERO)
	_entidad("rastrillo", "pieza", E + "rastrillo.gd", "", 1, Vector2.ZERO)
	_entidad("murcielago", "pieza", E + "murcielago.gd", S + "murcielago.png", 3, Vector2(0, -5))
	_entidad("micifuz", "cuerpo", E + "micifuz.gd", S + "micifuz.png", 4, Vector2(0, -14), Vector2(28, 24))
	_entidad("puerta", "pieza", E + "puerta.gd", "", 1, Vector2.ZERO)
	# Badajoz y el Guadiana
	_entidad("paloma", "cuerpo", E + "paloma.gd", S + "paloma.png", 4, Vector2(0, -7), Vector2(12, 10))
	_entidad("vecino", "pieza", E + "vecino.gd", S + "vecinos.png", 2, Vector2(0, -12), Vector2.ZERO, 4)
	_entidad("eduardo", "pieza", E + "eduardo.gd", S + "eduardo.png", 2, Vector2(0, -12))
	_entidad("cafe", "pieza", E + "cafe.gd", S + "cafe.png", 1, Vector2(72, -56), Vector2.ZERO)
	_entidad("carpa", "pieza", E + "carpa.gd", S + "carpa.png", 2, Vector2(0, -8))
	# Mundo 2
	_entidad("aspersor", "pieza", E + "aspersor.gd", "", 1, Vector2.ZERO)
	_entidad("globo", "pieza", E + "globo.gd", S + "globo.png", 4, Vector2(0, -5))
	_entidad("pato", "pieza", E + "pato.gd", S + "pato.png", 1, Vector2(0, -8))
	_entidad("estalactita", "pieza", E + "estalactita.gd", S + "estalactita.png", 1, Vector2(0, -6))
	_entidad("luciernaga", "pieza", E + "luciernaga.gd", "", 1, Vector2.ZERO)
	_entidad("milano", "pieza", E + "milano.gd", S + "milano.png", 3, Vector2(0, -5))
	_entidad("urraca", "pieza", E + "urraca.gd", S + "urraca.png", 5, Vector2(0, -12))
	_entidad("noria", "pieza", E + "noria.gd", "", 1, Vector2.ZERO)
	var D := "res://assets/decorado/"
	_decorado("farola", D + "farola.png", Vector2(0, -32))
	_decorado("naranjo", D + "naranjo.png", Vector2(-8, -32))
	_decorado("escultura", D + "escultura.png", Vector2(0, -32), 2)
	_decorado("canas", D + "canas.png", Vector2(0, -8))
	_decorado("banco", D + "banco.png", Vector2.ZERO)
	_decorado("mesa", D + "mesa.png", Vector2.ZERO)
	# Tizón
	var j := CharacterBody2D.new()
	j.name = "Tizon"
	j.set_script(load("res://scripts/tizon.gd"))
	_sprite(j, S + "tizon_pequeno.png", 5, Vector2(-8, -16), false)
	_forma(j, 12, 13)
	_guardar(j, "res://escenas/jugador.tscn")
	# escena principal
	var p := Node.new()
	p.name = "Principal"
	p.set_script(load("res://scripts/principal.gd"))
	_guardar(p, "res://escenas/principal.tscn")


# ------------------------------------------------------------------ niveles
const LOSETAS := {"B": "corcho", "C": "corcho_multi", "H": "colmena", "P": "colmena_poder", "V": "colmena_disco", "S": "piedra", "^": "pinchos",
	"!": "interruptor", "[": "rojo", "]": "azul_hueco", "+": "desmorona"}
const ATLAS := {"corcho": Vector2i(0, 8), "corcho_multi": Vector2i(1, 8), "usado": Vector2i(2, 8), "piedra": Vector2i(3, 8), "tablon": Vector2i(4, 8),
	"colmena": Vector2i(0, 9), "colmena_poder": Vector2i(4, 9), "colmena_disco": Vector2i(8, 9), "pinchos": Vector2i(0, 15),
	"interruptor": Vector2i(6, 41), "rojo": Vector2i(8, 41), "azul_hueco": Vector2i(11, 41), "desmorona": Vector2i(12, 41)}
## Fila del atlas donde empieza el suelo de cada tema
const FILA_SUELO := {"dehesa": 0, "atardecer": 0, "rio": 0, "jardin": 0, "cueva": 4, "gruta": 4, "castillo": 11, "cielo": 11,
	"ciudad": 16, "museo": 20, "feria": 24, "romano": 28}
## Casillas sólidas, para saber hasta dónde bajan los postes de los toldos
const SOLIDO := "#BCHPVSTN!|+[f"
const DECORADO := {"l": "farola", "j": "naranjo", "Y": "escultura", "k": "canas", "u": "banco", "y": "mesa"}
const SALUDOS := {
	"ciudad": ["¡HOLA, TIZÓN!", "¡BUENOS DÍAS, TIZÓN!", "¡QUÉ GUAPO VAS HOY!", "¿VAS AL CAFÉ, TIZÓN?", "¡MIRA, ES TIZÓN!", "¡DALE RECUERDOS A EDUARDO!", "¡TIZÓN, QUÉ BIGOTES!"],
	"rio": ["¡NO TE MOJES, TIZÓN!", "¡CUIDADO CON LAS CARPAS!", "¡BUEN PASEO, TIZÓN!", "¡ADIÓS, CAMPEÓN!"],
}


func _crear_nivel(ruta_txt: String, ruta_tscn: String) -> void:
	var texto := FileAccess.get_file_as_string(ruta_txt)
	var cab := {"nombre": "DEHESA", "subtitulo": "", "dedicatoria": "", "avance": "0"}
	var zonas := []
	for linea in texto.split("\n"):
		var l := linea.strip_edges()
		# las líneas con # son comentarios solo antes de la primera zona (en el mapa, # es suelo)
		if l == "" or (zonas.is_empty() and l.begins_with("#")):
			continue
		if zonas.is_empty() and l.contains("=") and cab.has(l.get_slice("=", 0)):
			cab[l.get_slice("=", 0)] = l.substr(l.find("=") + 1)
		elif l.begins_with("[zona"):
			var partes := l.trim_prefix("[").trim_suffix("]").split(" ")
			zonas.append({"nombre": partes[1], "tema": partes[2], "filas": []})
		elif not zonas.is_empty():
			zonas[-1].filas.append(l)
	var raiz := Node2D.new()
	raiz.name = "Nivel"
	raiz.set_script(load("res://scripts/nivel.gd"))
	raiz.set("nombre", cab.nombre)
	raiz.set("subtitulo", cab.subtitulo)
	raiz.set("dedicatoria", cab.dedicatoria)
	raiz.set("avance", float(cab.avance))
	var suelo := _capa(raiz, "Suelo")
	var huesos := _capa(raiz, "Huesos")
	var decorado := _capa(raiz, "Decorado")
	var nodo_zonas := Node2D.new()
	nodo_zonas.name = "Zonas"
	raiz.add_child(nodo_zonas)
	var ents := Node2D.new()
	ents.name = "Entidades"
	raiz.add_child(ents)
	raiz.move_child(decorado, 0)
	var oy := 0
	var calcetines := 0
	for z in zonas:
		var filas: Array = z.filas
		var tema: String = z.tema
		var h := filas.size()
		var w := 0
		for f in filas:
			w = maxi(w, f.length())
		var zn := Node2D.new()
		zn.name = String(z.nombre).capitalize()
		zn.set_script(load("res://scripts/zona.gd"))
		zn.set("rect", Rect2(0, oy * T, w * T, h * T))
		zn.set("tema", tema)
		nodo_zonas.add_child(zn)
		var fila_suelo: int = FILA_SUELO.get(tema, 0)
		var car := func(x: int, y: int) -> String:
			if y < 0 or y >= h or x < 0 or x >= filas[y].length():
				return "."
			return filas[y][x]
		var es_suelo := func(x: int, y: int) -> bool:
			if x < 0 or x >= w or y >= h:
				return true
			return car.call(x, y) == "#"
		var de_fachada := func(c: String) -> bool:
			return c in ["W", "w", "=", "&"]
		var socks := []
		var n_vecino := 0
		var saludos: Array = SALUDOS.get(tema, SALUDOS.ciudad)
		var orden := []      # entidades de izquierda a derecha, como en la web
		for y in h:
			var tronco_racha := 0
			for x in w:
				var ch: String = car.call(x, y)
				var celda := Vector2i(x, y + oy)
				if ch == "&":
					# puerta secreta: en la calle queda fachada detrás de la puerta
					orden.append([x, y, ch])
					if tema != "ciudad":
						continue
					ch = "W"
				if ch == "T":
					var lado := tronco_racha % 2
					tronco_racha += 1
					var arriba: bool = car.call(x, y - 1) != "T"
					suelo.set_cell(celda, 0, Vector2i(5 + lado if arriba else 7 + lado, 8))
					continue
				tronco_racha = 0
				var izq: String = car.call(x - 1, y)
				var der: String = car.call(x + 1, y)
				var enc: String = car.call(x, y - 1)
				var deb: String = car.call(x, y + 1)
				match ch:
					"#":
						var v := (x * 7 + y * 13) & 3
						var m := (4 if not es_suelo.call(x, y - 1) else 0) + (2 if not es_suelo.call(x - 1, y) else 0) + (1 if not es_suelo.call(x + 1, y) else 0)
						suelo.set_cell(celda, 0, Vector2i(m, v + fila_suelo))
					"o":
						huesos.set_cell(celda, 0, Vector2i(0, 10))
					"*":
						decorado.set_cell(celda, 0, Vector2i(9 + (x * 3 + y) % 3, 8))
					"%":
						decorado.set_cell(celda, 0, Vector2i(12, 8))
						decorado.set_cell(celda + Vector2i(1, 0), 0, Vector2i(13, 8))
					"=":
						if tema == "ciudad":
							suelo.set_cell(celda, 0, Vector2i(13 if (izq == "W" or der == "W") else 12, 40))
						else:
							suelo.set_cell(celda, 0, ATLAS.tablon)
					"W":
						# fachada: liso, ventana, puerta o zócalo según lo que tenga alrededor
						var tipo_pared := 0
						if not de_fachada.call(deb):
							tipo_pared = 2 if x % 6 == 3 else 3
						elif x % 3 == 1 and y % 3 == 1 and de_fachada.call(enc):
							tipo_pared = 1
						var vp := (x * 5 + y * 3) & 3
						var bordes := (2 if not de_fachada.call(izq) else 0) + (1 if not de_fachada.call(der) else 0)
						decorado.set_cell(celda, 0, Vector2i(vp * 4 + bordes, 36 + tipo_pared))
					"R":
						suelo.set_cell(celda, 0, Vector2i((2 if izq != "R" else 0) + (1 if der != "R" else 0), 40))
					"w":
						var le := izq != "w"
						var re := der != "w"
						var pared := tema == "ciudad" and (izq == "W" or der == "W")
						suelo.set_cell(celda, 0, Vector2i((8 if pared else 4) + (2 if le else 0) + (1 if re else 0), 40))
						# toldo de un puesto: sin pared detrás se apoya en dos postes
						if (le or re) and izq != "W" and der != "W" and deb != "W":
							var col := 0 if le else 2
							decorado.set_cell(celda, 0, Vector2i(col, 43))
							var k := y + 1
							while k < h and not SOLIDO.contains(car.call(x, k)):
								decorado.set_cell(Vector2i(x, k + oy), 0, Vector2i(col + 1, 43))
								k += 1
					"~":
						suelo.set_cell(celda, 0, Vector2i(4, 41) if enc in ["~", "x", "q"] else Vector2i(0, 41))
					"N":
						var vg := (x * 7 + y * 3) & 3
						var mg := (4 if enc != "N" else 0) + (2 if izq != "N" else 0) + (1 if der != "N" else 0)
						suelo.set_cell(celda, 0, Vector2i(mg, 32 + vg))
					"A":
						var a := x
						while car.call(a - 1, y) == "A":
							a -= 1
						var b := x
						while car.call(b + 1, y) == "A":
							b += 1
						var base: Array = datos.arcos[str(b - a + 1)]
						decorado.set_cell(celda, 0, Vector2i(int(base[0]) + x - a, int(base[1])))
					"|":
						suelo.set_cell(celda, 0, Vector2i(4 + (2 if enc != "|" else 0) + (1 if deb != "|" else 0), 42))
					"-":
						suelo.set_cell(celda, 0, Vector2i((2 if izq != "-" else 0) + (1 if der != "-" else 0), 42))
					"z":
						decorado.set_cell(celda, 0, Vector2i(14, 40))
					"I":
						decorado.set_cell(celda, 0, Vector2i(15, 40))
					":":
						decorado.set_cell(celda, 0, Vector2i(8, 42))
					"M":
						decorado.set_cell(celda, 0, Vector2i(5, 41))
					_:
						if LOSETAS.has(ch):
							suelo.set_cell(celda, 0, ATLAS[LOSETAS[ch]])
						elif DECORADO.has(ch):
							var d: Sprite2D = load("res://escenas/decorado/%s.tscn" % DECORADO[ch]).instantiate()
							d.position = Vector2(x * T, (y + oy) * T)
							if ch == "Y":
								d.frame = (x >> 1) & 1
							ents.add_child(d, true)
						elif ch == "F":
							socks.append([x, Vector2(x * T + 8, (y + oy) * T + 15)])
						elif ch != ".":
							if ch in ["x", "q"]:
								suelo.set_cell(celda, 0, Vector2i(4, 41) if enc in ["~", "x", "q"] else Vector2i(0, 41))
							if ch == "f":
								suelo.set_cell(celda, 0, ATLAS.usado)
							orden.append([x, y, ch])
		# entidades en orden de izquierda a derecha (así los vecinos saludan como en la web)
		orden.sort_custom(func(p, q): return p[0] < q[0] or (p[0] == q[0] and p[1] < q[1]))
		var ultimo_tronco: Node2D = null
		for o in orden:
			var x: int = o[0]
			var y: int = o[1]
			var ch: String = o[2]
			var pos := Vector2(x * T, (y + oy) * T)
			var pies := Vector2(x * T + 8, (y + oy + 1) * T)
			match ch:
				"@":
					var s := Marker2D.new()
					s.name = "Salida"
					s.position = pies
					ents.add_child(s)
				"e":
					_poner(ents, "pelotero", pies)
				"s":
					_poner(ents, "caracol", pies)
				"a":
					_poner(ents, "abejorro", Vector2(x * T + 8, (y + oy) * T + 14))
				"c":
					_poner(ents, "cardo", Vector2(x * T + 16, (y + oy + 1) * T))
				"X":
					_poner(ents, "caseta", pies)
				"G":
					_poner(ents, "meta", Vector2(x * T, (y + oy + 1) * T))
				"m", "n":
					var p := _poner(ents, "plataforma", pos)
					p.set("clase", "barca" if tema == "rio" else "madera")
					if ch == "m":
						p.set("eje", "x")
						p.set("recorrido", 112.0)
						p.set("periodo", 6.0)
					else:
						p.set("eje", "y")
						p.set("recorrido", 64.0)
						p.set("periodo", 5.0)
						p.set("desfase", (x * 53) % 300)
				"i":
					_poner(ents, "antorcha", pos)
				"f":
					var b := _poner(ents, "barra_fuego", pos + Vector2(8, 8))
					b.set("angulo", fmod(x * 0.9, 6.28))
					b.set("giro", 0.034 if x % 2 == 1 else -0.034)
				"K":
					_poner(ents, "rastrillo", pos)
				"b":
					_poner(ents, "murcielago", Vector2(x * T + 8, (y + oy) * T + 10))
				"Z":
					_poner(ents, "micifuz", pies)
				"D":
					_poner(ents, "puerta", pos)
				"p":
					_poner(ents, "paloma", pies)
				"h":
					var v := _poner(ents, "vecino", pies)
					v.set("variante", n_vecino % 4)
					v.set("mensaje", saludos[n_vecino % saludos.size()])
					n_vecino += 1
				"E":
					_poner(ents, "eduardo", pies)
				"&":
					var pu := _poner(ents, "pasadizo", Vector2(x * T + 16, (y + oy + 1) * T))
					pu.set("numero", 100)
					pu.set("puerta", true)
				"?":
					_poner(ents, "cuadro", Vector2(x * T + 16, (y + oy) * T))
				"Q":
					var q := _poner(ents, "cafe", Vector2(x * T, (y + oy + 1) * T))
					q.set("puerta_x", x * T + 72.0)
				"x":
					_poner(ents, "carpa", Vector2(x * T + 8, (y + oy) * T + 22))
				"q":
					# 'q' es un tronco de dos casillas; varias 'q' seguidas hacen uno más largo
					if ultimo_tronco != null and ultimo_tronco.position.y == pos.y - 4 and ultimo_tronco.position.x + ultimo_tronco.ancho >= pos.x:
						ultimo_tronco.ancho = maxf(ultimo_tronco.ancho, pos.x + T - ultimo_tronco.position.x)
						continue
					var tr := _poner(ents, "plataforma", pos + Vector2(0, -4))
					tr.set("clase", "tronco")
					tr.set("eje", "hundir")
					tr.set("ancho", 32.0)
					ultimo_tronco = tr
				"J":
					_poner(ents, "aspersor", pies)
				"O":
					var pe := _poner(ents, "caracol", pies)
					pe.set("pelota", true)
				"g":
					var gl := _poner(ents, "globo", Vector2(x * T + 8, (y + oy) * T + 8))
					gl.set("color", x % 4)
				"r":
					_poner(ents, "pato", Vector2(x * T + 8, (y + oy) * T + 15))
				"t":
					_poner(ents, "estalactita", Vector2(x * T + 8, (y + oy) * T + 14))
				"L":
					var lu := _poner(ents, "luciernaga", Vector2(x * T + 8, (y + oy) * T + 8))
					lu.set("fase", x % 7)
				"v":
					var ci := _poner(ents, "plataforma", pos)
					ci.set("clase", "ciguena")
					ci.set("eje", "x")
					ci.set("ancho", 28.0)
					ci.set("recorrido", 48.0)
					ci.set("periodo", 7.0)
					ci.set("desfase", (x * 37) % 420)
					ci.set("bambolea", true)
				"d":
					_poner(ents, "milano", Vector2(x * T + 8, (y + oy) * T + 13))
				"U":
					_poner(ents, "urraca", Vector2(x * T + 14, (y + oy) * T + 18))
				"$":
					var centro := Vector2(x * T + 8, (y + oy) * T + 8)
					var no := _poner(ents, "noria", centro)
					no.set("suelo_y", float((oy + 13) * T))
					for k in 6:
						var g := _poner(ents, "plataforma", centro)
						g.set("clase", "gondola")
						g.set("eje", "giro")
						g.set("ancho", 32.0)
						g.set("centro", centro)
						g.set("radio", 80.0)
						g.set("angulo0", k * PI / 3.0)
				_:
					if ch >= "1" and ch <= "9":
						var pz := _poner(ents, "pasadizo", Vector2(x * T + 16, (y + oy + 1) * T))
						pz.set("numero", int(ch))
		socks.sort_custom(func(a, b): return a[0] < b[0])
		for s in socks:
			var c := _poner(ents, "calcetin", s[1])
			c.set("indice", calcetines)
			calcetines += 1
		oy += h + 4
	_guardar(raiz, ruta_tscn)
	print("  ", ruta_tscn, " · ", cab.nombre, " · ", calcetines, " calcetines")


func _capa(raiz: Node, nombre: String) -> TileMapLayer:
	var c := TileMapLayer.new()
	c.name = nombre
	c.tile_set = tileset
	raiz.add_child(c)
	return c


func _poner(ents: Node, escena: String, pos: Vector2) -> Node2D:
	var n: Node2D = load("res://escenas/entidades/%s.tscn" % escena).instantiate()
	n.position = pos
	ents.add_child(n, true)
	return n
