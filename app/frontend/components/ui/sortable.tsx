import { createChange, createReorder, definePrimitive, type ChangeDetails, type ReorderDraft } from "@ui-sdk/core"
import { createParts } from "@ui-sdk/react/primitive"

type SortableOptions = {
  value?: string[]
  defaultValue?: string[]
  label?: (key: string) => string | undefined
  onValueChange?: (value: string[], details: ChangeDetails<"drag" | "move-key" | "imperative">) => void
}

// Lista que se ordena arrastrando o con el teclado (createReorder de UI SDK). Cada fila tiene un asa:
// Espacio o Intro la coge, las flechas la mueven, Espacio la suelta y Escape cancela.
const sortable = definePrimitive({
  name: "sortable-list",
  options: { value: "list", defaultValue: "list", label: "callback", onValueChange: "callback" },
  controlled: ["value"],
  state: (options: SortableOptions) => ({
    value: options.value ?? options.defaultValue ?? [],
    moving: null as ReorderDraft | null,
  }),
  sync: (options) => (options.value === undefined ? {} : { value: options.value }),
  api: (context) => {
    const change = createChange(context)
    const reorder = createReorder(context, {
      slot: "item",
      key: "value",
      draft: "moving",
      label: (key) => context.options().label?.(key),
      set: (value, details) => change("value", value, details),
    })
    return { reorder }
  },
  slots: (slot) => ({
    root: slot({ attrs: () => ({ role: "list", "aria-roledescription": "lista ordenable" }) }),
    item: slot<{ value: string }>({
      props: { value: "string" },
      attrs: (state, part) => ({
        role: "listitem",
        "data-grabbed": part.api.reorder.moving(state, part.key) ? "" : undefined,
        "data-dragging": part.api.reorder.dragging(state, part.key) ? "" : undefined,
      }),
      bind: (el, part) => part.api.reorder.bind(el, part),
    }),
    handle: slot<{ value: string }>({
      props: { value: "string" },
      attrs: (state, part) => ({
        type: "button",
        "aria-roledescription": "asa para ordenar",
        "aria-pressed": String(part.api.reorder.moving(state, part.key)),
      }),
      press: { none: "Se coge con Espacio o Intro en keydown, como pide createReorder." },
      on: {
        keydown: (event, { api, key }) => { api.reorder.keydown(event, key) },
        pointerdown: (event, { api, key }) => api.reorder.pointerdown(event, key),
      },
    }),
  }),
})

const { Root: Sortable, Item: SortableItem, Handle: SortableHandle } = createParts(sortable, { root: "div", item: "div", handle: "button" })

export { Sortable, SortableHandle, SortableItem }
