# GET /api: la API se describe a sí misma.
class Api::RootController < Api::BaseController
  skip_before_action :authenticate_actor

  def show
    render_ok({ api_version: Api::Operations::VERSION, operations: Api::Operations::ALL },
      summary: "Maker Tracker API v#{Api::Operations::VERSION}: #{Api::Operations::ALL.size} operations.",
      breadcrumbs: [ "mt projects", "mt context" ])
  end
end
