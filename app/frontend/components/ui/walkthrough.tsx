import { Fragment } from "react"
import { Icon } from "./icons"

type Screen = { code: string; title: string; src?: string | null }

// Recorrido con pantallas (10): capturas en orden, número en mono y flecha fina.
// Si falta la captura, la casilla lo dice (nunca imagen inventada).
export function Walkthrough({ screens }: { screens: Screen[] }) {
  return (
    <ol className="flex items-start gap-4 overflow-x-auto pb-2">
      {screens.map((screen, index) => (
        <Fragment key={screen.code}>
          {index > 0 && <Icon name="arrowRight" size={14} className="mt-[110px] text-muted-foreground" />}
          <li className="flex w-[118px] shrink-0 flex-col gap-2">
            {screen.src ? (
              <img src={screen.src} alt={screen.title} className="aspect-[118/254] w-full rounded-xl border border-border object-cover" />
            ) : (
              <span className="flex aspect-[118/254] w-full flex-col items-center justify-center gap-2 rounded-xl border border-border bg-card px-3 text-center text-label text-muted-foreground">
                <Icon name="design" size={14} />
                Falta la captura
              </span>
            )}
            <span className="flex gap-2 text-control text-foreground"><span className="font-mono text-muted-foreground">{screen.code}</span>{screen.title}</span>
          </li>
        </Fragment>
      ))}
    </ol>
  )
}
