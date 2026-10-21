# Avisos push (MT-47, D-66): Maker Tracker avisa en el móvil y en el escritorio
# cuando a Fran le toca algo que bloquea a un agente o ya espera a Fran: una
# pregunta bloqueante, algo por probar y un proyecto que entra en poco trabajo.
# Nunca de lo que hace Fran.
#
# Las claves VAPID van en variables de entorno (`VAPID_PUBLIC_KEY`,
# `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`; se generan con `bin/rails mt:vapid`).
# Sin ellas no se avisa y la línea de activar no se enseña.
#
# Las piezas: `Push::Notifier` decide qué avisa (desde `Event`),
# `Push::DeliverJob` envía a cada dispositivo y `Push::FlushJob` manda el
# resumen al cerrar la ventana. Las suscripciones son `PushSubscription`.
module Push
  # Como mucho un aviso por proyecto en este tiempo; lo demás, un resumen al final.
  WINDOW = 10.minutes

  # Qué dice un aviso y qué abre al pulsarlo (una ruta de la app). `kind` e
  # `ids` dicen de qué es (:question con su id, :testable con los ids de las
  # historias, :low_work), para que el resumen solo cuente lo aplazado.
  Notice = Data.define(:title, :body, :path, :kind, :ids) do
    def initialize(title:, body:, path:, kind: nil, ids: []) = super
  end

  def self.configured? = public_key.present? && ENV["VAPID_PRIVATE_KEY"].present? && ENV["VAPID_SUBJECT"].present?

  def self.public_key = ENV["VAPID_PUBLIC_KEY"]

  def self.vapid
    { subject: ENV["VAPID_SUBJECT"], public_key: public_key, private_key: ENV["VAPID_PRIVATE_KEY"] }
  end

  # Lo que recibe el service worker. Todos los avisos de un proyecto comparten
  # `tag`: uno nuevo sustituye al anterior en vez de apilarse (y,
  # con `renotify`, vuelve a sonar).
  def self.payload(project, notice)
    { title: notice.title,
      options: { body: notice.body, tag: "mt-#{project.key.downcase}", renotify: true, data: { path: notice.path },
                 icon: "/icon-192.png", badge: "/badge-96.png" } }
  end

  # Envía el aviso a todos los dispositivos, cada uno en su job, fuera de la petición.
  def self.deliver(project, notice)
    payload = payload(project, notice)
    PushSubscription.find_each { Push::DeliverJob.perform_later(it, payload) }
  end

  # Abre la ventana del proyecto si ya pasó la anterior: true si este aviso
  # puede salir ya. Atómico, para que dos eventos a la vez no avisen los dos.
  def self.claim_window(project, now: Time.current)
    claimed = Project.where(id: project.id).where("last_pushed_at IS NULL OR last_pushed_at <= ?", now - WINDOW)
      .update_all(last_pushed_at: now) == 1
    project.last_pushed_at = now if claimed
    claimed
  end
end
