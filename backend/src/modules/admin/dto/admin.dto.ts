import { IsString, IsEnum, IsArray, IsBoolean, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateQuestionDto {
    @ApiProperty({ description: 'Question text' })
    @IsString()
    text: string;

    @ApiProperty({ description: 'Question type', enum: ['radio', 'checkbox', 'text'] })
    @IsEnum(['radio', 'checkbox', 'text'])
    type: 'radio' | 'checkbox' | 'text';

    @ApiProperty({ description: 'Question options (for radio/checkbox)', required: false })
    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    options?: string[];

    @ApiProperty({ description: 'Is question required', default: true })
    @IsOptional()
    @IsBoolean()
    required?: boolean;

    @ApiProperty({ description: 'Is question active', default: true })
    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}

export class UpdateQuestionDto {
    @ApiProperty({ description: 'Question text', required: false })
    @IsOptional()
    @IsString()
    text?: string;

    @ApiProperty({ description: 'Question type', enum: ['radio', 'checkbox', 'text'], required: false })
    @IsOptional()
    @IsEnum(['radio', 'checkbox', 'text'])
    type?: 'radio' | 'checkbox' | 'text';

    @ApiProperty({ description: 'Question options', required: false })
    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    options?: string[];

    @ApiProperty({ description: 'Is question required', required: false })
    @IsOptional()
    @IsBoolean()
    required?: boolean;

    @ApiProperty({ description: 'Question order', required: false })
    @IsOptional()
    @IsNumber()
    orderNumber?: number;

    @ApiProperty({ description: 'Is question active', required: false })
    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}