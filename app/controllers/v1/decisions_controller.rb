# Las decisiones del producto (MT-105, «v1 · 7 · Decisiones»): lo que ya está
# decidido y por qué, agrupado por la capacidad que rige (MT-90), con buscador
# y combo de capacidad; las sustituidas, plegadas. Al elegir una, su detalle en
# la columna lateral (en móvil, su propia página): el porqué, qué capacidades e
# historias la aplican, las relacionadas y qué sustituye o quién la sustituye.
# Sin señales de enfoque: llegan con MT-94. En directo como la capacidad.
module V1
  class DecisionsController < ApplicationController
    RELATED = 3

    def index
      render inertia: "Decisions", props: { decisions: InertiaRails.live(@project) { list_props }, selected: nil }
    end

    def show
      number = params[:number]
      @project.decisions.find_by!(number: number)
      render inertia: "Decisions", props: {
        decisions: InertiaRails.live(@project) { list_props },
        selected: InertiaRails.live(@project) { detail_props(@project.decisions.find_by!(number: number)) }
      }
    end

    # «Nueva decisión»: el porqué, las capacidades que rige y, si cambia otra, cuál. Una
    # pantalla vieja no sustituye dos veces la misma: se mira bajo el bloqueo del proyecto.
    # Lo que no vale vuelve al diálogo como `errors` de Inertia (`base`), sin perder lo escrito.
    def create
      attributes = params.slice(:title, :why, :supersedes, :capabilities).permit(:title, :why, :supersedes, capabilities: [])
      slugs = Array(attributes[:capabilities]).compact_blank.uniq
      pages = @project.pages.documentation.where(slug: slugs).to_a
      problem = nil
      decision = @project.with_lock do
        supersedes = @project.decisions.find_by(number: attributes[:supersedes]) if attributes[:supersedes].present?
        problem = if pages.size != slugs.size
          "No existe la capacidad #{(slugs - pages.map(&:slug)).join(', ')}."
        elsif attributes[:supersedes].present? && supersedes.nil?
          "D-#{attributes[:supersedes]} no existe."
        elsif supersedes&.superseded_by
          "#{supersedes.reference} ya está sustituida por #{supersedes.superseded_by.reference}."
        end
        next if problem

        @project.record_decision!({ title: attributes[:title].to_s.strip, body: attributes[:why].to_s.strip, supersedes: supersedes },
                                  actor: Current.actor, capabilities: pages)
      end
      return back(problem) unless decision

      redirect_to project_v1_decision_path(@project, decision.number), notice: "#{decision.reference} apuntada."
    rescue ActiveRecord::RecordInvalid => e
      back(e.record.errors.full_messages.join(". "))
    end

    private

    def back(problem) = redirect_back_or_to(project_v1_decisions_path(@project), inertia: { errors: { base: [ problem ] } })

    def list_props
      decisions = @project.decisions.includes(:actor, :superseded_by, :capabilities).order(number: :desc).to_a
      {
        items: decisions.map { item_props(it) },
        capabilities: @project.pages.documentation.ordered.map { { slug: it.slug, title: it.title, icon: it.icon } },
        in_force: decisions.count { it.superseded_by.nil? },
        superseded: decisions.count(&:superseded_by),
        create_url: project_v1_decisions_path(@project),
        copy: "mt decisions --project #{@project.key}"
      }
    end

    def item_props(decision)
      { number: decision.number, reference: decision.reference, title: decision.title, why: decision.body.presence,
        actor: decision.actor.name, agent: decision.actor.agent?, at: decision.created_at.iso8601,
        capabilities: decision.capabilities.map(&:slug), superseded_by: decision.superseded_by&.reference,
        url: project_v1_decision_path(@project, decision.number) }
    end

    def detail_props(decision)
      {
        number: decision.number,
        reference: decision.reference,
        title: decision.title,
        why: why_blocks(decision.body),
        actor: decision.actor.name,
        agent: decision.actor.agent?,
        at: decision.created_at.iso8601,
        capabilities: decision.capabilities.ordered.map { { title: it.title, icon: it.icon, url: project_v1_capability_path(@project, it.slug) } },
        stories: stories(decision).map { { ref: it.reference, title: it.title, url: project_v1_story_path(@project, it.number) } },
        related: related(decision).map { link(it) },
        supersedes: decision.supersedes && link(decision.supersedes),
        superseded_by: decision.superseded_by && link(decision.superseded_by),
        copy: copy(decision)
      }
    end

    def link(decision) = { reference: decision.reference, title: decision.title, url: project_v1_decision_path(@project, decision.number) }

    # El porqué tal cual, en bloques (sus `##` como subtítulos, también los que no tienen nada debajo): nunca se pierde texto.
    def why_blocks(body)
      Page::Reading.new(body, plain: true).sections.flat_map { [ (it[:title] && { type: "heading", text: it[:title] }), *it[:blocks] ].compact }
    end

    # La aplican las historias con las que se registró y las que la citan (`D-52`), como `Story#related_decisions`.
    def stories(decision)
      cited = /(?<![\w-])#{decision.reference}\b/
      citing = @project.stories.where("body LIKE ?", "%#{decision.reference}%").select { it.body.to_s.match?(cited) }
      ([ decision.story ].compact + citing).uniq.sort_by(&:number)
    end

    # Las vigentes que rigen alguna de sus capacidades o que cita su porqué; sin la que sustituye ni la que la sustituye.
    def related(decision)
      others = @project.decisions.in_force.where.not(id: [ decision.id, decision.supersedes_id, decision.superseded_by&.id ].compact)
      cited = decision.body.to_s.scan(/(?<![\w-])D-(\d+)\b/).flatten.map(&:to_i)
      sharing = others.where(id: DecisionCapability.where(page_id: decision.capability_ids).select(:decision_id)).order(number: :desc)
      (others.where(number: cited).order(:number).to_a + sharing.to_a).uniq.first(RELATED)
    end

    def copy(decision)
      lines = [ "#{decision.reference} en #{@project.name}: #{decision.title}" ]
      lines << "Por qué: #{decision.body.strip}" if decision.body.present?
      lines << "Sustituida por #{decision.superseded_by.reference}: #{decision.superseded_by.title}" if decision.superseded_by
      lines << "Rige: #{decision.capabilities.map(&:slug).join(', ')}" if decision.capabilities.any?
      lines << "Todas las decisiones: `mt decisions --project #{@project.key}`."
      lines.join("\n")
    end
  end
end
