# El despliegue de una historia Hecha (MT-46): `mt deployed` la da por
# desplegada en un sha (`deployed_at` y el evento `story.deployed`). Pasar a
# Hecha o salir de ella lo pone a nulo (Story::Operations).
module Story::Deploy
  # `mt deployed` la da por desplegada en `sha`. `false` si ya lo estaba o no está Hecha.
  def deployed!(sha:, actor:)
    with_lock do
      next false unless done? && deployed_at.nil?

      update!(deployed_at: Time.current)
      record_event!("story.deployed", actor: actor, story: self, data: { sha: sha })
    end
  end
end
