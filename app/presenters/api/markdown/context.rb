# El onboarding de un agente (`mt context`): brief, últimas decisiones
# vigentes, hito actual y lo que está en curso.
class Api::Markdown::Context
  include Api::Markdown::Formatting

  DECISIONS = 5

  def initialize(project)
    @project = project
  end

  def decisions
    @decisions ||= @project.decisions.reorder(number: :desc).where.missing(:superseded_by).limit(DECISIONS).to_a
  end

  def in_progress
    @in_progress ||= @project.stories.in_progress.includes(:claimed_by, :milestone).order(:claimed_at).to_a
  end

  def to_s
    milestone = @project.current_milestone
    <<~MARKDOWN
      # #{@project.name} (#{@project.key})

      #{@project.brief.strip.presence || '_Sin brief todavía._'}

      ## Decisiones recientes

      #{decisions.map { decision_line(it) }.join("\n").presence || '_Ninguna._'}

      ## Hito actual: #{milestone ? milestone_label(milestone) : 'ninguno abierto'}

      #{milestone&.goal.to_s.strip.presence || '_Sin objetivo._'}

      ## En curso

      #{in_progress.map { "- #{it.reference} · #{it.title} · #{it.claimed_by&.name || 'sin dueño'}" }.join("\n").presence || '_Nada._'}
    MARKDOWN
  end

  private

  def decision_line(decision)
    body = decision.body.strip.gsub(/\s*\n\s*/, " ")
    "- **#{decision.reference} · #{decision.title}** (#{date(decision.created_at)})#{" — #{body}" if body.present?}"
  end
end
