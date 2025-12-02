import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';

import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt.guard';
import { CurrentUser } from './auth.decorator';

class LoginDto {
  @IsNotEmpty()
  tenant!: string;

  @IsEmail()
  email!: string;

  @MinLength(6)
  password!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: unknown) {
    return user;
  }
}
