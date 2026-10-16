// Tema del sistema de diseño v3 (docs/DESIGN.md). Los valores viven como
// variables CSS en application.tailwind.css; aquí solo se exponen con los
// mismos nombres que los tokens de Paper.
module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        bg: 'var(--color-bg)',
        surface: 'var(--color-surface)',
        'surface-sunken': 'var(--color-surface-sunken)',
        border: 'var(--color-border)',
        'border-strong': 'var(--color-border-strong)',
        text: 'var(--color-text)',
        'text-soft': 'var(--color-text-soft)',
        'text-muted': 'var(--color-text-muted)',
        'text-subtle': 'var(--color-text-subtle)',
        accent: {
          DEFAULT: 'var(--color-accent)',
          hover: 'var(--color-accent-hover)',
        },
        avatar: 'var(--color-avatar)',
        state: {
          idea: 'var(--color-state-idea)',
          defining: 'var(--color-state-defining)',
          ready: 'var(--color-state-ready)',
          'in-progress': 'var(--color-accent)',
          done: 'var(--color-state-done)',
        },
      },
      // Atajos: text-soft, text-muted, text-subtle, border (por defecto) y border-strong.
      textColor: {
        DEFAULT: 'var(--color-text)',
        soft: 'var(--color-text-soft)',
        muted: 'var(--color-text-muted)',
        subtle: 'var(--color-text-subtle)',
      },
      borderColor: {
        DEFAULT: 'var(--color-border)',
        strong: 'var(--color-border-strong)',
      },
      fontFamily: {
        sans: 'var(--font-sans)',
        mono: 'var(--font-mono)',
        display: 'var(--font-display)',
      },
      // Tamaño / interlineado de 01 · Tipografía.
      fontSize: {
        xs: ['var(--text-xs)', '16px'],
        // Controles pequeños, selector de estado, actor, metadatos y ayudas de campo.
        control: ['var(--text-control)', '16px'],
        sm: ['var(--text-sm)', '20px'],
        base: ['var(--text-base)', '24px'],
        lg: ['var(--text-lg)', '28px'],
        xl: ['var(--text-xl)', '28px'],
        '2xl': ['var(--text-2xl)', '32px'],
        '3xl': ['var(--text-3xl)', '36px'],
        'display-sm': ['var(--text-display-sm)', '52px'],
        display: ['var(--text-display)', { lineHeight: '72px', letterSpacing: '-0.01em' }],
        'display-lg': ['var(--text-display-lg)', { lineHeight: '104px', letterSpacing: '-0.02em' }],
      },
      letterSpacing: {
        label: '0.08em',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
        full: 'var(--radius-full)',
      },
      // La escala de espaciado de Paper (base 4) coincide con la de Tailwind.
      height: {
        'control-sm': '32px',
        nav: '36px',
        control: '40px',
        'control-lg': '44px',
      },
      transitionTimingFunction: {
        brand: 'cubic-bezier(0.32, 0.72, 0, 1)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
