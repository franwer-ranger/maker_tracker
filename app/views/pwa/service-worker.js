// Service worker de Maker Tracker (MT-47): solo avisos push. No cachea nada:
// la app no necesita funcionar sin conexión.

self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()))

// En iOS y en Safari cada push tiene que enseñar un aviso (no hay pushes
// silenciosos: si no se enseña, Apple acaba retirando el permiso). En el resto,
// si la app ya está a la vista, no se enseña: la pantalla se actualiza sola.
const mustShow = (() => {
  const ua = self.navigator.userAgent
  return /iPhone|iPad|iPod/.test(ua) || (/Safari/.test(ua) && !/Chrome|Chromium|Edg|Firefox/.test(ua))
})()

async function appVisible() {
  const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
  return windows.some((client) => client.visibilityState === "visible")
}

self.addEventListener("push", (event) => {
  const { title, options } = event.data.json()
  event.waitUntil((async () => {
    if (!mustShow && await appVisible()) return
    await self.registration.showNotification(title, options)
  })())
})

// Al pulsar: si ya hay una ventana de la app, la enfoca y la lleva a la ruta
// del aviso; si no, abre una nueva.
self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data?.path || "/", self.location.origin).href

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
    const client = windows.find((window) => new URL(window.url).origin === self.location.origin)
    if (client) {
      await client.focus()
      if (client.url === url) return
      try {
        if (await client.navigate(url)) return
      } catch {
        // Una ventana que este service worker no controla no se puede llevar a otra URL: se abre otra.
      }
    }
    return self.clients.openWindow(url)
  })())
})
