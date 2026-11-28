import type { Metadata } from "next";
import { TERMS } from "@/modules/legal/data/legal-texts";
import LegalPage from "@/modules/legal/pages/legal.page";

export const metadata: Metadata = { title: "Termos de uso · Bora" };

export default function TermosRoutePage() {
  return <LegalPage doc={TERMS} />;
}
