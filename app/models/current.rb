# Estado de la petición en curso. En la UI, el actor es siempre Actor.human.
class Current < ActiveSupport::CurrentAttributes
  attribute :actor
  attribute :activity_for_you # las tarjetas de «Te toca», calculadas una vez por petición (MT-30)
  attribute :ready_work # el trabajo listo de todos los proyectos, calculado una vez por petición (MT-33)
  attribute :api_request # la petición viene de la API (un agente o una persona con su token): su escritura marca presencia (MT-100)
  attribute :presence_written # la escritura de la petición ya marcó la presencia (MT-36)
  attribute :base_url # https://host de la petición a la API: los enlaces absolutos de los adjuntos (MT-96)
end
