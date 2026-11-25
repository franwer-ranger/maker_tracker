import { Fragment } from "react"
import { Icon } from "./icons"

type Screen = { code: string; title: string; src?: string | null }

// Recorrido con pantallas (10, «El recorrido» de «v1 · 3 · Capacidad»): capturas en orden, número en mono y flecha fina.
// Si falta la captura, la casilla lo dice (nunca imagen inventada). Si no caben, se desliza en horizontal.
export function Walkthrough({ screens }: { screens: Screen[] }) {
  return (
    <ol className="flex items-start gap-3.5 overflow-x-auto pb-2">
      {screens.map((screen, index) => (
        <Fragment key={screen.code}>
          {index > 0 && <Icon name="arrowRight" size={14} className="mt-[120px] text-muted-foreground" />}
          <li className="flex w-[118px] shrink-0 flex-col gap-2.5">
            {screen.src ? (
              <img src={screen.src} alt={screen.title} className="aspect-[118/255] w-full rounded-[var(--radius-panel)] border border-border object-cover" />
            ) : (
              <span className="flex aspect-[118/255] w-full flex-col items-center justify-center gap-2 rounded-[var(--radius-panel)] border border-border bg-card px-3 text-center text-label text-muted-foreground">
                <Icon name="design" size={14} />
                Falta la captura
              </span>
            )}
            <span className="flex items-baseline gap-2 text-control leading-[18px] text-foreground"><span className="font-mono text-label text-muted-foreground">{screen.code}</span><span className="max-w-[110px]">{screen.title}</span></span>
          </li>
        </Fragment>
      ))}
    </ol>
  )
}
