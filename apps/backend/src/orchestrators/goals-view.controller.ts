import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
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
import { JwtAuthGuard } from '../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../shared/decorators/current-user.decorator';
import { CreateGoalOrchestrator } from './create-goal.orchestrator';
import { GoalDeleteOrchestrator } from './goal-delete.orchestrator';
import {
  CreateGoalBody,
  CreateGoalResponse,
  GoalDeleteResponse,
  GoalDetailResponse,
  GoalListQuery,
  GoalListResponse,
  SingleTaskDoneBody,
  SingleTaskDoneResponse,
} from './goals-view.dto';
import { GoalsViewOrchestrator } from './goals-view.orchestrator';
import { SingleTaskDoneOrchestrator } from './single-task-done.orchestrator';

@ApiTags('goals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@ApiUnauthorizedResponse({
  description: 'Token ausente, inválido ou expirado.',
})
@Controller('goals')
export class GoalsViewController {
  constructor(
    private readonly createGoal: CreateGoalOrchestrator,
    private readonly goalsView: GoalsViewOrchestrator,
    private readonly singleTaskDone: SingleTaskDoneOrchestrator,
    private readonly goalDelete: GoalDeleteOrchestrator,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiCreatedResponse({ type: CreateGoalResponse })
  @ApiBadRequestResponse({
    description: 'Corpo malformado ou campo não previsto.',
  })
  @ApiNotFoundResponse({ description: 'Sem disponibilidade cadastrada (P12).' })
  @ApiUnprocessableEntityResponse({
    description:
      'Título vazio, zero etapas, estimativa inválida ou plannedDate com kind "goal".',
  })
  async create(
    @CurrentUser('id') userId: string,
    @Body() body: CreateGoalBody,
  ): Promise<CreateGoalResponse> {
    return this.createGoal.execute({
      userId,
      title: body.title,
      deadline: body.deadline ?? null,
      plannedDate: body.plannedDate ?? null,
      kind: body.kind,
      source: body.source,
      steps: body.steps.map((step) => ({
        title: step.title,
        estimatedMinutes: step.estimatedMinutes,
        aiEstimatedMinutes: step.aiEstimatedMinutes,
        microSteps: step.microSteps,
      })),
    });
  }

  @Get()
  @ApiOkResponse({ type: GoalListResponse })
  @ApiBadRequestResponse({ description: 'kind diferente de goal ou single.' })
  async list(
    @CurrentUser('id') userId: string,
    @Query() query: GoalListQuery,
  ): Promise<GoalListResponse> {
    return this.goalsView.list(userId, query.kind);
  }

  @Get(':goalId')
  @ApiOkResponse({ type: GoalDetailResponse })
  @ApiBadRequestResponse({ description: 'goalId não é um UUID.' })
  @ApiNotFoundResponse({
    description: 'Objetivo inexistente ou de outro usuário.',
  })
  async detail(
    @CurrentUser('id') userId: string,
    @Param('goalId', ParseUUIDPipe) goalId: string,
  ): Promise<GoalDetailResponse> {
    return this.goalsView.detail(userId, goalId);
  }

  @Patch(':goalId/done')
  @ApiOkResponse({ type: SingleTaskDoneResponse })
  @ApiBadRequestResponse({
    description: 'goalId não é um UUID, done não é booleano ou campo a mais.',
  })
  @ApiNotFoundResponse({
    description: 'Tarefa inexistente ou de outro usuário.',
  })
  @ApiUnprocessableEntityResponse({
    description: 'O objetivo não é uma tarefa única (goal.kind.single).',
  })
  async setDone(
    @CurrentUser('id') userId: string,
    @Param('goalId', ParseUUIDPipe) goalId: string,
    @Body() body: SingleTaskDoneBody,
  ): Promise<SingleTaskDoneResponse> {
    return this.singleTaskDone.execute({ userId, goalId, done: body.done });
  }

  @Delete(':goalId')
  @ApiOkResponse({ type: GoalDeleteResponse })
  @ApiBadRequestResponse({ description: 'goalId não é um UUID.' })
  @ApiNotFoundResponse({
    description: 'Objetivo inexistente ou de outro usuário.',
  })
  async remove(
    @CurrentUser('id') userId: string,
    @Param('goalId', ParseUUIDPipe) goalId: string,
  ): Promise<GoalDeleteResponse> {
    return this.goalDelete.execute({ userId, goalId });
  }
}
