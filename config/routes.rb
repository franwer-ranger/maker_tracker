Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "design" => "design#show" if Rails.env.development?

  # "/" redirige al proyecto si solo hay uno; "/p" lista siempre los proyectos.
  root "projects#index"
  resources :projects, path: "p", only: %i[index create]

  # Todo lo de un proyecto cuelga de su slug: /p/postgram, /p/postgram/roadmap…
  scope "p/:project_slug", as: :project do
    get "/", to: "boards#show", as: ""
    resource :roadmap, only: :show
    resources :milestones, only: :create do
      scope module: :milestones do
        resource :position, only: :update
        resource :closure, only: %i[create destroy]
      end
    end
    resource :brief, only: :show
    resources :stories, param: :number, only: %i[show create] do
      scope module: :stories do
        resource :state, only: :update
        resource :position, only: :update
      end
    end
  end
end
