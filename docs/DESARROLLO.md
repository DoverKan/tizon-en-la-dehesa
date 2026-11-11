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
  - Si marcas `puerta`, el pasadizo es una puerta de 2 casillas de ancho y 3 de alto: se dibuja sola, se entra agachándose delante y se pasa con un fundido. En los mapas de texto es `&`.
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

La partida se guarda sola al tocar la caseta y al pasar un nivel, en `user://partida.json`. Si se acaban las vidas, se puede seguir desde la partida guardada con **Continuar**, pero con 0 puntos y 5 vidas (así no se suman puntos sin fin para el ranking). Las partidas de la versión anterior (de tres niveles) se convierten solas: quien iba por la Alcazaba sigue por Badajoz y conserva sus calcetines. En la pantalla de inicio:

- **Código de partida** muestra un código de 21 caracteres y permite escribir uno. Es el mismo código que usa la versión web, así que sirve para pasar la partida de un dispositivo a otro, o entre la web y Godot, en los dos sentidos. Los códigos antiguos de 13 y 15 caracteres siguen valiendo.
- **Empezar de cero** borra la partida guardada (pide confirmación) y empieza en la Dehesa 1-1. La mejor puntuación no se borra.

El código guarda hasta 63 vidas y 1.048.575 puntos; por encima de eso se queda en el máximo.

## Ranking de jugadores

Al acabar la partida (fin de partida o tras vencer a la Urraca), si la puntuación entra entre las 20 mejores, el juego pide un nombre de hasta 8 letras con un teclado en pantalla, como en las recreativas. Se maneja con la cruceta y A, tocando las letras o escribiendo con el teclado. En el menú de inicio, **Ranking** enseña los 20 mejores jugadores, cada uno con su mejor puntuación (se guardan todas las partidas, y en el panel se ven todas). Si una partida no supera el récord de ese nombre, el juego avisa de que su mejor puntuación sigue en su puesto.

- Lo hace `scripts/ranking.gd`; las pantallas están en `principal.gd` (estados `nombre` y `ranking`) y en `pantalla.gd`.
- Habla con la misma API que la versión web: `https://www.doverkan.com/tizon_ranking/api.php`.
  - `GET` devuelve `{"ok":true,"puestos":20,"ranking":[{"pos":1,"nombre":"NACHO","puntos":98500,"nivel":10,"final":true,"calcetines":41}]}`.
  - `POST` con `{"nombre","puntos","nivel","final","calcetines","segundos","plataforma"}` guarda la puntuación y devuelve el ranking y el puesto. Al volver, se resalta solo esa partida; desde el menú se resaltan todas las del último nombre usado.
- Con la puntuación se envían el nivel más lejano, los calcetines y el tiempo jugado, que se guarda en la partida. El servidor rechaza lo que no se puede conseguir jugando: demasiados puntos para el tiempo jugado, más calcetines de los que hay en los niveles alcanzados...
- Las partidas cargadas con un código de partida no entran en el ranking: el código lleva los puntos dentro y cualquiera podría fabricarse uno.
- En Android hace falta el permiso de internet; ya está activado en el preajuste.
- El código del servidor (PHP y MySQL) no está en este repositorio porque su configuración lleva la contraseña de la base de datos.

## Estadísticas (Google Analytics)

La versión web publicada (`docs/index.html`) envía a Google Analytics (G-J0WR95LLC3) estos eventos. La versión de Godot no envía nada.

| Evento | Datos |
|---|---|
| `muerte` | `nivel`, `zona` (main, cueva...), `tramo` (bloque de 32 columnas del mapa, desde 1), `casilla` (columna) y `causa` (caída, agua, tiempo, pinchos, barra de fuego, rastrillo, pelotero, Micifuz...) |
| `nivel_empezado` | `nivel` y `desde_caseta`; cada vida perdida cuenta como un intento nuevo |
| `nivel_superado` | `nivel` y `tiempo_restante` |
| `fin_partida` | `nivel` y `puntos` |
| `final_juego` | `puntos` |
| `ranking_enviado` | `puesto` |
| `huevo_encontrado` | `huevo`: cuál se ha encontrado |

Para verlos con sus datos en los informes, en Analytics: **Administrar > Definiciones personalizadas > Crear dimensión personalizada**, con ámbito *Evento*, una por parámetro: `nivel`, `zona`, `tramo`, `casilla`, `causa` y `huevo`. Después, en **Explorar**, una tabla con filas `nivel` y `tramo` (o `casilla`) y el número de eventos `muerte` enseña dónde muere más la gente.

## Exportar a PC, Android, iOS y web

La versión que sale abajo a la derecha en la pantalla de inicio está en **Proyecto > Configuración del proyecto > Aplicación > Configuración > Versión** (en la web, en `VERSION_JUEGO`). Se sube en cada versión publicada (1.0, 1.1, 1.2...) y se apunta en **Versiones** del README. Al subirla, cámbiala también en:

- los preajustes de exportación: versión del archivo y del producto en Windows (`1.1.0.0`), `version/name` en Android y `short_version` en macOS e iOS;
- el número de compilación, que tiene que crecer siempre de uno en uno: `version/code` en Android y `version` en macOS e iOS (la 1.1 es la 2);
- la línea `Versión:` de la cabecera de cada archivo. En los mapas y en `docs/index.html` se pone sola, porque sale de `VERSION_JUEGO`.

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
