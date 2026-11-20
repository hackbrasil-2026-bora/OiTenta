import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import {
  GetCommitment,
  GetWeeklyAvailability,
  ListCommitmentOccurrences,
} from '@oitenta/scheduling';
import { JwtAuthGuard } from '../../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../../shared/decorators/current-user.decorator';
import {
  CommitmentOccurrencesQuery,
  CommitmentOccurrencesResponse,
  CommitmentResponse,
  toCommitmentView,
  toOccurrencesResponse,
} from './commitment.dto';
import { PrismaCommitmentRepository } from './commitment.prisma';
import {
  toAvailabilityResponse,
  WeeklyAvailabilityResponse,
} from './scheduling.dto';
import { PrismaWeeklyAvailabilityRepository } from './weekly-availability.prisma';

@ApiTags('scheduling')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@ApiUnauthorizedResponse({
  description: 'Token ausente, inválido ou expirado.',
})
// O PUT /scheduling/availability e as escritas dos compromissos moram nos orquestradores
// (set-availability e commitment-*), porque devolvem o plano recalculado (C4, §5b).
@Controller('scheduling')
export class SchedulingController {
  constructor(
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly commitmentRepository: PrismaCommitmentRepository,
  ) {}

  @Get('availability')
  @ApiOkResponse({ type: WeeklyAvailabilityResponse })
  @ApiNotFoundResponse({ description: 'O usuário ainda não fez o onboarding.' })
  async getAvailability(
    @CurrentUser('id') userId: string,
  ): Promise<WeeklyAvailabilityResponse> {
    const useCase = new GetWeeklyAvailability(this.availabilityRepository);
    const { availability } = await useCase.execute({ userId });
    return toAvailabilityResponse(availability);
  }

  // Declarada antes de commitments/:id para "occurrences" não ser lido como id (MC4).
  @Get('commitments/occurrences')
  @ApiOkResponse({ type: CommitmentOccurrencesResponse })
  @ApiBadRequestResponse({
    description: 'from ou to fora do formato YYYY-MM-DD.',
  })
  @ApiUnprocessableEntityResponse({
    description:
      'Data inexistente, to antes de from ou mais de 62 dias (occurrences.range).',
  })
  async listOccurrences(
    @CurrentUser('id') userId: string,
    @Query() query: CommitmentOccurrencesQuery,
  ): Promise<CommitmentOccurrencesResponse> {
    const { occurrences } = await new ListCommitmentOccurrences(
      this.commitmentRepository,
    ).execute({ userId, from: query.from, to: query.to });
    return toOccurrencesResponse(occurrences);
  }

  @Get('commitments/:id')
  @ApiOkResponse({ type: CommitmentResponse })
  @ApiBadRequestResponse({ description: 'id não é um UUID.' })
  @ApiNotFoundResponse({
    description: 'Compromisso inexistente ou de outro usuário.',
  })
  async getCommitment(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) commitmentId: string,
  ): Promise<CommitmentResponse> {
    const { commitment } = await new GetCommitment(
      this.commitmentRepository,
    ).execute({ userId, commitmentId });
    return { commitment: toCommitmentView(commitment) };
  }
}
