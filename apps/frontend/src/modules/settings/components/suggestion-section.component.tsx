"use client";

import { useState } from "react";
import { PRIMARY_BTN } from "@/modules/core/components/ui";
import { DESC, H2, PANEL } from "./settings-ui";

/** "Enviar sugestão" (AT6, sem design no web): o texto da M29 do app. Só visual até existir o POST /feedback. */
export default function SuggestionSection({ onSend }: { onSend: (text: string) => Promise<void> }) {
  const [text, setText] = useState("");
  const [sent, setSent] = useState(false);

  const send = async () => {
    await onSend(text.trim());
    setText("");
    setSent(true);
  };

  return (
    <section className={`flex flex-col gap-4 p-6 ${PANEL}`}>
      <div>
        <h2 className={H2}>Enviar sugestão</h2>
        <p className={DESC}>Achou algo estranho ou teve uma ideia? Conta pra gente.</p>
      </div>
      <label className="flex flex-col gap-1.5">
        <span className="text-[13px]/[16px] font-extrabold">O que podemos melhorar?</span>
        <textarea
          rows={4}
          value={text}
          placeholder="Ex.: queria poder mudar a cor dos objetivos"
          onChange={(e) => {
            setText(e.target.value);
            setSent(false);
          }}
          className="box-border w-full resize-y rounded-[12px] border-2 border-border bg-surface p-3.5 font-nunito text-[16px]/[24px] text-tx outline-0 focus:border-blue"
        />
      </label>
      <div className="flex items-center gap-4">
        <button type="button" aria-label="Enviar sugestão" disabled={!text.trim()} onClick={send} className={`${PRIMARY_BTN} disabled:opacity-50`}>
          Enviar
        </button>
        {sent && (
          <span role="status" className="text-[15px]/[20px] font-bold text-pri">
            Sugestão enviada. Valeu! A gente lê tudo.
          </span>
        )}
      </div>
    </section>
  );
}
