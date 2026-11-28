"use client";

import { useEffect, useRef, useState } from "react";
import type { Language } from "../data";
import { DESC, H2, PANEL } from "./settings-ui";

/** Idiomas do seletor. A lista abre ao clicar, para caber mais idiomas depois. */
const LANGUAGES: { id: Language; label: string }[] = [
  { id: "pt", label: "Português (Brasil)" },
  { id: "en", label: "English" },
  { id: "es", label: "Español" },
];

/**
 * "Idioma" (AT7, sem design no web): uma lista que abre ao clicar (pedido do dono do produto, 28/11/2026),
 * com as opções do app (M28). Só visual: o app continua em português.
 */
export default function LanguageSection({ value, onChange }: { value: Language | undefined; onChange: (language: Language) => void }) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const current = LANGUAGES.find((l) => l.id === value) ?? LANGUAGES[0];

  // Clicar fora fecha a lista.
  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => {
      if (!box.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, [open]);

  const pick = (id: Language) => {
    setOpen(false);
    onChange(id);
  };

  return (
    <section className={`flex items-center justify-between gap-6 p-6 ${PANEL}`}>
      <div>
        <h2 className={H2}>Idioma</h2>
        <p className={DESC}>Em que língua o Bora fala com você.</p>
      </div>
      <div ref={box} className="relative w-[240px]">
        <button
          type="button"
          aria-label={`Idioma: ${current.label}`}
          aria-haspopup="listbox"
          aria-expanded={open}
          onClick={() => setOpen((o) => !o)}
          className="flex h-11 w-full cursor-pointer items-center justify-between gap-2 rounded-[12px] border-2 border-border bg-surface px-3.5 text-[15px]/none font-extrabold text-tx"
        >
          {current.label}
          <i className={`ph-bold ph-caret-${open ? "up" : "down"} text-[16px] text-tx2`} />
        </button>
        {open && (
          <ul
            role="listbox"
            aria-label="Idioma"
            tabIndex={-1}
            onKeyDown={(e) => {
              if (e.key === "Escape") setOpen(false);
            }}
            className="absolute right-0 left-0 z-10 m-0 mt-1 max-h-[240px] list-none overflow-y-auto rounded-[12px] border border-border bg-surface p-1 shadow-card"
          >
            {LANGUAGES.map((l) => {
              const selected = l.id === current.id;
              return (
                <li
                  key={l.id}
                  role="option"
                  aria-selected={selected}
                  tabIndex={0}
                  onClick={() => pick(l.id)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      pick(l.id);
                    }
                  }}
                  className={`flex h-10 cursor-pointer items-center justify-between rounded-[8px] px-3 text-[15px]/none font-bold text-tx hover:bg-s2 ${selected ? "bg-pri-soft" : ""}`}
                >
                  {l.label}
                  {selected && <i className="ph-fill ph-check-circle text-[18px] text-pri" />}
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </section>
  );
}
