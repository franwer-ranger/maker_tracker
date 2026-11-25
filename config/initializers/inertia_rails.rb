# frozen_string_literal: true

# Prueba del stack v1 (MT-99): Inertia v3 con React y Vite, al lado de las vistas de Hotwire.
InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true
  config.use_data_inertia_head_attribute = true
  config.server_head = true
  config.convert_fragment_redirects = true
end
