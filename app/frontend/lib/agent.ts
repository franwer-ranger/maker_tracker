import { createAgent, registerTools } from "@ui-sdk/react/agent"

// El puente de UI SDK (MT-99): un agente lee los componentes de la página y llama a sus
// acciones. Por WebMCP (document.modelContext) si el navegador lo tiene; en la consola, window.agent.
const agent = createAgent()

Object.assign(window, { agent })

// Lo marcado con data-agent-confirm lo decide una persona; lo demás, el agente.
const unregister = registerTools(agent, { allow: (step) => !step.confirm })

if (import.meta.hot) import.meta.hot.dispose(unregister)

export { agent }
