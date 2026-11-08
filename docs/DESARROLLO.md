# Guía de desarrollo

Cómo está hecho el proyecto, cómo editar y añadir niveles, cómo funciona la partida guardada y cómo exportar el juego a cada plataforma. Para jugar basta con abrir el proyecto en Godot (ver el [README](../README.md)).

## Carpetas

- `niveles/` contiene las escenas de nivel (`nivel_1_1.tscn` a `nivel_1_5.tscn` y `nivel_2_1.tscn` a `nivel_2_5.tscn`) y sus mapas de texto (`mapas/*.txt`).
- `escenas/` contiene a Tizón (`jugador.tscn`), la escena principal, `entidades/` (enemigos, objetos, plataformas, jefes...) y `decorado/` (farolas, naranjos, esculturas, cañas, bancos y mesas).
- `scripts/` tiene todo el código en GDScript, comentado en castellano.
  - `tizon.gd`: la física de Tizón. Las constantes de arriba (velocidades, salto, gravedad) son las que hay que tocar para cambiar el control.
  - `nivel.gd`: bloques, interruptor de colores, piedras que se desmoronan, agua, pasadizos, caseta, meta, oscuridad de la cueva, jefes e interacciones con los enemigos.
  - `entidades/micifuz.gd` y `entidades/urraca.gd`: los dos jefes. Arriba están sus velocidades y tiempos.
  - `juego.gd`: niveles, vidas, puntos, calcetines, partida guardada, código de partida y opciones.
  - `principal.gd` y `pantalla.gd`: menús, mapa del mundo, ayuda, bestiario, opciones y pausa.
  - `tactil.gd`: los botones táctiles.
- `assets/` guarda los gráficos en PNG (puedes editarlos con cualquier programa de pixel art), los sonidos en WAV y `datos.json` (posiciones del mapa del mundo, textos del bestiario, colores de los fondos y arcos del puente).
- `tiles/losetas.tres` es el TileSet, con colisiones y el dato `tipo` de cada loseta.
- `tools/construir.gd` es el constructor que genera el TileSet y las escenas a partir de los mapas de texto.

## Editar niveles

Hay dos formas. Usa una u otra para cada nivel, no las dos a la vez.

### En el editor de Godot

Abre una escena de `niveles/`:

- **Suelo**, **Huesos** y **Decorado** son capas de losetas. Selecciona la capa y pinta con el panel TileMap de abajo. En **Decorado** van las fachadas, setos, arcos, guirnaldas y setas, que no chocan.
- **Entidades**: para añadir enemigos, calcetines y demás, arrastra escenas de `escenas/entidades/` o `escenas/decorado/` dentro de este nodo.
  - El origen de cada entidad está en sus pies.
  - Los calcetines llevan un `indice` del 0 al 4.
  - Los vecinos llevan una `variante` (0 a 3) y su `mensaje`.
- **Pasadizos**: pon un nodo `Pasadizo` centrado sobre la boca de una encina hueca. Dos pasadizos con el mismo `numero` quedan conectados.
- **Zonas**: cada zona tiene un rectángulo que limita la cámara y un tema de fondo (`dehesa`, `atardecer`, `cueva`, `castillo`, `ciudad`, `rio`, `jardin`, `museo`, `feria`, `gruta`, `cielo` o `romano`). En el castillo la cámara se queda arriba, para que se vea el techo. En la `gruta` todo está a oscuras.
- **Sala del jefe**: los nodos `Puerta` marcan las casillas que se convierten en piedra cuando Tizón pasa dos casillas más allá de la primera puerta. El nivel se supera al vencer al jefe (no hace falta meta).
- En el nodo raíz del nivel, **Avance** hace que la zona principal avance sola (píxeles por fotograma; el nivel de las cigüeñas usa 0,6).

Filas del atlas de losetas (`assets/tiles/losetas.png`, 16 columnas):

| Filas | Contenido |
|---|---|
| 0-3 | suelo de la dehesa (también el Guadiana y los jardines) |
| 4-7 | suelo de la cueva |
| 8-10 | corcho, piedra, tablón, troncos, flores, matorral, colmenas y huesitos |
| 11-14 | suelo de la Alcazaba (también el cielo) |
| 15 | pinchos |
| 16-19, 20-23, 24-27, 28-31 | suelo de Badajoz, del museo, de la feria y de Mérida |
| 32-35 | granito del puente |
| 36-39 | fachadas de Badajoz |
| 40 | tejados, toldos, balcones, valla y seto |
| 41 | agua, seta, interruptor, bloques rojos y azules y piedra que se desmorona |
| 42 | nubes, columnas y guirnalda |
| 43-44 | postes de los toldos y arcos del puente |

En el suelo, la columna es la forma: hierba o borde arriba, borde izquierdo y borde derecho.

### Con los mapas de texto

Edita `niveles/mapas/nivel_1_1.txt` (o el que sea). Cada carácter es una casilla y la leyenda está al principio del archivo. Después regenera las escenas:

```
godot --headless --path . --script res://tools/construir.gd
```

Esto **sobrescribe** las escenas de nivel. Lo que hayas cambiado a mano en el editor en esas escenas se pierde.

### Añadir un nivel nuevo

1. Copia un mapa, por ejemplo `nivel_2_5.txt` como `nivel_3_1.txt`.
2. Ejecuta el constructor.
3. Añade el nivel a la lista `NIVELES` de `scripts/juego.gd`.
4. Cada mundo tiene cinco niveles y su propio mapa. Para un tercer mundo, añade su dibujo en `assets/mapas/`, su nombre y las cinco posiciones en `mundos` de `assets/datos.json`, y cárgalo en `_mapas` de `scripts/pantalla.gd`.

El código de partida tiene sitio para diez niveles: con más, los calcetines de los niveles nuevos no entran en el código (la partida guardada en el dispositivo sí los guarda).

## Partida guardada

La partida se guarda sola al tocar la caseta y al pasar un nivel, en `user://partida.json`. Las partidas de la versión anterior (de tres niveles) se convierten solas: quien iba por la Alcazaba sigue por Badajoz y conserva sus calcetines. En la pantalla de inicio:

- **Código de partida** muestra un código de 21 caracteres y permite escribir uno. Es el mismo código que usa la versión web, así que sirve para pasar la partida de un dispositivo a otro, o entre la web y Godot, en los dos sentidos. Los códigos antiguos de 13 y 15 caracteres siguen valiendo.
- **Empezar de cero** borra la partida guardada (pide confirmación) y empieza en la Dehesa 1-1. La mejor puntuación no se borra.

El código guarda hasta 63 vidas y 1.048.575 puntos; por encima de eso se queda en el máximo.

## Exportar a PC, Android, iOS y web

El proyecto trae ya preparados los preajustes de **Proyecto > Exportar** para Windows, Linux, macOS, Android, iOS y Web. Cada uno deja el juego en su carpeta de `exportar/`. El renderizador es **Compatibilidad**, que funciona en todas esas plataformas, y está activada la compresión de texturas ETC2/ASTC que piden Android e iOS.

1. **Plantillas de exportación** (una vez por versión de Godot): **Editor > Gestionar plantillas de exportación > Descargar e instalar**. Son algo más de 1 GB.
2. **Windows y Linux**: elige el preajuste y pulsa **Exportar proyecto**. Sale un solo ejecutable con el juego dentro.
   - En Windows el .exe lleva el icono de Godot. Para que lleve el de Tizón, instala [rcedit](https://github.com/electron/rcedit/releases), pon su ruta en **Editor > Configuración del editor > Exportar > Windows** y activa **Aplicación > Modificar recursos** en el preajuste.
3. **macOS**: se puede exportar desde cualquier sistema, pero sin firmar. La primera vez, en el Mac hay que abrirlo con clic derecho > Abrir. Para firmarlo y notarizarlo hace falta un Mac y una cuenta de desarrollador de Apple.
4. **Android**:
   - Instala el JDK 17 y el SDK de Android; lo más cómodo es instalar Android Studio, que trae los dos.
   - En **Editor > Configuración del editor > Exportar > Android**, pon la ruta del **Java SDK** y del **Android SDK**.
   - Con eso ya genera el APK para probar: Godot crea solo la clave de depuración.
   - Para subirlo a Google Play hace falta el formato AAB:
     - Crea tu propia clave (keystore) y ponla en el preajuste, en **Keystore > Release**.
     - Usa **Proyecto > Instalar plantilla de compilación de Android**.
     - En el preajuste, activa **Gradle Build > Usar compilación con Gradle** y elige el formato **AAB**.
   - El identificador es `com.skydronex.tizonenladehesa`. Cámbialo antes de publicar si quieres otro, porque después ya no se puede cambiar.
5. **iOS**: solo desde un Mac con Xcode. Rellena el **App Store Team ID** de tu cuenta de Apple en el preajuste de iOS.
6. **Web**: sube el contenido de `exportar/web/` a cualquier servidor web. Usa la variante sin hilos, así que no necesita cabeceras especiales del servidor. Abriendo `index.html` directamente desde el disco no funciona; tiene que servirlo un servidor web.

## Diferencias con la versión web

La lógica es la misma, reescrita en GDScript para Godot. Tizón choca con el mundo usando la física de Godot (`CharacterBody2D` y las colisiones del TileSet). Los enemigos, los objetos y las interacciones siguen las mismas reglas y números que en la web. La ayuda, el bestiario y las opciones, que en la web están en la página, aquí son pantallas del propio juego.
