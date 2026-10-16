# Componentes del sistema de diseño v3 (Paper → v3 · Sistema → 03 · Componentes).
# Código propio al estilo de shadcn: helpers y partials pequeños que usan los
# tokens de config/tailwind.config.js. Se ven todos juntos en /design (development).
module ComponentsHelper
  STATES = Story::STATE_NAMES

  # Foco: anillo de 2px del color del control, separado 2px del fondo.
  FOCUS_RING = "focus-visible:outline-none focus-visible:shadow-[0_0_0_2px_var(--color-bg),0_0_0_4px_var(--color-text)]".freeze
  ACCENT_FOCUS_RING = "focus-visible:outline-none focus-visible:shadow-[0_0_0_2px_var(--color-bg),0_0_0_4px_var(--color-accent)]".freeze
  HALO = "shadow-[0_0_0_3px_color-mix(in_srgb,var(--color-accent)_25%,transparent)]".freeze

  BUTTON_BASE = "inline-flex shrink-0 items-center justify-center whitespace-nowrap rounded-md font-medium " \
                "transition-colors duration-150 ease-brand".freeze
  BUTTON_SIZES = {
    md: "h-control gap-2 text-sm leading-[18px]",
    sm: "h-control-sm gap-1.5 px-3 text-control leading-4"
  }.freeze
  BUTTON_VARIANTS = {
    primary: "bg-accent text-bg hover:bg-accent-hover #{ACCENT_FOCUS_RING}",
    secondary: "border border-strong bg-bg text-text hover:bg-surface #{FOCUS_RING}",
    ghost: "text-text-muted hover:text-text focus-visible:text-text #{FOCUS_RING}"
  }.freeze
  BUTTON_DISABLED = "cursor-not-allowed bg-surface text-text-subtle".freeze

  # ui_button "Decidir"
  # ui_button "Ver PR", variant: :secondary, icon: "arrow-top-right-on-square", href: pr_url
  # ui_button "Abrir sesión", variant: :ghost, icon_trailing: "arrow-right"
  # ui_button "Guardar", type: "submit", size: :sm
  def ui_button(label = nil, variant: :primary, size: :md, icon: nil, icon_trailing: nil, href: nil, disabled: false, **attrs, &block)
    classes = class_names(
      BUTTON_BASE,
      BUTTON_SIZES.fetch(size),
      disabled ? BUTTON_DISABLED : BUTTON_VARIANTS.fetch(variant),
      attrs.delete(:class),
      "px-4": size == :md && variant != :ghost,
      "px-3": size == :md && variant == :ghost
    )
    content = safe_join([
      (icon(icon, size: 16) if icon),
      label || capture(&block),
      (icon(icon_trailing, size: 16) if icon_trailing)
    ].compact)

    if href && !disabled
      link_to content, href, class: classes, **attrs
    else
      tag.button content, type: attrs.delete(:type) || "button", disabled: disabled, class: classes, **attrs
    end
  end

  # nav_item "Actividad", project_path(project), count: 3
  def nav_item(label, href, active: current_page?(href), count: nil)
    classes = class_names(
      "flex h-nav shrink-0 items-center justify-between rounded-md px-3 text-sm leading-[18px] transition-colors duration-150 ease-brand",
      FOCUS_RING,
      active ? "bg-surface font-medium text-text" : "text-text-muted hover:text-text"
    )
    link_to href, class: classes, aria: { current: ("page" if active) } do
      safe_join([
        tag.span(label),
        (tag.span(count, class: "rounded-full bg-accent px-1.5 font-mono text-xs leading-[18px] text-bg") if count)
      ].compact)
    end
  end

  # state_dot :ready; state_dot :in_progress, size: 8
  # `halo: false` quita el halo de En curso (cabeceras de columna).
  def state_dot(state, size: 6, halo: true)
    state = state.to_sym
    tag.span class: class_names(
      "inline-block shrink-0 rounded-full",
      { 6 => "size-1.5", 8 => "size-2", 10 => "size-2.5" }.fetch(size),
      "border-[1.5px] border-state-idea": state == :idea,
      "bg-state-defining": state == :defining,
      "bg-state-ready": state == :ready,
      "bg-accent": state == :in_progress,
      HALO => state == :in_progress && halo,
      "bg-state-done": state == :done
    ), aria: { hidden: true }
  end

  # Control segmentado con los cinco estados. Son radios, así que funciona en
  # cualquier formulario: state_selector "story[state]", selected: story.state
  # `compact: true` aprieta el relleno para columnas estrechas (5.4). Los demás
  # atributos van a cada radio (p. ej. data: { action: "change->…" }).
  def state_selector(name, selected: nil, compact: false, **radio_attrs)
    tag.div role: "radiogroup", class: "inline-flex gap-0.5 rounded-[9px] border border-border bg-surface-sunken p-[3px]" do
      safe_join(STATES.map do |value, label|
        tag.label class: "relative flex h-[30px] cursor-pointer items-center rounded-md text-control leading-4 text-text-muted " \
                         "#{compact ? 'gap-[7px] px-[9px]' : 'gap-2 px-3'} " \
                         "transition-colors duration-150 ease-brand hover:text-text " \
                         "has-[:checked]:bg-surface has-[:checked]:font-medium has-[:checked]:text-text " \
                         "has-[:checked]:shadow-[inset_0_0_0_1px_var(--color-border-strong)] " \
                         "has-[:focus-visible]:shadow-[0_0_0_2px_var(--color-text)]" do
          safe_join([
            radio_button_tag(name, value, selected.to_s == value.to_s, class: "sr-only", **radio_attrs),
            state_dot(value, halo: false),
            label
          ])
        end
      end)
    end
  end

  # Input con label y ayuda (y el primer error de validación del atributo). Con form builder: ui_field f, :title, label: "Título", hint: "…"
  # Sin él: ui_field nil, :q, label: "Buscar", value: params[:q]
  # Sobre una superficie hundida (p. ej. el alta de proyecto), el input va sobre `bg`: surface: :bg.
  def ui_field(form, attribute, label:, hint: nil, surface: :sunken, **input_attrs)
    render "components/field", form: form, attribute: attribute, label: label, hint: hint, surface: surface, input_attrs: input_attrs
  end

  # actor "claude", detail: "en #48", active: true
  # actor "codex", detail: "inactivo · 2 h"
  # actor "tú", kind: :human, detail: "humano"
  def actor(name, kind: :agent, active: false, detail: nil)
    dot = class_names(
      "inline-block size-1.5 shrink-0 rounded-full",
      "bg-avatar": kind == :human,
      "bg-accent #{HALO}": kind != :human && active,
      "bg-text-subtle": kind != :human && !active
    )
    tag.span class: "inline-flex items-center gap-2 text-control leading-4" do
      safe_join([
        tag.span(class: dot, aria: { hidden: true }),
        tag.span(name, class: "font-mono text-text"),
        (tag.span(detail, class: "text-text-muted") if detail)
      ].compact)
    end
  end

  # meta_line "wflow", "implement", "41 min", "$3.12" → wflow · implement · 41 min · $3.12
  def meta_line(*parts, **attrs)
    tag.div parts.compact_blank.join(" · "), class: class_names("font-mono text-xs text-text-muted", attrs.delete(:class)), **attrs
  end

  # Etiqueta de sección: mono, mayúsculas, 12px, tracking 0.08em.
  def section_label(text, **attrs)
    tag.div text, class: class_names("font-mono text-xs uppercase tracking-label text-text-muted", attrs.delete(:class)), **attrs
  end

  # Menú desplegable (5.2 · Selector de hito): un <details> que se cierra al
  # pulsar fuera o con Escape. El bloque `summary` es el disparador.
  #   ui_menu(summary: ..., align: :left) { menu_item(...) }
  def ui_menu(summary:, align: :left, width: "w-80", **attrs, &block)
    tag.details class: class_names("relative", attrs.delete(:class)), data: { controller: "menu", action: "toggle->menu#toggle" }, **attrs do
      safe_join([
        tag.summary(summary, class: "list-none [&::-webkit-details-marker]:hidden cursor-pointer rounded-md #{FOCUS_RING}"),
        tag.div(capture(&block), class: class_names(
          "absolute top-full z-20 mt-1 flex flex-col rounded-lg border border-strong bg-surface p-1 shadow-[0_12px_32px_rgba(0,0,0,0.6)]",
          width, align == :right ? "right-0" : "left-0"
        ))
      ])
    end
  end

  def menu_separator = tag.div(class: "h-px shrink-0 bg-border")

  # Label de una historia: mono 11px sobre surface, radio 4.
  def ui_label(text)
    tag.span text, class: "rounded-sm bg-surface px-1.5 py-0.5 font-mono text-[11px] leading-[14px] text-text-muted"
  end

  # Opción de un menú: código en mono o icono (w-6), texto y metadato a la derecha.
  def menu_item(label, href, code: nil, icon: nil, meta: nil, meta_class: "text-text-muted", active: false, muted: false)
    link_to href, class: class_names(
      "flex h-nav shrink-0 items-center gap-2.5 rounded-md px-2.5 text-control",
      "hover:bg-[color-mix(in_srgb,var(--color-text)_6%,transparent)] #{FOCUS_RING}",
      "bg-[color-mix(in_srgb,var(--color-text)_6%,transparent)] font-medium text-text": active,
      "text-text-subtle": muted && !active,
      "text-text-soft": !muted && !active
    ), aria: { current: ("page" if active) } do
      safe_join([
        (tag.span(code, class: class_names("w-6 shrink-0 font-mono text-xs", muted ? "text-text-subtle" : "text-text-muted")) if code),
        (tag.span(icon(icon, size: 16), class: "flex w-6 shrink-0 items-center text-text-muted") if icon),
        tag.span(label, class: "grow truncate"),
        (tag.span(meta, class: "font-mono text-xs #{meta_class}") if meta)
      ].compact)
    end
  end

  # terminal "~/postgram" do "$ mt next\n#49 …" end
  def terminal(title = nil, &block)
    render "components/terminal", title: title, body: capture(&block)
  end
end
