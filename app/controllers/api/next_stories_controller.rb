# `mt next`: la primera historia Lista y no bloqueada, entera y con el porqué.
class Api::NextStoriesController < Api::BaseController
  def show
    next_story = Api::NextStory.new(project)
    story = next_story.story
    raise next_story.nothing_ready_error unless story

    render_ok({ story: Api::Markdown::Formatting.story_data(story), reason: next_story.reason, markdown: next_story.markdown },
      summary: "Next up: #{story.reference} · #{story.title}",
      breadcrumbs: [ "mt start #{story.reference}", *next_story.related.map { "mt show #{it}" } ])
  end
end
