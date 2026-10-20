# Presence guarda estado en memoria y arranca un barrido y un hilo: en
# desarrollo, cada recarga de código dejaría vivos los anteriores.
ActiveSupport::Reloader.before_class_unload { Presence.shutdown! if defined?(Presence) }
