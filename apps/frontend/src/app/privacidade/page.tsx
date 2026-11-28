import type { Metadata } from "next";
import { PRIVACY } from "@/modules/legal/data/legal-texts";
import LegalPage from "@/modules/legal/pages/legal.page";

export const metadata: Metadata = { title: "Política de privacidade · Bora" };

export default function PrivacidadeRoutePage() {
  return <LegalPage doc={PRIVACY} />;
}
