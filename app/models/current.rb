# Estado de la petición en curso. En la UI, el actor es siempre Actor.human.
class Current < ActiveSupport::CurrentAttributes
  attribute :actor
  attribute :presence_written # la escritura de la petición ya marcó la presencia (MT-36)
end
