import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { ReservationStatus } from '@prisma/client';

import { JwtAuthGuard } from '../../auth/jwt.guard';
import { RolesGuard } from '../../auth/roles.guard';
import { Roles } from '../../auth/auth.guard';
import { TenantGuard } from '../../tenancy/tenant.guard';
import { ReservationsService } from './reservations.service';

class CreateReservationDto {
  @IsString()
  @IsNotEmpty()
  guestName!: string;

  @IsDateString()
  checkIn!: string;

  @IsDateString()
  checkOut!: string;

  @IsString()
  @IsOptional()
  roomId?: string;

  @IsEnum(ReservationStatus)
  @IsOptional()
  status?: ReservationStatus = ReservationStatus.CONFIRMED;

  @IsNumber()
  @IsOptional()
  amount?: number;

  @IsNumber()
  @IsOptional()
  deposit?: number;

  @IsString()
  @IsOptional()
  source?: string;
}

@Controller('reservations')
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
export class ReservationsController {
  constructor(private readonly reservations: ReservationsService) {}

  @Get()
  list() {
    return this.reservations.list();
  }

  @Post()
  @Roles('ADMIN', 'MANAGER', 'STAFF')
  create(@Body() dto: CreateReservationDto) {
    return this.reservations.create({
      guestName: dto.guestName,
      checkIn: new Date(dto.checkIn),
      checkOut: new Date(dto.checkOut),
      status: dto.status,
      amount: dto.amount,
      deposit: dto.deposit,
      source: dto.source,
      room: dto.roomId ? { connect: { id: dto.roomId } } : undefined,
    });
  }

  @Patch(':id/status')
  @Roles('ADMIN', 'MANAGER', 'STAFF')
  updateStatus(
    @Param('id') id: string,
    @Body() body: { status: ReservationStatus },
  ) {
    return this.reservations.updateStatus(id, body.status);
  }
}
