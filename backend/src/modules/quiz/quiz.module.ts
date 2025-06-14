import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuizController } from './quiz.controller';
import { QuizService } from './quiz.service';
import { Question } from '../../entities/question.entity';
import { QuizSession } from '../../entities/quiz-session.entity';
import { UserResponse } from '../../entities/user-response.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Question, QuizSession, UserResponse])],
    controllers: [QuizController],
    providers: [QuizService],
})
export class QuizModule {}