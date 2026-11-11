// ============================================================================
//  Tizón en la Dehesa
//  Juego de plataformas al estilo de Super Mario World, hecho con Godot 4.
//
//  Archivo:  scripts/oscuridad.gdshader
//  Qué es:   Oscuridad de las cuevas, con círculos de luz a escalones
//  Autor:    Nacho Cano (DoverKan)
//  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
//  Versión:  1.2 (noviembre de 2026)
//  © 2026 Nacho Cano
// ============================================================================

shader_type canvas_item;
// Oscuridad de las cuevas: todo negro salvo unos círculos de luz que van a
// escalones (tres anillos), como en los juegos de 16 bits.
// Cada luz es (x, y, radio) en píxeles de pantalla.

uniform vec3 luces[32];
uniform int cuantas = 0;
uniform vec2 tam = vec2(384.0, 224.0);

void fragment() {
	vec2 p = floor(UV * tam) + vec2(0.5);
	float queda = 0.82;   // se intuyen las formas aunque esté oscuro
	for (int i = 0; i < 32; i++) {
		if (i >= cuantas) {
			break;
		}
		vec3 l = luces[i];
		float d = distance(p, l.xy);
		if (d < round(l.z * 0.56)) {
			queda = 0.0;
		} else if (d < round(l.z * 0.78)) {
			queda *= 0.26;
		} else if (d < round(l.z)) {
			queda *= 0.65;
		}
	}
	COLOR = vec4(4.0 / 255.0, 2.0 / 255.0, 10.0 / 255.0, queda);
}
