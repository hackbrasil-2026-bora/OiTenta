import { Commitment, CommitmentRepository } from '@oitenta/scheduling';

// P8: compromissos (aula, estágio) existem só no domínio nesta fase; não há tela, endpoint
// nem tabela. Este repositório devolve sempre lista vazia para o CommitmentBusySource poder
// ser montado (C4). Quando houver a tabela `commitments`, entra um PrismaCommitmentRepository.
// As escritas ainda não têm onde gravar e falham de propósito (nenhuma rota as usa).
export class EmptyCommitmentRepository implements CommitmentRepository {
  create(data: Commitment): Promise<Commitment> {
    void data;
    return Promise.reject(new Error('Compromissos ainda não têm tabela.'));
  }

  update(data: Commitment): Promise<Commitment> {
    void data;
    return Promise.reject(new Error('Compromissos ainda não têm tabela.'));
  }

  delete(userId: string, id: string): Promise<void> {
    void userId;
    void id;
    return Promise.reject(new Error('Compromissos ainda não têm tabela.'));
  }

  findById(userId: string, id: string): Promise<Commitment | null> {
    void userId;
    void id;
    return Promise.resolve(null);
  }

  findAllByUser(userId: string): Promise<Commitment[]> {
    void userId;
    return Promise.resolve([]);
  }
}
