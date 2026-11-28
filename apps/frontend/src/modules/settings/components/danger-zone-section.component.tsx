"use client";

import { useState } from "react";
import { authRepository } from "@/modules/auth/data";
import { ApiError } from "@/modules/core/data/api-error";
import { PRIMARY_BTN } from "@/modules/core/components/ui";
import { DESC, FIELD, H2, LABEL, PANEL } from "./settings-ui";

const STRONG = (p: string) => p.length >= 8 && /[A-Z]/.test(p) && /[a-z]/.test(p) && /\d/.test(p) && /[^A-Za-z0-9]/.test(p);

const passwordError = (e: unknown) => {
  if (e instanceof ApiError && e.statusCode === 403) return "Senha atual incorreta.";
  if (e instanceof ApiError && e.statusCode === 422) return "A senha nova precisa de 8 caracteres, com maiúscula, minúscula, número e símbolo.";
  return "Não deu pra trocar a senha. Tenta de novo?";
};

/**
 * "Zona de risco" (AT9, sem design): trocar senha (PATCH /auth/me/password), sair e apagar a conta
 * (DELETE /auth/me, que apaga de verdade a conta e todos os dados). Apagar pede a senha.
 */
export default function DangerZoneSection({ onLogout, onDeleted }: { onLogout: () => void; onDeleted: () => void }) {
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [pwStatus, setPwStatus] = useState<{ ok: boolean; text: string } | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [deletePassword, setDeletePassword] = useState("");
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const mismatch = confirm.length > 0 && confirm !== next;
  const canChange = current.length > 0 && STRONG(next) && confirm === next;

  const edit = (set: (v: string) => void) => (v: string) => {
    set(v);
    setPwStatus(null);
  };

  const changePassword = async () => {
    try {
      await authRepository.changePassword({ currentPassword: current, newPassword: next });
      setCurrent("");
      setNext("");
      setConfirm("");
      setPwStatus({ ok: true, text: "Senha trocada." });
    } catch (e) {
      setPwStatus({ ok: false, text: passwordError(e) });
    }
  };

  const deleteAccount = async () => {
    try {
      await authRepository.deleteAccount({ currentPassword: deletePassword });
      onDeleted();
    } catch (e) {
      setDeleteError(e instanceof ApiError && e.statusCode === 403 ? e.message : "Não deu pra apagar a conta. Tenta de novo?");
    }
  };

  return (
    <section className={`flex flex-col gap-6 border-danger p-6 ${PANEL}`}>
      <div>
        <h2 className={`${H2} text-danger`}>Zona de risco</h2>
        <p className={DESC}>Trocar a senha, sair ou apagar a conta.</p>
      </div>

      <div className="flex flex-col gap-3">
        <b className="text-[16px]/[22px] font-extrabold">Trocar senha</b>
        <div className="grid grid-cols-3 gap-4">
          <label className="flex flex-col gap-1.5">
            <span className={LABEL}>Atual</span>
            <input aria-label="Senha atual da conta" className={FIELD} type="password" value={current} onChange={(e) => edit(setCurrent)(e.target.value)} />
          </label>
          <label className="flex flex-col gap-1.5">
            <span className={LABEL}>Nova</span>
            <input aria-label="Senha nova" className={FIELD} type="password" value={next} onChange={(e) => edit(setNext)(e.target.value)} />
          </label>
          <label className="flex flex-col gap-1.5">
            <span className={LABEL}>Confirme</span>
            <input aria-label="Confirme a senha nova" className={FIELD} type="password" value={confirm} onChange={(e) => edit(setConfirm)(e.target.value)} />
          </label>
        </div>
        <span className={`text-[14px]/[20px] font-semibold ${STRONG(next) ? "text-pri" : "text-tx2"}`}>
          8 caracteres ou mais, com maiúscula, minúscula, número e símbolo.
        </span>
        {mismatch && <span className="text-[14px]/[20px] font-semibold text-danger">As senhas não batem.</span>}
        <div className="flex items-center gap-4">
          <button type="button" aria-label="Trocar senha" disabled={!canChange} onClick={changePassword} className={`${PRIMARY_BTN} disabled:opacity-50`}>
            Salvar senha
          </button>
          {pwStatus && (
            <span role="status" className={`text-[15px]/[20px] font-bold ${pwStatus.ok ? "text-pri" : "text-danger"}`}>
              {pwStatus.text}
            </span>
          )}
        </div>
      </div>

      <div className="flex items-center justify-between gap-6 border-t border-border pt-5">
        <div>
          <b className="text-[16px]/[22px] font-extrabold">Sair da conta</b>
          <p className={DESC}>Seus dados ficam salvos. É só entrar de novo.</p>
        </div>
        <button type="button" onClick={onLogout} className="flex h-11 cursor-pointer items-center gap-1.5 rounded-full bg-transparent px-4 text-[15px]/none font-extrabold text-blue hover:bg-blue-soft">
          <i className="ph-bold ph-sign-out text-[16px]" />Sair
        </button>
      </div>

      <div className="flex flex-col gap-3 border-t border-border pt-5">
        <div className="flex items-center justify-between gap-6">
          <div>
            <b className="text-[16px]/[22px] font-extrabold text-danger">Apagar conta</b>
            <p className={DESC}>Apaga a conta e todos os dados. Não dá pra desfazer.</p>
          </div>
          {!deleting && (
            <button type="button" onClick={() => setDeleting(true)} className="flex h-11 cursor-pointer items-center gap-1.5 rounded-full border-2 border-danger bg-transparent px-4 text-[15px]/none font-extrabold text-danger">
              <i className="ph-bold ph-trash text-[16px]" />Apagar conta
            </button>
          )}
        </div>
        {deleting && (
          <div className="flex flex-col gap-3 rounded-[12px] bg-s2 p-4">
            <p className="m-0 text-[15px]/[22px] font-semibold">
              Isso apaga de verdade a sua conta e tudo o que está nela: objetivos, etapas, plano, sessões de foco, rotina e compromissos.
            </p>
            <label className="flex max-w-[360px] flex-col gap-1.5">
              <span className={LABEL}>Confirme com a sua senha</span>
              <input
                aria-label="Senha para apagar a conta"
                className={FIELD}
                type="password"
                value={deletePassword}
                onChange={(e) => {
                  setDeletePassword(e.target.value);
                  setDeleteError(null);
                }}
              />
            </label>
            {deleteError && (
              <span role="alert" className="text-[15px]/[20px] font-bold text-danger">
                {deleteError}
              </span>
            )}
            <div className="flex items-center gap-3">
              <button
                type="button"
                disabled={!deletePassword}
                onClick={deleteAccount}
                className="flex h-[52px] cursor-pointer items-center justify-center rounded-full bg-danger px-7 text-[16px]/none font-extrabold text-pri-tx disabled:cursor-not-allowed disabled:opacity-50"
              >
                Apagar minha conta
              </button>
              <button type="button" onClick={() => setDeleting(false)} className="flex h-11 cursor-pointer items-center rounded-full bg-transparent px-4 text-[15px]/none font-extrabold text-blue hover:bg-blue-soft">
                Cancelar
              </button>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
