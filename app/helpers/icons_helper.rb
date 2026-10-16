# Heroicons (outline, trazo 1.5) como SVG en línea. Solo se incluyen en
# app/assets/icons/ los que se usan; para añadir uno, copia su SVG de
# heroicons/24/outline. Heredan el color del texto (stroke="currentColor").
module IconsHelper
  ICONS_PATH = Rails.root.join("app/assets/icons")
  ICON_CACHE = Concurrent::Map.new

  # icon "arrow-right"            → 20px, el tamaño de interfaz
  # icon "plus", size: 16         → dentro de botones
  # icon "cog-6-tooth", class: "text-accent", aria: { label: "Ajustes" }
  def icon(name, size: 20, **attrs)
    attrs[:class] = class_names("inline-block shrink-0", attrs[:class])
    attrs[:aria] = { hidden: true } unless attrs.dig(:aria, :label)
    attrs[:role] = "img" if attrs.dig(:aria, :label)

    svg = icon_svg(name).sub("<svg ", "<svg #{tag.attributes(width: size, height: size, **attrs)} ")
    svg.html_safe # rubocop:disable Rails/OutputSafety -- SVG propio de app/assets/icons
  end

  private

  def icon_svg(name)
    ICON_CACHE[name.to_s] ||= begin
      path = ICONS_PATH.join("#{name}.svg")
      raise ArgumentError, "Icono desconocido: #{name} (añádelo a app/assets/icons/)" unless path.file?

      path.read.sub(' aria-hidden="true"', "").sub(' data-slot="icon"', "").strip
    end
  end
end
