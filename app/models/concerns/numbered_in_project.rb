# Número correlativo por proyecto que nunca se reutiliza (PG-48, D-14). Usa un
# contador en el proyecto (`last_<modelo>_number`) reservado con un bloqueo.
module NumberedInProject
  extend ActiveSupport::Concern

  included do
    validates :number, uniqueness: { scope: :project_id }, allow_nil: true
    before_create :assign_number
  end

  private

  def assign_number
    self.number = project.reserve_number!(self.class.model_name.singular, number)
  end
end
