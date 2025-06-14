import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    LogOut, Plus, Edit, Trash2, BarChart3, Users,
    FileText, Download, Eye, Settings
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../contexts/AuthContext';
import { adminService } from '../services/api';
import QuestionModal from '../components/Admin/QuestionModal';
import ResponsesTable from '../components/Admin/ResponsesTable';
import Statistics from '../components/Admin/Statistics';

const AdminDashboard = () => {
    const [activeTab, setActiveTab] = useState('dashboard');
    const [questions, setQuestions] = useState([]);
    const [responses, setResponses] = useState([]);
    const [statistics, setStatistics] = useState(null);
    const [loading, setLoading] = useState(false);
    const [showQuestionModal, setShowQuestionModal] = useState(false);
    const [editingQuestion, setEditingQuestion] = useState(null);

    const { logout, user, isAuthenticated } = useAuth();
    const navigate = useNavigate();

    useEffect(() => {
        if (!isAuthenticated) {
            navigate('/admin');
        }
    }, [isAuthenticated, navigate]);

    useEffect(() => {
        if (activeTab === 'questions') {
            loadQuestions();
        } else if (activeTab === 'responses') {
            loadResponses();
        } else if (activeTab === 'dashboard') {
            loadStatistics();
        }
    }, [activeTab]);

    const loadQuestions = async () => {
        setLoading(true);
        try {
            const data = await adminService.getQuestions();
            setQuestions(data);
        } catch (error) {
            toast.error('Suallar yüklənə bilmədi');
        } finally {
            setLoading(false);
        }
    };

    const loadResponses = async () => {
        setLoading(true);
        try {
            const data = await adminService.getResponses();
            setResponses(data);
        } catch (error) {
            toast.error('Cavablar yüklənə bilmədi');
        } finally {
            setLoading(false);
        }
    };

    const loadStatistics = async () => {
        setLoading(true);
        try {
            const data = await adminService.getStatistics();
            setStatistics(data);
        } catch (error) {
            toast.error('Statistika yüklənə bilmədi');
        } finally {
            setLoading(false);
        }
    };

    const handleDeleteQuestion = async (id) => {
        if (!window.confirm('Bu sualı silmək istədiyinizdən əminsiniz?')) return;

        try {
            await adminService.deleteQuestion(id);
            toast.success('Sual uğurla silindi');
            loadQuestions();
        } catch (error) {
            toast.error('Sual silinə bilmədi');
        }
    };

    const handleQuestionSaved = () => {
        setShowQuestionModal(false);
        setEditingQuestion(null);
        loadQuestions();
        toast.success('Sual uğurla saxlanıldı');
    };

    const exportResponses = async () => {
        try {
            const data = await adminService.exportResponses();
            const csvContent = convertToCSV(data);
            downloadCSV(csvContent, 'quiz-responses.csv');
            toast.success('Məlumatlar yükləndi');
        } catch (error) {
            toast.error('Export zamanı xəta baş verdi');
        }
    };

    const convertToCSV = (data) => {
        if (!data.length) return '';

        const headers = Object.keys(data[0]).join(',');
        const rows = data.map(row =>
            Object.values(row).map(value =>
                `"${String(value).replace(/"/g, '""')}"`
            ).join(',')
        );

        return [headers, ...rows].join('\n');
    };

    const downloadCSV = (csvContent, filename) => {
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        if (link.download !== undefined) {
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', filename);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    };

    const tabs = [
        { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
        { id: 'questions', label: 'Suallar', icon: FileText },
        { id: 'responses', label: 'Cavablar', icon: Users },
    ];

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white shadow-sm border-b">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between items-center h-16">
                        <h1 className="text-xl font-semibold text-gray-900">
                            Quiz Admin Panel
                        </h1>
                        <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">
                Xoş gəlmisiniz, {user?.username}
              </span>
                            <button
                                onClick={logout}
                                className="flex items-center text-gray-600 hover:text-red-600 transition-colors"
                            >
                                <LogOut className="w-4 h-4 mr-1" />
                                Çıxış
                            </button>
                        </div>
                    </div>
                </div>
            </header>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="flex space-x-8">
                    {/* Sidebar */}
                    <div className="w-64 flex-shrink-0">
                        <nav className="bg-white rounded-lg shadow-sm p-4">
                            <ul className="space-y-2">
                                {tabs.map((tab) => {
                                    const Icon = tab.icon;
                                    return (
                                        <li key={tab.id}>
                                            <button
                                                onClick={() => setActiveTab(tab.id)}
                                                className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                                                    activeTab === tab.id
                                                        ? 'bg-blue-100 text-blue-700'
                                                        : 'text-gray-600 hover:bg-gray-100'
                                                }`}
                                            >
                                                <Icon className="w-4 h-4 mr-3" />
                                                {tab.label}
                                            </button>
                                        </li>
                                    );
                                })}
                            </ul>
                        </nav>
                    </div>

                    {/* Main Content */}
                    <div className="flex-1">
                        {activeTab === 'dashboard' && (
                            <Statistics statistics={statistics} loading={loading} />
                        )}

                        {activeTab === 'questions' && (
                            <div className="bg-white rounded-lg shadow-sm">
                                <div className="p-6 border-b border-gray-200">
                                    <div className="flex justify-between items-center">
                                        <h2 className="text-lg font-medium text-gray-900">Sual İdarəetməsi</h2>
                                        <button
                                            onClick={() => setShowQuestionModal(true)}
                                            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                                        >
                                            <Plus className="w-4 h-4 mr-2" />
                                            Yeni Sual
                                        </button>
                                    </div>
                                </div>

                                <div className="p-6">
                                    {loading ? (
                                        <div className="text-center py-12">
                                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                                            <p className="text-gray-600 mt-2">Yüklənir...</p>
                                        </div>
                                    ) : (
                                        <div className="space-y-4">
                                            {questions.map((question) => (
                                                <div key={question.id} className="border border-gray-200 rounded-lg p-4">
                                                    <div className="flex justify-between items-start">
                                                        <div className="flex-1">
                                                            <h3 className="font-medium text-gray-900 mb-2">
                                                                {question.text}
                                                            </h3>
                                                            <div className="flex items-center space-x-4 text-sm text-gray-600">
                                <span className="bg-gray-100 px-2 py-1 rounded">
                                  {question.type}
                                </span>
                                                                <span>Sıra: {question.orderNumber}</span>
                                                                <span className={question.isActive ? 'text-green-600' : 'text-red-600'}>
                                  {question.isActive ? 'Aktiv' : 'Deaktiv'}
                                </span>
                                                            </div>
                                                            {question.options && (
                                                                <div className="mt-2">
                                                                    <p className="text-sm text-gray-600">Variantlar:</p>
                                                                    <ul className="text-sm text-gray-700 ml-4">
                                                                        {question.options.map((option, index) => (
                                                                            <li key={index}>• {option}</li>
                                                                        ))}
                                                                    </ul>
                                                                </div>
                                                            )}
                                                        </div>
                                                        <div className="flex space-x-2 ml-4">
                                                            <button
                                                                onClick={() => {
                                                                    setEditingQuestion(question);
                                                                    setShowQuestionModal(true);
                                                                }}
                                                                className="p-2 text-blue-600 hover:bg-blue-100 rounded"
                                                            >
                                                                <Edit className="w-4 h-4" />
                                                            </button>
                                                            <button
                                                                onClick={() => handleDeleteQuestion(question.id)}
                                                                className="p-2 text-red-600 hover:bg-red-100 rounded"
                                                            >
                                                                <Trash2 className="w-4 h-4" />
                                                            </button>
                                                        </div>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}

                        {activeTab === 'responses' && (
                            <div className="bg-white rounded-lg shadow-sm">
                                <div className="p-6 border-b border-gray-200">
                                    <div className="flex justify-between items-center">
                                        <h2 className="text-lg font-medium text-gray-900">Cavablar</h2>
                                        <button
                                            onClick={exportResponses}
                                            className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                                        >
                                            <Download className="w-4 h-4 mr-2" />
                                            Export CSV
                                        </button>
                                    </div>
                                </div>

                                <ResponsesTable responses={responses} loading={loading} />
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Question Modal */}
            {showQuestionModal && (
                <QuestionModal
                    question={editingQuestion}
                    onClose={() => {
                        setShowQuestionModal(false);
                        setEditingQuestion(null);
                    }}
                    onSave={handleQuestionSaved}
                />
            )}
        </div>
    );
};

export default AdminDashboard;