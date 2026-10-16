# `mt next`: la primera historia Lista y no bloqueada, entera y con el porqué.
class Api::NextStoriesController < Api::BaseController
  def show
    next_story = Api::NextStory.new(project)
    story = next_story.story
    raise Api::Error.new("NOTHING_READY", "No hay ninguna historia Lista y sin bloquear en los hitos abiertos",
      status: :not_found, hint: next_story.nothing_ready_hint) unless story

    reason = next_story.reason
    render_ok({ story: Api::Markdown::Formatting.story_data(story), reason: reason,
                markdown: "> #{reason}\n\n#{Api::Markdown::Story.new(story)}" },
      summary: "Siguiente: #{story.reference} · #{story.title}",
      breadcrumbs: [ "mt start #{story.reference}", *next_story.related.map { "mt show #{it}" } ])
  end
end
