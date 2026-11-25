Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Avisos push de este dispositivo (MT-47): por `endpoint`, que es lo que conoce el navegador.
  post "push_subscriptions", to: "push_subscriptions#create"
  delete "push_subscriptions", to: "push_subscriptions#destroy"

  if Rails.env.development?
    # Catálogo de la UI v1 (MT-101): todas las piezas dentro del marco, para comparar con Paper.
    get "design" => "v1/design#show"
  end

  # API para agentes (mt, MCP). Proyectos por su clave: /api/projects/PG/stories/49.
  # GET /api describe todas las operaciones (Api::Operations).
  namespace :api, defaults: { format: :json } do
    get "/", to: "root#show"
    get "questions", to: "questions#index"
    get "qa", to: "qa#index"
    resources :projects, param: :key, only: %i[index create]
    scope "projects/:project_key", as: :project do
      get "context", to: "contexts#show"
      get "next", to: "next_stories#show"
      get "roadmap", to: "roadmaps#show"
      get "workshop", to: "workshops#show"
      post "daily", to: "dailies#create"
      post "daily/ideas", to: "dailies#idea"
      get "deployed", to: "deploys#index"
      post "deployed", to: "deploys#create"
      post "usage", to: "usages#create"
      resources :stories, param: :number, only: %i[index show create update] do
        member do
          post :start, to: "story_work#start"
          post :done, to: "story_work#done"
          post :release, to: "story_work#release"
          post :move
          post :reorder
          post :answer, to: "questions#answer"
          post :qa, to: "qa#create"
        end
        resources :comments, only: :create
        resources :questions, only: :create
        resources :attachments, only: :create
      end
      resources :decisions, only: %i[index create]
      match "check", to: "checks#show", via: %i[get post]
      resources :milestones, param: :code, only: %i[create show update] do
        member do
          post :reorder
          post :close
          post :reopen
        end
      end
      resource :brief, only: %i[show update]
      resources :pages, path: "docs", param: :slug, only: %i[index show create update destroy] do
        resources :attachments, only: :create
      end
    end
    match "*path", to: "base#route_not_found", via: :all
  end

  # "/" es el taller (MT-97, sustituye a «Te toca»): el del primer producto con algo que definir; "/p" los lista.
  root "workshops#show"
  resources :projects, path: "p", only: %i[index create]

  # Todo lo de un proyecto cuelga de su slug: /p/postgram, /p/postgram/roadmap…
  scope "p/:project_slug", as: :project do
    get "/", to: "boards#show", as: ""
    # Prueba del stack v1 (MT-99): Inertia + React, al lado de las vistas de siempre.
    scope "v1", module: :v1, as: :v1 do
      get "/", to: "covers#show", as: :cover
      # La página de una capacidad (MT-103) y su markdown (el de `mt doc <slug>`).
      get "capacidades/:slug", to: "capabilities#show", as: :capability
      get "capacidades/:slug/markdown", to: "capabilities#markdown", as: :capability_markdown
      # Una historia (MT-104): leerla, responder, marcarla como Lista, comentar y enlazar una capacidad.
      scope "historias/:number", as: :story do
        get "/", to: "stories#show", as: ""
        post "lista", to: "stories#ready", as: :ready
        post "respuesta", to: "stories#answer", as: :answer
        post "comentarios", to: "stories#comment", as: :comment
        post "capacidades", to: "stories#link_capability", as: :capability
      end
      # El taller (MT-97): la portada de Maker Tracker, un producto cada vez.
      get "taller", to: "workshops#show", as: :workshop
      scope "taller/historias/:number", as: :workshop_story do
        post "lista", to: "workshops#ready", as: :ready
        post "respuesta", to: "workshops#answer", as: :answer
      end
      resources :milestones, path: "hitos", param: :number, only: %i[edit update]
    end
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
      resources :questions, only: [] do
        resource :answer, only: :create, module: :questions
      end
      scope module: :stories do
        resource :state, only: :update
        resource :position, only: :update
        resource :qa, only: :create, controller: "qa"
        resource :agent_notice, only: :show # el aviso de la edición, en directo (MT-38)
        resources :attachments, only: :create # pegar o arrastrar en el editor (MT-96)
      end
    end
  end
end
