# QA pendiente (MT-32). Una historia que pasa a Hecha queda con `qa: pending`
# hasta que Fran la prueba allí donde ya está (la línea «Dónde se prueba» del
# brief). Es derivado de Hecha, no un estado: no bloquea nada ni cambia `mt next`.
# Las que ya estaban hechas antes de esta funcionalidad tienen `qa` nulo.
#
# «Probada» la cierra (`qa.passed`); «Falla» pide una nota, crea una historia en
# Definiendo en el mismo hito y deja el enlace en el evento (`qa.failed`). La
# historia original no se reabre. Solo una persona prueba, como con las preguntas.
#
# La espera al despliegue (MT-46, D-62): en un proyecto que ya ha llamado a
# `mt deployed` (Project#deploys?), la QA pendiente solo se puede probar cuando
# la historia tiene `deployed_at`. Un proyecto que nunca despliega con mt sigue
# como antes: Hecha es probable al momento.
module Story::Qa
  extend ActiveSupport::Concern

  QA_STATES = %w[pending passed failed].freeze

  # La historia no espera QA (no está Hecha, o se hizo antes de esta funcionalidad).
  class NotPending < StandardError
    attr_reader :story

    def initialize(story)
      @story = story
      super("#{story.reference} no tiene QA pendiente")
    end
  end

  # «Falla» sin nota.
  class NoteRequired < StandardError; end

  # Un agente intenta probar: es una tarea de la persona.
  class HumanOnly < StandardError; end

  included do
    scope :qa_pending, -> { where(qa: "pending") }
    # Lo que ya se puede probar: sin espera activa en su proyecto o ya desplegada.
    scope :qa_testable, -> { qa_pending.where("stories.deployed_at IS NOT NULL OR NOT #{PROJECT_DEPLOYS_SQL}") }
    # Hecha, con QA pendiente, en un proyecto con espera activa y aún sin desplegar.
    scope :qa_undeployed, -> { qa_pending.where(deployed_at: nil).where(PROJECT_DEPLOYS_SQL) }
  end

  # Project#deploys? como subconsulta: existe un evento `project.deployed`.
  PROJECT_DEPLOYS_SQL = "EXISTS (SELECT 1 FROM events WHERE events.project_id = stories.project_id AND events.action = 'project.deployed')".freeze

  def qa_pending? = qa == "pending"
  def qa_passed? = qa == "passed"
  def qa_failed? = qa == "failed"

  # Hecha, con la QA sin pasar, en un proyecto que despliega con mt y todavía sin desplegar.
  def qa_awaiting_deploy? = qa_pending? && deployed_at.nil? && project.deploys?

  # `mt deployed` la da por desplegada en `sha`. `false` si ya lo estaba o no espera QA.
  def deployed!(sha:, actor:)
    with_lock do
      next false unless qa_pending? && deployed_at.nil?

      update!(deployed_at: Time.current)
      record_event!("story.deployed", actor: actor, story: self, data: { sha: sha })
    end
  end

  # Los criterios de aceptación del cuerpo, sin la viñeta ni la casilla.
  def criteria_list
    section = body.to_s[/^## Criterios de aceptación\s*$(.*?)(?=^## |\z)/m, 1].to_s
    section.lines.filter_map { it.strip[/\A(?:[-*]|\d+[.)])\s+(?:\[[ xX]\]\s+)?(.+)\z/, 1] }
  end

  # La da por probada. `false` si ya lo estaba.
  def qa_pass!(actor:, note: nil)
    ensure_human_qa!(actor)
    with_lock do
      next false if qa_passed?
      raise NotPending, self unless qa_pending?

      update!(qa: "passed")
      record_event!("qa.passed", actor: actor, story: self, data: { note: note.to_s.strip.presence }.compact)
    end
  end

  # Falla: pide una nota y crea la historia de la corrección en Definiendo, en el
  # mismo hito, enlazada en el evento. Devuelve la historia nueva.
  def qa_fail!(note:, actor:)
    ensure_human_qa!(actor)
    note = note.to_s.strip
    raise NoteRequired, "Cuenta qué falla: la nota es obligatoria" if note.empty?

    with_lock do
      raise NotPending, self unless qa_pending?

      # La referencia va como enlace de markdown a la historia original (el cuerpo se pinta como markdown).
      context = "Falla la QA de [#{reference}](/p/#{project.slug}/stories/#{number}) · #{title}.\n\n#{note}\n"
      fix = project.create_story!({ title: "#{reference} falla en QA: #{note.lines.first.strip.truncate(70)}", milestone: milestone, state: :defining,
                                    body: Story::BODY_TEMPLATE.sub("## Contexto\n") { "## Contexto\n\n#{context}" } },
        actor: actor, data: { qa_failed_from: number })
      update!(qa: "failed")
      record_event!("qa.failed", actor: actor, story: self, data: { note: note, story: fix.number })
      fix
    end
  end

  private

  def ensure_human_qa!(actor)
    raise HumanOnly, "Solo una persona prueba la QA" if actor.agent?
  end
end
