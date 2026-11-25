# Live props de Inertia (MT-99): el transporte de Action Cable de Inertia se suscribe aquí.
# Los nombres de stream van firmados al pintar la página; sin login, no hay más comprobación.
class InertiaChannel < ApplicationCable::Channel
  include InertiaRails::LiveChannel
end
