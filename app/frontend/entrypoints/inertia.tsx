import "../styles/application.css"
import "../lib/agent"
import { actionCable } from "@inertiajs/core/actionCable"
import { createInertiaApp } from "@inertiajs/react"
import { createConsumer } from "@rails/actioncable"
import { applyTheme } from "../lib/theme"

applyTheme()

void createInertiaApp({
  pages: "../pages",
  serverHead: true,
  title: (title) => (title ? `${title} · Maker Tracker` : "Maker Tracker"),
  strictMode: true,
  // Live props (MT-99): cada evento del proyecto emite por Action Cable y la página recarga solo esos props.
  live: actionCable({ consumer: () => createConsumer() }),
  defaults: {
    form: { forceIndicesArrayFormatInFormData: false, withAllErrors: true },
  },
})
