# /design (solo en development, MT-101): las piezas de la UI v1 dentro del marco, en claro y oscuro,
# para compararlas con Paper. El marco usa el proyecto de ?p=<slug> o el primero.
module V1
  class DesignController < ApplicationController
    def show
      render inertia: "Design"
    end

    private

    def set_project
      @project = Project.find_by(slug: params[:p]) || Project.order(:created_at).first!
    end
  end
end
