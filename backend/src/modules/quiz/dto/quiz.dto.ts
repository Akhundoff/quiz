import { IsString, IsNumber, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class StartQuizDto {
    // No fields needed for starting quiz
}

export class SubmitAnswerDto {
    @ApiProperty({ description: 'Quiz session ID' })
    @IsUUID()
    sessionId: string;

    @ApiProperty({ description: 'Question ID' })
    @IsNumber()
    questionId: number;

    @ApiProperty({ description: 'User answer' })
    @IsString()
    answer: string;
}

export class CompleteQuizDto {
    @ApiProperty({ description: 'Quiz session ID' })
    @IsUUID()
    sessionId: string;

    @ApiProperty({ description: 'User name (optional)', required: false })
    @IsOptional()
    @IsString()
    name?: string;
}