import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Question } from '../../entities/question.entity';
import { QuizSession } from '../../entities/quiz-session.entity';
import { UserResponse } from '../../entities/user-response.entity';
import { SubmitAnswerDto, CompleteQuizDto } from './dto/quiz.dto';

@Injectable()
export class QuizService {
    constructor(
        @InjectRepository(Question)
        private questionRepository: Repository<Question>,
        @InjectRepository(QuizSession)
        private sessionRepository: Repository<QuizSession>,
        @InjectRepository(UserResponse)
        private responseRepository: Repository<UserResponse>,
    ) {}

    async getActiveQuestions() {
        return this.questionRepository.find({
            where: { isActive: true },
            order: { orderNumber: 'ASC' },
            select: ['id', 'text', 'type', 'options', 'required'],
        });
    }

    async startQuiz() {
        const questions = await this.getActiveQuestions();
        const sessionId = uuidv4();

        // Create new session
        const session = this.sessionRepository.create({
            id: sessionId,
            isCompleted: false,
        });
        await this.sessionRepository.save(session);

        return {
            sessionId,
            questions,
            totalQuestions: questions.length,
        };
    }

    async submitAnswer(submitAnswerDto: SubmitAnswerDto) {
        const { sessionId, questionId, answer } = submitAnswerDto;

        // Check if session exists
        const session = await this.sessionRepository.findOne({
            where: { id: sessionId },
        });
        if (!session) {
            throw new NotFoundException('Quiz session not found');
        }

        if (session.isCompleted) {
            throw new BadRequestException('Quiz session is already completed');
        }

        // Check if question exists
        const question = await this.questionRepository.findOne({
            where: { id: questionId, isActive: true },
        });
        if (!question) {
            throw new NotFoundException('Question not found');
        }

        // Save or update response
        const existingResponse = await this.responseRepository.findOne({
            where: { sessionId, questionId },
        });

        const answerText = Array.isArray(answer) ? JSON.stringify(answer) : answer;

        if (existingResponse) {
            existingResponse.answerText = answerText;
            await this.responseRepository.save(existingResponse);
        } else {
            const response = this.responseRepository.create({
                sessionId,
                questionId,
                answerText,
            });
            await this.responseRepository.save(response);
        }

        return { success: true, message: 'Answer saved successfully' };
    }

    async completeQuiz(completeQuizDto: CompleteQuizDto) {
        const { sessionId, name } = completeQuizDto;

        const session = await this.sessionRepository.findOne({
            where: { id: sessionId },
            relations: ['responses'],
        });

        if (!session) {
            throw new NotFoundException('Quiz session not found');
        }

        // Update session
        session.isCompleted = true;
        session.completedAt = new Date();
        if (name && name.trim()) {
            session.userName = name.trim();
        }

        await this.sessionRepository.save(session);

        return {
            success: true,
            message: 'Quiz completed successfully',
            totalAnswers: session.responses?.length || 0,
        };
    }

    async getSession(sessionId: string) {
        const session = await this.sessionRepository.findOne({
            where: { id: sessionId },
            relations: ['responses', 'responses.question'],
        });

        if (!session) {
            throw new NotFoundException('Session not found');
        }

        const totalQuestions = await this.questionRepository.count({
            where: { isActive: true },
        });

        return {
            sessionId: session.id,
            isCompleted: session.isCompleted,
            completedAt: session.completedAt,
            userName: session.userName,
            totalQuestions,
            answeredQuestions: session.responses?.length || 0,
            responses: session.responses?.map(r => ({
                questionId: r.questionId,
                questionText: r.question?.text,
                answer: r.answerText,
                answeredAt: r.createdAt,
            })) || [],
        };
    }
}