import {
  Body,
  Controller,
  Delete,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import {
  CommitmentOccurrenceParams,
  CreateCommitmentBody,
  DeleteCommitmentQuery,
  SetOccurrenceBody,
  toCommitmentView,
  toRecurrence,
  UpdateCommitmentBody,
} from '../modules/scheduling/commitment.dto';
import { JwtAuthGuard } from '../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../shared/decorators/current-user.decorator';
import { CommitmentCreateOrchestrator } from './commitment-create.orchestrator';
import { CommitmentDeleteOrchestrator } from './commitment-delete.orchestrator';
import {
  CommitmentPlanResponse,
  CommitmentWithPlanResponse,
} from './commitment-mutations.dto';
import { CommitmentOccurrenceOrchestrator } from './commitment-occurrence.orchestrator';
import { CommitmentUpdateOrchestrator } from './commitment-update.orchestrator';

// Escritas dos compromissos (docs/4 §5b): cada uma chama o caso de uso e recalcula o plano.
// As leituras (GET :id e GET occurrences) estão no SchedulingController.
@ApiTags('scheduling')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@ApiUnauthorizedResponse({
  description: 'Token ausente, inválido ou expirado.',
})
@Controller('scheduling/commitments')
export class CommitmentMutationsController {
  constructor(
    private readonly createCommitment: CommitmentCreateOrchestrator,
    private readonly updateCommitment: CommitmentUpdateOrchestrator,
    private readonly deleteCommitment: CommitmentDeleteOrchestrator,
    private readonly occurrence: CommitmentOccurrenceOrchestrator,
  ) {}

  @Post()
  @ApiCreatedResponse({ type: CommitmentWithPlanResponse })
  @ApiBadRequestResponse({
    description: 'Corpo malformado ou campo não previsto (como userId).',
  })
  @ApiNotFoundResponse({
    description: 'O usuário ainda não tem disponibilidade (P12).',
  })
  @ApiUnprocessableEntityResponse({
    description:
      'Título fora de 2–80, horário fora dos múltiplos de 5, fim antes do início, dia da semana ou data inválidos.',
  })
  async create(
    @CurrentUser('id') userId: string,
    @Body() body: CreateCommitmentBody,
  ): Promise<CommitmentWithPlanResponse> {
    const { commitment, plan } = await this.createCommitment.execute({
      userId,
      title: body.title,
      category: body.category,
      startDate: body.startDate,
      startMinute: body.startMinute,
      endMinute: body.endMinute,
      recurrence: toRecurrence(body.recurrence),
    });
    return { commitment: toCommitmentView(commitment), plan };
  }

  @Patch(':id')
  @ApiOkResponse({
    type: CommitmentWithPlanResponse,
    description: 'Em "following", o compromisso devolvido é a série nova.',
  })
  @ApiBadRequestResponse({
    description:
      'Corpo malformado, campo não previsto, scope inválido ou "following" sem fromDate.',
  })
  @ApiNotFoundResponse({
    description: 'Compromisso inexistente ou de outro usuário.',
  })
  @ApiUnprocessableEntityResponse({
    description: 'Regra do compromisso violada.',
  })
  async update(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) commitmentId: string,
    @Body() body: UpdateCommitmentBody,
  ): Promise<CommitmentWithPlanResponse> {
    const { commitment, plan } = await this.updateCommitment.execute({
      userId,
      commitmentId,
      scope: body.scope,
      fromDate: body.fromDate,
      title: body.title,
      category: body.category,
      startDate: body.startDate,
      startMinute: body.startMinute,
      endMinute: body.endMinute,
      recurrence: toRecurrence(body.recurrence),
    });
    return { commitment: toCommitmentView(commitment), plan };
  }

  @Delete(':id')
  @ApiOkResponse({ type: CommitmentPlanResponse })
  @ApiBadRequestResponse({
    description: 'scope inválido ou "following" sem fromDate YYYY-MM-DD.',
  })
  @ApiNotFoundResponse({
    description: 'Compromisso inexistente ou de outro usuário.',
  })
  async remove(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) commitmentId: string,
    @Query() query: DeleteCommitmentQuery,
  ): Promise<CommitmentPlanResponse> {
    return this.deleteCommitment.execute({
      userId,
      commitmentId,
      scope: query.scope,
      fromDate: query.fromDate,
    });
  }

  @Put(':id/occurrences/:date')
  @ApiOkResponse({ type: CommitmentWithPlanResponse })
  @ApiBadRequestResponse({
    description:
      'Corpo malformado, campo não previsto ou data fora do formato.',
  })
  @ApiNotFoundResponse({
    description: 'Compromisso inexistente ou de outro usuário.',
  })
  @ApiUnprocessableEntityResponse({
    description:
      'A data não é ocorrência da série, ou "moved" sem novo dia e horário válidos.',
  })
  async setOccurrence(
    @CurrentUser('id') userId: string,
    @Param() params: CommitmentOccurrenceParams,
    @Body() body: SetOccurrenceBody,
  ): Promise<CommitmentWithPlanResponse> {
    const { commitment, plan } = await this.occurrence.set({
      userId,
      commitmentId: params.id,
      date: params.date,
      type: body.status,
      newDate: body.newDate,
      startMinute: body.startMinute,
      endMinute: body.endMinute,
    });
    return { commitment: toCommitmentView(commitment), plan };
  }

  @Delete(':id/occurrences/:date')
  @ApiOkResponse({ type: CommitmentWithPlanResponse })
  @ApiBadRequestResponse({ description: 'id ou data fora do formato.' })
  @ApiNotFoundResponse({
    description:
      'Compromisso inexistente, de outro usuário ou sem exceção na data.',
  })
  async clearOccurrence(
    @CurrentUser('id') userId: string,
    @Param() params: CommitmentOccurrenceParams,
  ): Promise<CommitmentWithPlanResponse> {
    const { commitment, plan } = await this.occurrence.clear({
      userId,
      commitmentId: params.id,
      date: params.date,
    });
    return { commitment: toCommitmentView(commitment), plan };
  }
}
