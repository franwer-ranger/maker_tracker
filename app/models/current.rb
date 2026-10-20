# Estado de la petición en curso. En la UI, el actor es siempre Actor.human.
class Current < ActiveSupport::CurrentAttributes
  attribute :actor
  attribute :activity_for_you # las tarjetas de «Te toca», calculadas una vez por petición (MT-30)
  attribute :presence_written # la escritura de la petición ya marcó la presencia (MT-36)
end
