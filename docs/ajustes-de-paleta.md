# Notas

Este archivo explica los tres huevos de pascua del juego. Si no quieres destripártelos, ciérralo.

Los tres están en la versión web y en la de Godot, son iguales en las dos y solo cambian el aspecto: no dan vidas, puntos ni ventajas.

## 1. Modo piloto

**Cómo se activa:** en la pantalla de inicio o en el mapa, mete el código Konami:

↑ ↑ ↓ ↓ ← → ← → B A

| | Teclado | Mando | Táctil |
|---|---|---|---|
| ↑ ↓ ← → | Flechas (o W A S D) | Cruceta o stick | Cruceta del mapa |
| B | C | B | B |
| A | Z o Espacio | A | A |

En táctil se mete desde el mapa, que es donde salen los botones en pantalla.

**Qué pasa:** suena un ladrido y sale el aviso «¡MODO PILOTO!». Desde entonces Tizón lleva gafas de aviador doradas y una bufanda roja que ondea al correr, y le sigue una libélula.

**Cómo se quita:** con el mismo código. Se recuerda entre partidas: en la web se guarda en el navegador (`tizon.piloto`) y en Godot en las opciones (`opciones.piloto`).

## 2. La sala secreta

**Dónde:** Badajoz 1-3, en el tramo 4, en el edificio de los balcones. Entre las fachadas hay un portal de madera con una huella dorada pintada en la hoja de la derecha. Es la única pista.

**Cómo se entra:** ponte delante del portal y agáchate (↓). La pantalla se funde a negro y Tizón aparece dentro.

**Qué hay:** una galería con el retrato de Tizón dormido en su cojín rojo, con una placa que pone «TIZÓN» y debajo «HECHO CON CARIÑO POR NACHO». Hay también una fila de huesos para coger.

**Cómo se sale:** por la misma puerta, agachándose otra vez. Se vuelve al portal de la calle.

En el mapa del nivel (`niveles/mapas/nivel_1_3.txt`) el portal es el `&` de la columna 113 de la zona principal, y la sala es la zona `[zona secreta museo]`, con el retrato en el `?`.

## 3. El cumpleaños de Tizón

**Cuándo:** cada 27 de abril. Tizón nació el 27 de abril de 2023.

**Qué pasa:** ese día Tizón lleva un gorro de fiesta de rayas en todo el juego. La pantalla de inicio le felicita con los años que cumple («¡FELIZ CUMPLEAÑOS, TIZÓN! HOY CUMPLE N AÑOS») y cae confeti.

**Para probarlo otro día:** cambia la fecha del ordenador o del móvil al 27 de abril. En Godot, también se puede poner `Adornos.forzar_cumple = true` en una prueba.

## Estadísticas

En la versión web, cada huevo encontrado envía a Google Analytics el evento `huevo_encontrado` con el dato `huevo`: `modo piloto`, `sala secreta` o `cumpleaños`. El del cumpleaños se envía una sola vez cada vez que se abre el juego, al ver la felicitación.

## Dónde está el código

| Qué | Godot | Web |
|---|---|---|
| Gafas, bufanda, gorro, libélula y portal | `scripts/adornos.gd` | `huevos.js` |
| Retrato con su placa | `scripts/entidades/cuadro.gd` y `assets/decorado/cuadro_tizon.png` | `huevos.js` |
| Código Konami y aviso | `scripts/principal.gd` y `scripts/pantalla.gd` | `huevos.js` y `game.js` |
| Entrar y salir por el portal | `scripts/nivel.gd` y `scripts/entidades/pasadizo.gd` | `game.js` |

El código de la web no está en este repositorio; va todo dentro de `docs/index.html`.

## Ojo

El repositorio es público y GitHub Pages publica todo lo que hay en `docs/`, así que este archivo se puede leer en `https://doverkan.github.io/tizon-en-la-dehesa/ajustes-de-paleta.md`. El nombre solo sirve para que no se encuentre sin buscarlo. Lo mismo vale para los mapas y el código, que también son públicos.
