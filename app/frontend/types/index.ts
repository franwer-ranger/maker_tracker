export type FlashData = {
  notice?: string
  alert?: string
}

export type SearchItem = {
  value: string
  ref: string
  title: string
  meta: string
  url: string
  state?: string
}

export type SearchIndex = {
  stories: SearchItem[]
  capabilities: SearchItem[]
  decisions: SearchItem[]
}

export type Frame = {
  products: { key: string; name: string; url: string }[]
  taller: number
  capabilities: { area: string | null; items: { slug: string; title: string; url: string }[] }[]
  user: string | null
}

// La presencia (MT-100): quién está activo y qué se está editando ahora (`key`: el `data-presence` del elemento).
export type PresenceEditing = { actor: string; agent: boolean; key: string | null; label: string; url: string | null; left_ms: number }

export type Presence = {
  // `label`: lo que toca, con el mismo nombre que la pestaña ("MT-12", "M2", el título de la página, "D-5").
  actors: { name: string; agent: boolean; label: string | null }[]
  editing: PresenceEditing[]
}

export type SharedProps = {
  frame: Frame
  presence: Presence
  project: { key: string; name: string; slug: string }
  nav: { cover: string; workshop: string; board: string; roadmap: string; brief: string; decisions: string }
  notice?: string | null
  search?: SearchIndex
}
