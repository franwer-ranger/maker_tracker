import { createChange, createTransfer, definePrimitive, type ChangeDetails, type TransferDraft } from "@ui-sdk/core"
import { createParts } from "@ui-sdk/react/primitive"

type Lists = Record<string, string[]>

const normalize = (text: string) => text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim()
type BoardOptions = {
  value?: Lists
  defaultValue?: Lists
  order?: () => string[]
  label?: (key: string) => string | undefined
  listLabel?: (list: string) => string | undefined
  onValueChange?: (value: Lists, details: ChangeDetails<"drag" | "move-key" | "imperative"> & { key: string; from: string; to: string; index: number }) => void
}

// Tablero: tarjetas que pasan de una columna a otra arrastrando o con el teclado (createTransfer de UI SDK).
// Espacio coge la tarjeta, Izquierda y Derecha la cambian de columna, Espacio la suelta y Escape la devuelve.
// Intro abre la tarjeta (es un enlace, y conserva su papel de enlace) mientras no esté cogida. Un agente la mueve
// con `moveCard` (tarjeta, columna y, si quiere, posición).
const board = definePrimitive({
  name: "board",
  options: { value: "value", defaultValue: "value", order: "callback", label: "callback", listLabel: "callback", onValueChange: "callback" },
  controlled: ["value"],
  state: (options: BoardOptions) => ({
    value: options.value ?? options.defaultValue ?? {},
    moving: null as TransferDraft | null,
  }),
  sync: (options) => (options.value === undefined ? {} : { value: options.value }),
  api: (context) => {
    const change = createChange(context)
    const transfer = createTransfer(context, {
      key: "value",
      draft: "moving",
      order: () => context.options().order?.() ?? Object.keys(context.store.get().value),
      label: (key) => context.options().label?.(key),
      listLabel: (list) => context.options().listLabel?.(list),
      set: (value, details) => change("value", value, details),
    })
    const lists = () => context.store.get().value
    const named = (text: string, keys: string[], name: (key: string) => string | undefined) => {
      const wanted = normalize(text)
      return keys.find((key) => key === text) ?? keys.find((key) => normalize(key) === wanted || normalize(name(key) ?? "") === wanted)
    }
    // Para agentes: lleva una tarjeta a una columna, en una posición (desde 1) o al final, como al soltarla.
    // Pasa por el mismo onValueChange que el arrastre, así que la página decide igual que con una persona.
    const moveCard = (card: string, list: string, position?: number) => {
      const current = lists()
      const columns = Object.keys(current)
      const cards = columns.flatMap((column) => current[column])
      const key = named(String(card), cards, (key) => context.options().label?.(key))
      if (!key) throw new Error(`No hay ninguna tarjeta «${card}».`)
      const to = named(String(list), columns, (column) => context.options().listLabel?.(column))
      if (!to) throw new Error(`No hay ninguna columna «${list}». Columnas: ${columns.map((column) => context.options().listLabel?.(column) ?? column).join(", ")}.`)
      const rest = current[to].filter((other) => other !== key)
      const index = position === undefined ? rest.length : Number(position) - 1
      if (!Number.isInteger(index) || index < 0 || index > rest.length) throw new Error(`La posición va de 1 a ${rest.length + 1}.`)
      if (!transfer.move(key, to, index)) throw new Error(`${key} ya está ahí.`)
      return true
    }
    const cards = () => Object.values(lists()).flat().map((key) => ({ value: key, label: context.options().label?.(key) ?? key }))
    return { transfer, moveCard, cards }
  },
  slots: (slot) => ({
    // Las columnas como se ven ahora: las del borrador mientras se mueve una tarjeta, si no, el valor; y cuál se mueve.
    root: slot({
      state: (state, part) => ({ lists: part.api.transfer.lists(state), moving: state.moving?.key ?? null }),
      attrs: () => ({ "aria-roledescription": "tablero" }),
    }),
    column: slot<{ value: string }>({
      props: { value: "string" },
      bind: (el, part) => part.api.transfer.bindList(el, part.key),
    }),
    card: slot<{ value: string }>({
      props: { value: "string" },
      attrs: (state, part) => ({
        "aria-roledescription": "tarjeta",
        "data-grabbed": part.api.transfer.moving(state, part.key) ? "" : undefined,
        "data-dragging": part.api.transfer.dragging(state, part.key) ? "" : undefined,
      }),
      press: { none: "Espacio coge la tarjeta en keydown, como pide createTransfer; Intro la abre." },
      on: {
        keydown: (event, { el, api, key }) => {
          if (event.key === "Enter" && !el?.hasAttribute("data-grabbed")) return
          api.transfer.keydown(event, key)
        },
        pointerdown: (event, { api, key }) => api.transfer.pointerdown(event, key),
      },
      bind: (el, part) => part.api.transfer.bindItem(el, part.key),
    }),
  }),
  agent: { actions: ["moveCard"], items: (api) => api.cards() },
})

const { Root: Board, Column: BoardColumn, Card: BoardCard } = createParts(board, { root: "div", column: "div", card: "div" })

export { Board, BoardCard, BoardColumn }
