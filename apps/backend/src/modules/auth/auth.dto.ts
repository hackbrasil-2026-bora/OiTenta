import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import type {
  LoginUserIn,
  LoginUserOut,
  PublicUser,
  RegisterUserIn,
  RegisterUserOut,
  UpdateProfileIn,
} from '@oitenta/auth';

// Classes para o Swagger enxergar o contrato; o tipo real é a interface do caso de uso.
// Os decorators do class-validator checam só o formato (400, P19); a regra de domínio
// (e-mail válido, senha forte, fuso IANA) continua no caso de uso (422).

export class RegisterUserBody implements RegisterUserIn {
  @ApiProperty({ example: 'Ana Souza' })
  @IsString()
  name!: string;

  @ApiProperty({ example: 'ana@bora.app' })
  @IsString()
  email!: string;

  @ApiProperty({
    example: 'Senha@123',
    description:
      'Mínimo 8 caracteres, com maiúscula, minúscula, número e símbolo.',
  })
  @IsString()
  password!: string;

  @ApiPropertyOptional({
    example: 'America/Sao_Paulo',
    description: 'Fuso IANA do usuário. Padrão: America/Sao_Paulo.',
  })
  @IsOptional()
  @IsString()
  timezone?: string;
}

export class LoginUserBody implements LoginUserIn {
  @ApiProperty({ example: 'ana@bora.app' })
  @IsString()
  email!: string;

  @ApiProperty({ example: 'Senha@123' })
  @IsString()
  password!: string;
}

/** Corpo do PATCH /auth/me (AT3). O dono vem do token, nunca do corpo. */
export class UpdateProfileBody implements Omit<UpdateProfileIn, 'userId'> {
  @ApiPropertyOptional({ example: 'Ana Clara' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'ana.clara@bora.app' })
  @IsOptional()
  @IsString()
  email?: string;

  @ApiPropertyOptional({
    example: 'Senha@123',
    description: 'Obrigatória quando o e-mail muda; errada → 403.',
  })
  @IsOptional()
  @IsString()
  currentPassword?: string;
}

/** Corpo do PATCH /auth/me/password (AT9). */
export class ChangePasswordBody {
  @ApiProperty({ example: 'Senha@123' })
  @IsString()
  currentPassword!: string;

  @ApiProperty({
    example: 'Nova@4567',
    description:
      'Mínimo 8 caracteres, com maiúscula, minúscula, número e símbolo.',
  })
  @IsString()
  newPassword!: string;
}

/** Corpo do DELETE /auth/me (AT9): confirma com a senha atual. */
export class DeleteAccountBody {
  @ApiProperty({ example: 'Senha@123' })
  @IsString()
  currentPassword!: string;
}

export class PublicUserResponse implements PublicUser {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  email!: string;

  @ApiProperty({ example: 'America/Sao_Paulo' })
  timezone!: string;
}

export class UserResponse implements RegisterUserOut {
  @ApiProperty({ type: PublicUserResponse })
  user!: PublicUserResponse;
}

export class LoginResponse implements LoginUserOut {
  @ApiProperty({
    description: 'JWT. Envie como Authorization: Bearer <token>.',
  })
  token!: string;

  @ApiProperty({ type: PublicUserResponse })
  user!: PublicUserResponse;
}
