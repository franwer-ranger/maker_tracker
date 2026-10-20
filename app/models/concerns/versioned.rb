# Bloqueo optimista por versión (MT-37). Quien edita contenido manda la versión
# que leyó; si ya no es la actual, la edición se rechaza y no se guarda nada.
# La versión sube solo al editar contenido: mover, reordenar o cerrar son
# acciones atómicas y no la tocan. Sin versión (`nil`) no se comprueba.
module Versioned
  extend ActiveSupport::Concern

  # La versión enviada ya no es la actual.
  class Conflict < StandardError
    attr_reader :record, :expected, :current, :editor, :edited_at

    def initialize(record, expected:, current:, editor: nil, edited_at: nil)
      @record, @expected, @current, @editor, @edited_at = record, expected, current, editor, edited_at
      super("Alguien cambió #{record.class.model_name.human.downcase} mientras la editabas")
    end
  end

  private

  # Dentro de la transacción de la edición, con el registro bloqueado y
  # recargado (antes de asignar nada).
  def check_version!(expected, attribute: :version)
    lock!
    return if expected.nil?

    current = public_send(attribute)
    return if expected.to_i == current

    editor, edited_at = last_editor
    raise Conflict.new(self, expected: expected.to_i, current: current, editor: editor, edited_at: edited_at)
  end

  def bump_version(attribute = :version) = self[attribute] = public_send(attribute) + 1
end
