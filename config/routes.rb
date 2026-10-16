Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "design" => "design#show" if Rails.env.development?

  # API para agentes (mt, MCP). Proyectos por su clave: /api/projects/PG/stories/49.
  # GET /api describe todas las operaciones (Api::Operations).
  namespace :api, defaults: { format: :json } do
    get "/", to: "root#show"
    resources :projects, param: :key, only: :index
    scope "projects/:project_key", as: :project do
      get "context", to: "contexts#show"
      get "next", to: "next_stories#show"
      get "roadmap", to: "roadmaps#show"
      resources :stories, param: :number, only: %i[index show] do
        member do
          post :start, to: "story_work#start"
          post :done, to: "story_work#done"
          post :release, to: "story_work#release"
        end
        resources :comments, only: :create
      end
      resources :decisions, only: %i[index create]
    end
    match "*path", to: "base#route_not_found", via: :all
  end

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
    resource :brief, only: %i[show edit update]
    resources :decisions, only: :create
    resources :stories, param: :number, only: %i[show create edit update] do
      resources :comments, only: :create
      scope module: :stories do
        resource :state, only: :update
        resource :position, only: :update
      end
    end
  end
end
