# La QA salió de Maker Tracker (MT-98, D-97): probar lo construido es de Relay.
# `mt qa` ya no existe; un CLI antiguo que la llame recibe GONE con el porqué.
class Api::QaController < Api::BaseController
  def index = raise gone

  def create = raise gone

  private

  def gone
    Api::Error.new("GONE", "QA is no longer part of Maker Tracker: testing what is built belongs to Relay (D-97).", status: :gone,
      hint: "test it with Relay. The old qa.passed and qa.failed events stay in the history of each story (mt show).")
  end
end
