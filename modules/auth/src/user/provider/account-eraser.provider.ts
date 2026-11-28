/**
 * Apaga de verdade a conta e todos os dados dela (AT9): sessões, blocos,
 * objetivos e etapas, disponibilidade, compromissos e o usuário. Fica fora do
 * repositório de usuário porque cruza os módulos; o backend implementa numa
 * transação.
 */
export interface AccountEraser {
  eraseAccount(userId: string): Promise<void>;
}
