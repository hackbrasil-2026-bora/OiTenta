import { Injectable } from '@nestjs/common';
import { AccountEraser } from '@oitenta/auth';
import { PrismaService } from '../../db/prisma.service';

/**
 * Apaga de verdade a conta e todos os dados dela (AT9, LGPD), numa transação
 * só: se algo falhar, nada é apagado. A ordem respeita as chaves estrangeiras
 * (as etapas caem com o objetivo e as exceções com o compromisso, em cascata).
 */
@Injectable()
export class PrismaAccountEraser implements AccountEraser {
  constructor(private readonly prisma: PrismaService) {}

  async eraseAccount(userId: string): Promise<void> {
    const where = { userId };
    await this.prisma.$transaction([
      this.prisma.focusSession.deleteMany({ where }),
      this.prisma.scheduledBlock.deleteMany({ where }),
      this.prisma.goal.deleteMany({ where }),
      this.prisma.weeklyAvailability.deleteMany({ where }),
      this.prisma.commitment.deleteMany({ where }),
      this.prisma.user.delete({ where: { id: userId } }),
    ]);
  }
}
