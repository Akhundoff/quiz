import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Question } from '../../entities/question.entity';
import { QuizSession } from '../../entities/quiz-session.entity';
import { UserResponse } from '../../entities/user-response.entity';
import { AdminUser } from '../../entities/admin-user.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Question, QuizSession, UserResponse, AdminUser])],
    controllers: [AdminController],
    providers: [AdminService],
})
export class AdminModule {}