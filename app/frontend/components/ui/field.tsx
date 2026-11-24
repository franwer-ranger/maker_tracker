import { Field, FieldDescription, FieldError, FieldLabel } from "@ui-sdk/react/field"
import { Input } from "@ui-sdk/react/input"
import { Textarea } from "@ui-sdk/react/textarea"
import { cx } from "./cx"

type Props = {
  label: string
  name: string
  value: string
  onChange: (value: string) => void
  description?: string
  errors?: string[] | string
  multiline?: boolean
}

const control =
  "w-full rounded-md border border-input bg-card px-3 text-sm text-foreground placeholder:text-muted-foreground data-invalid:border-destructive"

// Campo con su etiqueta, ayuda y los errores que devuelve Rails (UI SDK los conecta con aria-describedby).
export function TextField({ label, name, value, onChange, description, errors, multiline }: Props) {
  const messages = [errors ?? []].flat().filter(Boolean)
  return (
    <Field name={name} invalid={messages.length > 0 ? true : undefined} className="flex flex-col gap-1.5">
      <FieldLabel className="text-control font-medium text-foreground">{label}</FieldLabel>
      {multiline ? (
        <Textarea value={value} onValueChange={(next) => onChange(next)} rows={4} className={cx(control, "py-2 leading-6")} />
      ) : (
        <Input value={value} onValueChange={(next) => onChange(next)} className={cx(control, "h-9")} />
      )}
      {description && <FieldDescription className="text-control text-muted-foreground">{description}</FieldDescription>}
      <FieldError match={messages.length > 0} className="text-control text-destructive">
        {`${label} ${messages.join(", ")}`}
      </FieldError>
    </Field>
  )
}
