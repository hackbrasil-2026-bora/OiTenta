import Link from "next/link";
import { KICKER } from "@/modules/core/components/ui";
import Broto from "@/modules/landing/components/broto.component";
import { LEGAL_DRAFT_NOTICE, TERMS, type LegalDocument } from "../data/legal-texts";

/** Termos de uso (/termos) e Política de privacidade (/privacidade). Públicas: abrem sem login. **Sem design.** */
export default function LegalPage({ doc }: { doc: LegalDocument }) {
  const other = doc === TERMS ? { href: "/privacidade", label: "Política de privacidade" } : { href: "/termos", label: "Termos de uso" };
  return (
    <main className="min-h-screen bg-bg text-tx">
      <div className="mx-auto box-border flex max-w-[760px] flex-col gap-6 px-6 pt-10 pb-20">
        <Link href="/" className="flex items-center gap-2 font-fredoka text-[22px]/none font-semibold text-tx no-underline">
          <Broto size={36} />
          Bora
        </Link>
        <div>
          <span className={KICKER}>Atualizado em {doc.updated}</span>
          <h1 className="mt-1.5 mb-0 font-fredoka text-[40px]/[48px] font-semibold">{doc.title}</h1>
        </div>
        <p role="note" className="m-0 rounded-[12px] bg-s2 px-4 py-3 text-[15px]/[22px] font-bold text-tx2">
          {LEGAL_DRAFT_NOTICE}
        </p>
        <p className="m-0 text-[17px]/[28px]">{doc.intro}</p>
        {doc.sections.map((s) => (
          <section key={s.heading} className="flex flex-col gap-2">
            <h2 className="m-0 font-fredoka text-[22px]/[28px] font-semibold">{s.heading}</h2>
            {s.paragraphs.map((p) => (
              <p key={p} className="m-0 text-[16px]/[26px]">{p}</p>
            ))}
          </section>
        ))}
        <p className="m-0 border-t border-border pt-5 text-[15px]/[22px] font-semibold text-tx2">
          Veja também a{" "}
          <Link href={other.href} className="font-extrabold text-blue">
            {other.label}
          </Link>
          .
        </p>
      </div>
    </main>
  );
}
