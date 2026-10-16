# Estado de la petición en curso. En la UI, el actor es siempre Actor.human.
class Current < ActiveSupport::CurrentAttributes
  attribute :actor
end
