import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { RoomStatus } from '@prisma/client';

import { JwtAuthGuard } from '../../auth/jwt.guard';
import { RolesGuard } from '../../auth/roles.guard';
import { Roles } from '../../auth/auth.guard';
import { TenantGuard } from '../../tenancy/tenant.guard';
import { RoomsService } from './rooms.service';

class CreateRoomDto {
  @IsString()
  @IsNotEmpty()
  number!: string;

  @IsString()
  @IsOptional()
  type?: string;

  @IsString()
  @IsOptional()
  floor?: string;

  @IsEnum(RoomStatus)
  @IsOptional()
  status?: RoomStatus = RoomStatus.AVAILABLE;
}

@Controller('rooms')
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
export class RoomsController {
  constructor(private readonly rooms: RoomsService) {}

  @Get()
  list() {
    return this.rooms.list();
  }

  @Post()
  @Roles('ADMIN', 'MANAGER')
  create(@Body() dto: CreateRoomDto) {
    return this.rooms.create({
      number: dto.number,
      type: dto.type,
      floor: dto.floor,
      status: dto.status,
    });
  }

  @Patch(':id/status')
  @Roles('ADMIN', 'MANAGER')
  updateStatus(
    @Param('id') id: string,
    @Body() body: { status: RoomStatus },
  ) {
    return this.rooms.updateStatus(id, body.status);
  }
}
