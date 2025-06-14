import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateQuestionDto, UpdateQuestionDto } from './dto/admin.dto';

@ApiTags('Admin')
@Controller('admin')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AdminController {
    constructor(private readonly adminService: AdminService) {}

    @Get('questions')
    @ApiOperation({ summary: 'Get all questions (admin)' })
    async getAllQuestions() {
        return this.adminService.getAllQuestions();
    }

    @Post('questions')
    @ApiOperation({ summary: 'Create new question' })
    async createQuestion(@Body() createQuestionDto: CreateQuestionDto) {
        return this.adminService.createQuestion(createQuestionDto);
    }

    @Put('questions/:id')
    @ApiOperation({ summary: 'Update question' })
    async updateQuestion(
        @Param('id') id: number,
        @Body() updateQuestionDto: UpdateQuestionDto,
    ) {
        return this.adminService.updateQuestion(id, updateQuestionDto);
    }

    @Delete('questions/:id')
    @ApiOperation({ summary: 'Delete question' })
    async deleteQuestion(@Param('id') id: number) {
        return this.adminService.deleteQuestion(id);
    }

    @Get('responses')
    @ApiOperation({ summary: 'Get all quiz responses' })
    async getAllResponses(
        @Query('page') page: number = 1,
        @Query('limit') limit: number = 50,
        @Query('completed') completed?: boolean,
    ) {
        return this.adminService.getAllResponses(page, limit, completed);
    }

    @Get('statistics')
    @ApiOperation({ summary: 'Get quiz statistics' })
    async getStatistics() {
        return this.adminService.getStatistics();
    }

    @Get('responses/export')
    @ApiOperation({ summary: 'Export responses as CSV' })
    async exportResponses() {
        return this.adminService.exportResponses();
    }
}
