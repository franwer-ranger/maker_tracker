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
  agents: { name: string; target: string | null }[]
  user: string | null
}

export type SharedProps = {
  frame: Frame
  project: { key: string; name: string; slug: string }
  nav: { cover: string; workshop: string; board: string; roadmap: string; brief: string; decisions: string }
  notice?: string | null
  search?: SearchIndex
}
