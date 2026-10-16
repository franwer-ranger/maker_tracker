# `mt context`: lo que un agente lee al empezar una sesión.
class Api::ContextsController < Api::BaseController
  def show
    context = Api::Markdown::Context.new(project)
    milestone = project.current_milestone
    render_ok({ project: { key: project.key, name: project.name },
                current_milestone: milestone && { code: milestone.code, title: milestone.title },
                decisions: context.decisions.map(&:reference),
                in_progress: context.in_progress.map { { reference: it.reference, title: it.title, claimed_by: it.claimed_by&.name } },
                markdown: context.to_s },
      summary: "Context of #{project.name}.",
      breadcrumbs: [ "mt next", "mt roadmap" ])
  end
end
