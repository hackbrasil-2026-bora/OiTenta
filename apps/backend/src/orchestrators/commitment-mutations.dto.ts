import { ApiProperty } from '@nestjs/swagger';
import { CommitmentView } from '../modules/scheduling/commitment.dto';
import { PlanResponse } from './plan.dto';

// Respostas das escritas dos compromissos (docs/4-contrato-api.md §5b): o plano recalculado vem junto.
export class CommitmentWithPlanResponse {
  @ApiProperty({ type: CommitmentView })
  commitment!: CommitmentView;

  @ApiProperty({ type: PlanResponse })
  plan!: PlanResponse;
}

export class CommitmentPlanResponse {
  @ApiProperty({ type: PlanResponse })
  plan!: PlanResponse;
}
