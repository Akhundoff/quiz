import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {MoreThanOrEqual, Repository} from 'typeorm';
import { Question } from '../../entities/question.entity';
import { QuizSession } from '../../entities/quiz-session.entity';
import { UserResponse } from '../../entities/user-response.entity';
import { CreateQuestionDto, UpdateQuestionDto } from './dto/admin.dto';

@Injectable()
export class AdminService {
    constructor(
        @InjectRepository(Question)
        private questionRepository: Repository<Question>,
        @InjectRepository(QuizSession)
        private sessionRepository: Repository<QuizSession>,
        @InjectRepository(UserResponse)
        private responseRepository: Repository<UserResponse>,
    ) {}

    async getAllQuestions() {
        return this.questionRepository.find({
            order: { orderNumber: 'ASC' },
        });
    }

    async createQuestion(createQuestionDto: CreateQuestionDto) {
        // Get the next order number
        const maxOrder = await this.questionRepository
            .createQueryBuilder('question')
            .select('MAX(question.orderNumber)', 'max')
            .getRawOne();

        const orderNumber = (maxOrder?.max || 0) + 1;

        const question = this.questionRepository.create({
            ...createQuestionDto,
            orderNumber,
        });

        return this.questionRepository.save(question);
    }

    async updateQuestion(id: number, updateQuestionDto: UpdateQuestionDto) {
        const question = await this.questionRepository.findOne({ where: { id } });

        if (!question) {
            throw new NotFoundException('Question not found');
        }

        Object.assign(question, updateQuestionDto);
        return this.questionRepository.save(question);
    }

    async deleteQuestion(id: number) {
        const result = await this.questionRepository.delete(id);

        if (result.affected === 0) {
            throw new NotFoundException('Question not found');
        }

        return { success: true, message: 'Question deleted successfully' };
    }

    async getAllResponses(page: number = 1, limit: number = 50, completed?: boolean) {
        const queryBuilder = this.sessionRepository
            .createQueryBuilder('session')
            .leftJoinAndSelect('session.responses', 'response')
            .leftJoinAndSelect('response.question', 'question')
            .orderBy('session.createdAt', 'DESC');

        if (completed !== undefined) {
            queryBuilder.where('session.isCompleted = :completed', { completed });
        }

        const [sessions, total] = await queryBuilder
            .skip((page - 1) * limit)
            .take(limit)
            .getManyAndCount();

        return {
            data: sessions,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        };
    }

    async getStatistics() {
        const totalSessions = await this.sessionRepository.count();
        const completedSessions = await this.sessionRepository.count({
            where: { isCompleted: true },
        });
        const totalQuestions = await this.questionRepository.count({
            where: { isActive: true },
        });
        const totalResponses = await this.responseRepository.count();

        // Question response stats
        const questionStats = await this.questionRepository
            .createQueryBuilder('question')
            .leftJoin('question.responses', 'response')
            .select('question.id', 'questionId')
            .addSelect('question.text', 'questionText')
            .addSelect('COUNT(response.id)', 'responseCount')
            .where('question.isActive = :active', { active: true })
            .groupBy('question.id')
            .orderBy('question.orderNumber', 'ASC')
            .getRawMany();

        // Recent activity (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const recentSessions = await this.sessionRepository.count({
            where: { createdAt: MoreThanOrEqual(thirtyDaysAgo) },
        });

        return {
            totalSessions,
            completedSessions,
            incompleteSessions: totalSessions - completedSessions,
            completionRate: totalSessions > 0 ? (completedSessions / totalSessions * 100).toFixed(1) : 0,
            totalQuestions,
            totalResponses,
            averageResponsesPerSession: totalSessions > 0 ? (totalResponses / totalSessions).toFixed(1) : 0,
            recentSessions,
            questionStats: questionStats.map(stat => ({
                questionId: parseInt(stat.questionId),
                questionText: stat.questionText.substring(0, 50) + '...',
                responseCount: parseInt(stat.responseCount),
            })),
        };
    }

    async exportResponses() {
        const sessions = await this.sessionRepository.find({
            relations: ['responses', 'responses.question'],
            where: { isCompleted: true },
            order: { completedAt: 'DESC' },
        });

        const csvData = [];

        sessions.forEach(session => {
            const baseRow = {
                sessionId: session.id,
                userName: session.userName || 'Gizli şəxs',
                completedAt: session.completedAt?.toISOString(),
                totalResponses: session.responses?.length || 0,
            };

            if (session.responses && session.responses.length > 0) {
                session.responses.forEach(response => {
                    csvData.push({
                        ...baseRow,
                        questionId: response.questionId,
                        questionText: response.question?.text,
                        answer: response.answerText,
                        answeredAt: response.createdAt.toISOString(),
                    });
                });
            } else {
                csvData.push(baseRow);
            }
        });

        return csvData;
    }
}