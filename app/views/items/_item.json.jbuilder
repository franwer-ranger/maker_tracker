json.extract! item, :id, :status, :kind, :icebox, :name, :description, :points, :user_id, :sprint_id, :created_at,
:updated_at
json.url item_url(item, format: :json)
