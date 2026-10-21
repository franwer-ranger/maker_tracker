# Tokens de la API para agentes y para Fran (historia #014). Sin pantalla: se
# crean en el servidor y se ven una sola vez.
#
#   bin/rails "mt:token[claude]"
#   docker compose exec -u rails app bin/rails "mt:token[claude]"
namespace :mt do
  desc "Crea (o renueva) el token de un actor y lo imprime una vez. Si el actor no existe, lo crea como agente"
  task :token, [ :name ] => :environment do |_task, args|
    abort 'Falta el nombre del actor: bin/rails "mt:token[claude]"' if args[:name].blank?

    actor = Actor.find_or_create_by!(name: args[:name].strip.downcase) { it.kind = :agent }
    renewed = actor.token_digest.present?
    token = actor.regenerate_token!
    url = ENV["MT_URL"].presence || "<url>"

    puts <<~TEXT
      Token de #{actor.name} (#{actor.kind})#{" · el anterior ya no vale" if renewed}:

        #{token}

      Se enseña solo esta vez. Para usarlo con mt:

        mt setup #{url} #{token}
    TEXT
    puts "\n<url> es la dirección de esta instancia, p. ej. https://torre.tu-tailnet.ts.net" if url == "<url>"
  end

  desc "Lista los actores con token y cuándo se usó cada uno por última vez"
  task tokens: :environment do
    actors = Actor.with_token
    next puts "Ningún actor tiene token. Crea uno con: bin/rails \"mt:token[claude]\"" if actors.empty?

    actors.each do |actor|
      used = actor.token_used_at ? actor.token_used_at.localtime.strftime("%Y-%m-%d %H:%M") : "nunca"
      puts format("%-16s %-6s último uso: %s", actor.name, actor.kind, used)
    end
  end

  # Avisos push (MT-47). Las claves van en el entorno, no en credentials: la
  # torre ya inyecta `.env` y un autoalojado no tiene que tocar `master.key`.
  desc "Genera un par de claves VAPID para los avisos push y la línea para pegar en .env"
  task :vapid, [ :subject ] => :environment do |_task, args|
    key = WebPush.generate_key
    subject = args[:subject].presence || "mailto:tu@correo"

    puts <<~TEXT
      Claves VAPID nuevas. Añádelas al .env de la instancia y reinicia la app
      (con Docker: docker compose up -d):

        VAPID_PUBLIC_KEY=#{key.public_key}
        VAPID_PRIVATE_KEY=#{key.private_key}
        VAPID_SUBJECT=#{subject}

      VAPID_SUBJECT es un contacto (mailto:… o https://…) que ven Apple, Google y Mozilla.
      Cambiar las claves invalida todas las suscripciones: hay que reactivar los
      avisos en cada dispositivo.
    TEXT
  end
end
