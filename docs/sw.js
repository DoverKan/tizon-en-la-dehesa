/* ============================================================================
 *  Tizón en la Dehesa
 *  Juego de plataformas al estilo de Super Mario World (versión web).
 *
 *  Archivo:  docs/sw.js
 *  Qué es:   Service worker: permite instalar el juego como aplicación y
 *            jugar sin conexión
 *  Autor:    Nacho Cano (DoverKan)
 *  Código:   https://github.com/DoverKan/tizon-en-la-dehesa
 *  Versión:  1.2 (noviembre de 2026)
 *  © 2026 Nacho Cano
 * ============================================================================
 *
 * Cómo funciona:
 *  - La página (index.html) se pide siempre a internet primero, así una versión
 *    nueva del juego llega sola sin tocar este archivo. Si no hay conexión, o
 *    tarda más de 4 segundos, se usa la copia guardada.
 *  - Los iconos y el manifiesto se sirven desde la copia guardada.
 *  - Las fuentes de Google se guardan la primera vez para tenerlas sin conexión.
 *  - Todo lo demás (capturas, guía...) pasa sin tocar. Solo se guardan
 *    peticiones GET con respuesta correcta.
 *
 * Solo hay que cambiar VERSION si se añaden o cambian los iconos o el manifiesto.
 */
'use strict';

const VERSION = 'tizon-v1';
const FUENTES = 'tizon-fuentes';
const BASICOS = ['./', 'manifest.webmanifest', 'icono-192.png', 'icono-512.png', 'icono-maskable-512.png', 'apple-touch-icon.png'];
const HOSTS_FUENTES = ['fonts.googleapis.com', 'fonts.gstatic.com'];
const ESPERA_RED = 4000;

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(BASICOS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(claves => Promise.all(claves.filter(k => k.startsWith('tizon-') && k !== VERSION && k !== FUENTES).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Internet primero, con un tiempo máximo; si falla, la copia guardada
async function redPrimero(peticion, clave) {
  const cache = await caches.open(VERSION);
  try {
    const respuesta = await new Promise((ok, mal) => {
      const t = setTimeout(() => mal(new Error('tiempo')), ESPERA_RED);
      fetch(peticion).then(r => { clearTimeout(t); ok(r); }, err => { clearTimeout(t); mal(err); });
    });
    if (respuesta.ok) cache.put(clave, respuesta.clone());
    return respuesta;
  } catch (e) {
    const guardada = await cache.match(clave);
    if (guardada) return guardada;
    throw e;
  }
}

// Copia guardada primero; si no está, internet (y se guarda)
async function copiaPrimero(peticion, nombreCache) {
  const cache = await caches.open(nombreCache);
  const guardada = await cache.match(peticion);
  if (guardada) return guardada;
  const respuesta = await fetch(peticion);
  if (respuesta.ok || respuesta.type === 'opaque') cache.put(peticion, respuesta.clone());
  return respuesta;
}

const BASE = new URL('./', self.location).pathname;            // /tizon-en-la-dehesa/
const RUTAS_BASICOS = BASICOS.filter(f => f !== './').map(f => BASE + f);

self.addEventListener('fetch', e => {
  const p = e.request;
  if (p.method !== 'GET') return;
  const url = new URL(p.url);

  if (url.origin === self.location.origin) {
    if (p.mode === 'navigate' && (url.pathname === BASE || url.pathname === BASE + 'index.html')) e.respondWith(redPrimero(p, './'));
    else if (RUTAS_BASICOS.includes(url.pathname)) e.respondWith(copiaPrimero(p, VERSION));
    return;                                                    // lo demás (capturas, guía...) pasa sin tocar
  }
  if (HOSTS_FUENTES.includes(url.hostname)) e.respondWith(copiaPrimero(p, FUENTES));
});
