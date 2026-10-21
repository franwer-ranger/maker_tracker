# La línea de los avisos push (MT-47, «Fila · Avisos» en Paper): al pie de la
# barra lateral y, en el móvil, al pie de la portada. No es naranja: los avisos
# no son «Te toca». Sin claves VAPID no se enseña.
module PushHelper
  # Los estados de la línea. `hint` es la segunda línea; en la barra lateral,
  # «por activar» y «activado» no la llevan.
  PUSH_STATES = {
    idle: { icon: "bell", text: "Avisarme en este dispositivo", hint: "Preguntas, por probar y poco trabajo" },
    on: { icon: "bell", text: "Avisos activados en este dispositivo", hint: "Preguntas, por probar y poco trabajo" },
    blocked: { icon: "bell-slash", text: "Bloqueados en este navegador", hint: "Se cambian en los ajustes del sitio" },
    unsupported: { icon: "bell", text: "Este navegador no puede recibir avisos", hint: "Usa Chrome, Edge, Firefox o Safari" },
    insecure: { icon: "bell-slash", text: "Los avisos necesitan HTTPS", hint: "Abre Maker Tracker por su dirección https://" },
    install: { icon: "device-phone-mobile", text: "Instala Maker Tracker en la pantalla de inicio para recibir avisos", hint: "Compartir › Añadir a pantalla de inicio" }
  }.freeze

  # push_line :sidebar · push_line :page
  # Con `state:` pinta solo ese estado, sin JavaScript (para /design).
  def push_line(variant, state: nil)
    return unless state || Push.configured?

    render "push/line", variant: variant, state: state
  end
end
