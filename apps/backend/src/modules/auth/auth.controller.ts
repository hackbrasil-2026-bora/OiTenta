import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import {
  GetAuthenticatedUser,
  LoginDemoUser,
  LoginUser,
  RegisterUser,
  UpdateProfile,
} from '@oitenta/auth';
import { JwtAuthGuard } from '../../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../../shared/decorators/current-user.decorator';
import {
  LoginResponse,
  LoginUserBody,
  RegisterUserBody,
  UpdateProfileBody,
  UserResponse,
} from './auth.dto';
import { BcryptCryptoProvider } from './bcrypt-crypto.provider';
import { JwtTokenProvider } from './jwt-token.provider';
import { PrismaUserRepository } from './user.prisma';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly cryptoProvider: BcryptCryptoProvider,
    private readonly tokenProvider: JwtTokenProvider,
    private readonly config: ConfigService,
  ) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiCreatedResponse({ type: UserResponse })
  @ApiConflictResponse({ description: 'E-mail já cadastrado.' })
  async register(@Body() body: RegisterUserBody) {
    const useCase = new RegisterUser(this.cryptoProvider, this.userRepository);
    return await useCase.execute(body);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: LoginResponse })
  @ApiUnauthorizedResponse({ description: 'Credenciais inválidas.' })
  async login(@Body() body: LoginUserBody) {
    const useCase = new LoginUser(
      this.cryptoProvider,
      this.tokenProvider,
      this.userRepository,
    );
    return await useCase.execute(body);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: UserResponse })
  @ApiUnauthorizedResponse({
    description: 'Token ausente, inválido ou expirado.',
  })
  async me(@CurrentUser('id') userId: string) {
    const useCase = new GetAuthenticatedUser(this.userRepository);
    return await useCase.execute({ userId });
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: UserResponse })
  @ApiUnauthorizedResponse({
    description: 'Token ausente, inválido ou expirado.',
  })
  @ApiForbiddenResponse({
    description: 'Troca de e-mail sem a senha atual ou com a senha errada.',
  })
  @ApiConflictResponse({ description: 'E-mail já cadastrado.' })
  async updateMe(
    @CurrentUser('id') userId: string,
    @Body() body: UpdateProfileBody,
  ) {
    const useCase = new UpdateProfile(this.cryptoProvider, this.userRepository);
    return await useCase.execute({ ...body, userId });
  }

  @Post('demo')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: LoginResponse })
  @ApiNotFoundResponse({ description: 'Usuário demo ainda não semeado.' })
  async demo() {
    const useCase = new LoginDemoUser(this.tokenProvider, this.userRepository);
    return await useCase.execute({
      demoEmail: this.config.get<string>('DEMO_EMAIL') ?? '',
    });
  }
}
