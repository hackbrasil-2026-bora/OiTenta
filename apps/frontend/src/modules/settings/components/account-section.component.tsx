"use client";

import { useState } from "react";
import { authRepository, type AuthUser } from "@/modules/auth/data";
import { ApiError } from "@/modules/core/data/api-error";
import { PRIMARY_BTN } from "@/modules/core/components/ui";
import { DESC, FIELD, H2, LABEL, PANEL } from "./settings-ui";

const normalize = (email: string) => email.trim().toLowerCase();

const messageOf = (e: unknown) => {
  if (e instanceof ApiError && e.statusCode === 403) return "Senha atual incorreta.";
  if (e instanceof ApiError && e.statusCode === 409) return "Esse e-mail já está em uso em outra conta.";
  if (e instanceof ApiError && (e.statusCode === 400 || e.statusCode === 422)) return "Confira o nome e o e-mail.";
  return "Não deu pra salvar. Tenta de novo?";
};

/**
 * "Sua conta" (AT3, sem design): troca o nome e/ou o e-mail com PATCH /auth/me. A senha atual só aparece
 * quando o e-mail muda. O id da conta não muda.
 */
export default function AccountSection({ user, onSaved }: { user: AuthUser; onSaved: (user: AuthUser) => void }) {
  const [name, setName] = useState(user.name);
  const [email, setEmail] = useState(user.email);
  const [password, setPassword] = useState("");
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState<{ ok: boolean; text: string } | null>(null);

  const nameChanged = name.trim() !== user.name.trim();
  const emailChanged = normalize(email) !== normalize(user.email);
  const valid = name.trim().length >= 2 && /^[^@\s]+@[^@\s]+$/.test(normalize(email));
  const canSave = !saving && (nameChanged || emailChanged) && valid && (!emailChanged || password.length > 0);

  const edit = (set: (v: string) => void) => (v: string) => {
    set(v);
    setStatus(null);
  };

  const save = async () => {
    setSaving(true);
    try {
      const { user: saved } = await authRepository.updateProfile({
        ...(nameChanged ? { name: name.trim() } : {}),
        ...(emailChanged ? { email: normalize(email), currentPassword: password } : {}),
      });
      setName(saved.name);
      setEmail(saved.email);
      setPassword("");
      setStatus({ ok: true, text: "Perfil atualizado." });
      onSaved(saved);
    } catch (e) {
      setStatus({ ok: false, text: messageOf(e) });
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className={`flex flex-col gap-4 p-6 ${PANEL}`}>
      <div>
        <h2 className={H2}>Sua conta</h2>
        <p className={DESC}>Sua conta continua a mesma: dá pra trocar o nome e o e-mail quando quiser.</p>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <label className="flex flex-col gap-1.5">
          <span className={LABEL}>Nome</span>
          <input className={FIELD} value={name} placeholder="Como quer ser chamado?" onChange={(e) => edit(setName)(e.target.value)} />
        </label>
        <label className="flex flex-col gap-1.5">
          <span className={LABEL}>E-mail</span>
          <input className={FIELD} type="email" value={email} placeholder="seu@email.com" onChange={(e) => edit(setEmail)(e.target.value)} />
        </label>
      </div>
      {emailChanged && (
        <div className="flex max-w-[calc(50%-8px)] flex-col gap-1.5">
          <label className="flex flex-col gap-1.5">
            <span className={LABEL}>Senha atual</span>
            <input className={FIELD} type="password" value={password} placeholder="Sua senha de agora" onChange={(e) => edit(setPassword)(e.target.value)} />
          </label>
          <span className="text-[14px]/[20px] font-semibold text-tx2">Pra trocar o e-mail, confirme sua senha atual.</span>
        </div>
      )}
      <div className="flex items-center gap-4">
        <button type="button" aria-label="Salvar conta" disabled={!canSave} onClick={save} className={`${PRIMARY_BTN} disabled:opacity-50`}>
          Salvar
        </button>
        {status && (
          <span role="status" className={`text-[15px]/[20px] font-bold ${status.ok ? "text-pri" : "text-danger"}`}>
            {status.text}
          </span>
        )}
      </div>
    </section>
  );
}
