import { Controller } from "@hotwired/stimulus"

// Avisos push en este dispositivo (MT-47). Registra el service worker, enseña
// el estado de la línea (por activar, activado, bloqueado, sin HTTPS, sin
// soporte o, en iPhone sin la PWA instalada, instalar) y activa o desactiva la suscripción.
// El permiso se pide solo al pulsar «Activar», nunca al cargar la página.
export default class extends Controller {
  static targets = ["state"]
  static values = { key: String }

  connect() {
    this.refresh = this.refresh.bind(this)
    window.addEventListener("push:changed", this.refresh)
    this.refresh()
  }

  disconnect() {
    window.removeEventListener("push:changed", this.refresh)
  }

  async refresh() {
    if (!window.isSecureContext) return this.show("insecure")
    if (!this.supported) return this.show(this.ios && !this.standalone ? "install" : "unsupported")
    if (Notification.permission === "denied") return this.show("blocked")

    const registration = await this.register()
    let subscription = await registration.pushManager.getSubscription()
    if (subscription && !this.sameKey(subscription)) {
      // Las claves VAPID cambiaron: la suscripción vieja ya no vale.
      await this.request("DELETE", { endpoint: subscription.endpoint })
      await subscription.unsubscribe()
      subscription = null
    }
    if (subscription && Notification.permission === "granted") {
      this.show("on")
      // Por si el servidor la perdió. Solo la línea visible (la barra lateral o la
      // de la portada en el móvil), para no mandarla dos veces en cada carga.
      if (this.element.offsetParent) this.save(subscription)
    } else {
      this.show("idle")
    }
  }

  async subscribe(event) {
    event.currentTarget.disabled = true
    try {
      const permission = await Notification.requestPermission()
      if (permission === "granted") {
        const registration = await this.register()
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.applicationServerKey
        })
        await this.save(subscription)
      }
    } catch (error) {
      console.error("No se pudieron activar los avisos", error)
    }
    this.changed()
  }

  async unsubscribe(event) {
    event.currentTarget.disabled = true
    try {
      const registration = await this.register()
      const subscription = await registration.pushManager.getSubscription()
      if (subscription) {
        await this.request("DELETE", { endpoint: subscription.endpoint })
        await subscription.unsubscribe()
      }
    } catch (error) {
      console.error("No se pudieron desactivar los avisos", error)
    }
    this.changed()
  }

  // private

  show(state) {
    this.stateTargets.forEach((target) => {
      target.hidden = target.dataset.state !== state
      target.querySelectorAll("button").forEach((button) => (button.disabled = false))
    })
    this.element.hidden = false
  }

  changed() {
    window.dispatchEvent(new CustomEvent("push:changed"))
  }

  register() {
    navigator.serviceWorker.register("/service-worker", { scope: "/" })
    return navigator.serviceWorker.ready
  }

  save(subscription) {
    return this.request("POST", subscription.toJSON())
  }

  request(method, body) {
    return fetch("/push_subscriptions", {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
      },
      body: JSON.stringify(body)
    })
  }

  sameKey(subscription) {
    const current = subscription.options?.applicationServerKey
    if (!current) return true
    const a = new Uint8Array(current)
    const b = this.applicationServerKey
    return a.length === b.length && a.every((byte, i) => byte === b[i])
  }

  // La clave pública VAPID en base64url, como bytes.
  get applicationServerKey() {
    const base64 = this.keyValue.replace(/-/g, "+").replace(/_/g, "/").replace(/=+$/, "")
    const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4)
    return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0))
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  get ios() {
    return /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  get standalone() {
    return navigator.standalone === true || window.matchMedia("(display-mode: standalone)").matches
  }
}
