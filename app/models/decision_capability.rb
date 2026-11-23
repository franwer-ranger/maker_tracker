# Una decisión que rige una página de la documentación (MT-90). Se crea con la
# decisión y se va con la página; la decisión se queda.
class DecisionCapability < ApplicationRecord
  belongs_to :decision
  belongs_to :page
end
