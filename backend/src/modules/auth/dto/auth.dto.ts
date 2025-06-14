import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
    @ApiProperty({ description: 'Admin username' })
    @IsString()
    username: string;

    @ApiProperty({ description: 'Admin password' })
    @IsString()
    password: string;
}