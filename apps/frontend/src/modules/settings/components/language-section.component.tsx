"use client";

import type { Language } from "../data";
import { DESC, H2, PANEL } from "./settings-ui";

const LANGUAGES: { id: Language; label: string }[] = [
  { id: "pt", label: "Português (Brasil)" },
  { id: "en", label: "English" },
  { id: "es", label: "Español" },
];

/** "Idioma" (AT7, sem design no web): as opções do app (M28). Só visual: o app continua em português. */
export default function LanguageSection({ value, onChange }: { value: Language | undefined; onChange: (language: Language) => void }) {
  return (
    <section className={`flex items-center justify-between gap-6 p-6 ${PANEL}`}>
      <div>
        <h2 className={H2}>Idioma</h2>
        <p className={DESC}>Em que língua o Bora fala com você.</p>
      </div>
      <div className="flex gap-1 rounded-full bg-s2 p-1">
        {LANGUAGES.map((l) => {
          const on = value === l.id;
          return (
            <button
              key={l.id}
              type="button"
              aria-pressed={on}
              onClick={() => onChange(l.id)}
              className={`flex h-10 cursor-pointer items-center rounded-full border px-[18px] text-[14px]/none font-extrabold text-tx ${on ? "border-border bg-surface" : "border-transparent bg-transparent"}`}
            >
              {l.label}
            </button>
          );
        })}
      </div>
    </section>
  );
}
