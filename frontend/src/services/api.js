import axios from 'axios';

// Environment-based API URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001/api';

// Public API (for quiz)
export const quizAPI = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Admin API (with auth)
export const authAPI = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Add auth token from localStorage
const token = localStorage.getItem('adminToken');
if (token) {
    authAPI.defaults.headers.common['Authorization'] = `Bearer ${token}`;
}

// Quiz API methods - DƏYIŞIKLIK YOX
export const quizService = {
    async startQuiz() {
        const response = await quizAPI.post('/quiz/start');
        return response.data;
    },

    async submitAnswer(sessionId, questionId, answer) {
        const response = await quizAPI.post('/quiz/answer', {
            sessionId,
            questionId,
            answer,
        });
        return response.data;
    },

    async completeQuiz(sessionId, name) {
        const response = await quizAPI.post('/quiz/complete', {
            sessionId,
            name,
        });
        return response.data;
    },

    async getSession(sessionId) {
        const response = await quizAPI.get(`/quiz/session/${sessionId}`);
        return response.data;
    },
};

// Admin API methods - DƏYIŞIKLIK YOX
export const adminService = {
    async getQuestions() {
        const response = await authAPI.get('/admin/questions');
        return response.data;
    },

    async createQuestion(questionData) {
        const response = await authAPI.post('/admin/questions', questionData);
        return response.data;
    },

    async updateQuestion(id, questionData) {
        const response = await authAPI.put(`/admin/questions/${id}`, questionData);
        return response.data;
    },

    async deleteQuestion(id) {
        const response = await authAPI.delete(`/admin/questions/${id}`);
        return response.data;
    },

    async getResponses(page = 1, limit = 50, completed) {
        const params = { page, limit };
        if (completed !== undefined) params.completed = completed;

        const response = await authAPI.get('/admin/responses', { params });
        return response.data;
    },

    async getStatistics() {
        const response = await authAPI.get('/admin/statistics');
        return response.data;
    },

    async exportResponses() {
        const response = await authAPI.get('/admin/responses/export');
        return response.data;
    },
};