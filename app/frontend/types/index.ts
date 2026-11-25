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

export type SharedProps = {
  project: { key: string; name: string; slug: string }
  nav: { cover: string; board: string; roadmap: string; brief: string }
  notice?: string | null
  search?: SearchIndex
}
