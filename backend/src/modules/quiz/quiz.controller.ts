import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { QuizService } from './quiz.service';
import { StartQuizDto, SubmitAnswerDto, CompleteQuizDto } from './dto/quiz.dto';

@ApiTags('Quiz')
@Controller('quiz')
export class QuizController {
    constructor(private readonly quizService: QuizService) {}

    @Get('questions')
    @ApiOperation({ summary: 'Get all active questions' })
    async getQuestions() {
        return this.quizService.getActiveQuestions();
    }

    @Post('start')
    @ApiOperation({ summary: 'Start a new quiz session' })
    @ApiResponse({ status: 201, description: 'Quiz session started successfully' })
    async startQuiz(@Body() startQuizDto: StartQuizDto) {
        return this.quizService.startQuiz();
    }

    @Post('answer')
    @ApiOperation({ summary: 'Submit an answer' })
    async submitAnswer(@Body() submitAnswerDto: SubmitAnswerDto) {
        return this.quizService.submitAnswer(submitAnswerDto);
    }

    @Post('complete')
    @ApiOperation({ summary: 'Complete the quiz' })
    async completeQuiz(@Body() completeQuizDto: CompleteQuizDto) {
        return this.quizService.completeQuiz(completeQuizDto);
    }

    @Get('session/:id')
    @ApiOperation({ summary: 'Get session progress' })
    async getSession(@Param('id') sessionId: string) {
        return this.quizService.getSession(sessionId);
    }
}