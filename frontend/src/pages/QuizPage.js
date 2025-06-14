import React, { useState, useEffect } from 'react';
import { ChevronRight, CheckCircle, Clock, User } from 'lucide-react';
import toast from 'react-hot-toast';
import { quizService } from '../services/api';

const QuizPage = () => {
    const [currentStep, setCurrentStep] = useState('start'); // 'start', 'quiz', 'complete'
    const [questions, setQuestions] = useState([]);
    const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
    const [sessionId, setSessionId] = useState(null);
    const [answers, setAnswers] = useState({});
    const [userName, setUserName] = useState('');
    const [loading, setLoading] = useState(false);
    const [progress, setProgress] = useState(0);

    const currentQuestion = questions[currentQuestionIndex];

    const startQuiz = async () => {
        setLoading(true);
        try {
            const data = await quizService.startQuiz();
            setQuestions(data.questions);
            setSessionId(data.sessionId);
            setCurrentStep('quiz');
            setProgress(0);
            toast.success('Quiz başladı! Uğurlar!');
        } catch (error) {
            toast.error('Quiz başlada bilmədi. Yenidən cəhd edin.');
        } finally {
            setLoading(false);
        }
    };

    const handleAnswer = async (answer) => {
        if (!currentQuestion || !sessionId) return;

        const updatedAnswers = { ...answers, [currentQuestion.id]: answer };
        setAnswers(updatedAnswers);

        try {
            await quizService.submitAnswer(sessionId, currentQuestion.id, answer);
        } catch (error) {
            toast.error('Cavab saxlanmadı. Yenidən cəhd edin.');
        }
    };

    const nextQuestion = () => {
        if (currentQuestionIndex < questions.length - 1) {
            setCurrentQuestionIndex(currentQuestionIndex + 1);
            setProgress(((currentQuestionIndex + 1) / questions.length) * 100);
        } else {
            setCurrentStep('name');
        }
    };

    const previousQuestion = () => {
        if (currentQuestionIndex > 0) {
            setCurrentQuestionIndex(currentQuestionIndex - 1);
            setProgress(((currentQuestionIndex - 1) / questions.length) * 100);
        }
    };

    const completeQuiz = async () => {
        if (!sessionId) return;

        setLoading(true);
        try {
            await quizService.completeQuiz(sessionId, userName);
            setCurrentStep('complete');
            toast.success('Quiz uğurla tamamlandı! Təşəkkür edirik!');
        } catch (error) {
            toast.error('Quiz tamamlana bilmədi. Yenidən cəhd edin.');
        } finally {
            setLoading(false);
        }
    };

    const restartQuiz = () => {
        setCurrentStep('start');
        setQuestions([]);
        setCurrentQuestionIndex(0);
        setSessionId(null);
        setAnswers({});
        setUserName('');
        setProgress(0);
    };

    if (currentStep === 'start') {
        return (
            <div className="min-h-screen flex items-center justify-center p-4">
                <div className="max-w-md w-full bg-white rounded-2xl shadow-2xl p-8 text-center animate-fadeIn">
                    <div className="mb-6">
                        <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
                            <CheckCircle className="w-8 h-8 text-white" />
                        </div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-2">
                            Rəy Sorğusu
                        </h1>
                        <p className="text-gray-600">
                            Bir neçə sual cavablayaraq bizə kömək edin. Maksimum 5 dəqiqə çəkəcək.
                        </p>
                    </div>

                    <button
                        onClick={startQuiz}
                        disabled={loading}
                        className={`w-full py-3 rounded-lg font-medium transition-all flex items-center justify-center ${
                            loading
                                ? 'bg-gray-300 cursor-not-allowed'
                                : 'bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white'
                        }`}
                    >
                        {loading ? 'Yüklənir...' : 'Başla'}
                        {!loading && <ChevronRight className="w-5 h-5 ml-2" />}
                    </button>

                    <p className="text-xs text-gray-500 mt-4">
                        Qeydiyyat tələb olunmur • Anonim sorğu
                    </p>
                </div>
            </div>
        );
    }

    if (currentStep === 'quiz' && currentQuestion) {
        const currentAnswer = answers[currentQuestion.id];
        const isAnswered = currentAnswer !== undefined && currentAnswer !== '';

        return (
            <div className="min-h-screen flex items-center justify-center p-4">
                <div className="max-w-2xl w-full bg-white rounded-2xl shadow-2xl p-8 animate-fadeIn">
                    {/* Progress */}
                    <div className="mb-8">
                        <div className="flex justify-between items-center mb-2">
              <span className="text-sm text-gray-600">
                Sual {currentQuestionIndex + 1} / {questions.length}
              </span>
                            <span className="text-sm text-gray-600">
                {Math.round(progress)}% tamamlandı
              </span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                            <div
                                className="bg-gradient-to-r from-blue-500 to-purple-600 h-2 rounded-full transition-all duration-500"
                                style={{width: `${progress}%`}}
                            ></div>
                        </div>
                    </div>

                    {/* Question */}
                    <div className="mb-8">
                        <h2 className="text-xl font-semibold text-gray-800 mb-6">
                            {currentQuestion.text}
                        </h2>

                        {/* Answer Options */}
                        <div className="space-y-3">
                            {currentQuestion.type === 'radio' && currentQuestion.options?.map((option, index) => (
                                <button
                                    key={index}
                                    onClick={() => handleAnswer(option)}
                                    className={`w-full p-4 text-left rounded-lg border-2 transition-all ${
                                        currentAnswer === option
                                            ? 'border-blue-500 bg-blue-50 text-blue-800'
                                            : 'border-gray-200 bg-white hover:border-blue-300 hover:bg-blue-50'
                                    }`}
                                >
                                    <div className="flex items-center">
                                        <div className={`w-4 h-4 rounded-full border-2 mr-3 ${
                                            currentAnswer === option ? 'border-blue-500 bg-blue-500' : 'border-gray-300'
                                        }`}>
                                            {currentAnswer === option && (
                                                <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5"></div>
                                            )}
                                        </div>
                                        {option}
                                    </div>
                                </button>
                            ))}

                            {currentQuestion.type === 'checkbox' && currentQuestion.options?.map((option, index) => {
                                const selectedOptions = currentAnswer ? JSON.parse(currentAnswer) : [];
                                const isSelected = selectedOptions.includes(option);

                                return (
                                    <button
                                        key={index}
                                        onClick={() => {
                                            const current = currentAnswer ? JSON.parse(currentAnswer) : [];
                                            const updated = isSelected
                                                ? current.filter(item => item !== option)
                                                : [...current, option];
                                            handleAnswer(JSON.stringify(updated));
                                        }}
                                        className={`w-full p-4 text-left rounded-lg border-2 transition-all ${
                                            isSelected
                                                ? 'border-blue-500 bg-blue-50 text-blue-800'
                                                : 'border-gray-200 bg-white hover:border-blue-300 hover:bg-blue-50'
                                        }`}
                                    >
                                        <div className="flex items-center">
                                            <div className={`w-4 h-4 rounded border-2 mr-3 flex items-center justify-center ${
                                                isSelected ? 'border-blue-500 bg-blue-500' : 'border-gray-300'
                                            }`}>
                                                {isSelected && (
                                                    <CheckCircle className="w-3 h-3 text-white" />
                                                )}
                                            </div>
                                            {option}
                                        </div>
                                    </button>
                                );
                            })}

                            {currentQuestion.type === 'text' && (
                                <textarea
                                    value={currentAnswer || ''}
                                    onChange={(e) => handleAnswer(e.target.value)}
                                    placeholder="Cavabınızı yazın..."
                                    className="w-full p-4 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none min-h-[120px] resize-none"
                                />
                            )}
                        </div>
                    </div>

                    {/* Navigation */}
                    <div className="flex justify-between items-center">
                        <button
                            onClick={previousQuestion}
                            disabled={currentQuestionIndex === 0}
                            className={`px-6 py-2 rounded-lg font-medium transition-all ${
                                currentQuestionIndex === 0
                                    ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                            }`}
                        >
                            Əvvəlki
                        </button>

                        <button
                            onClick={nextQuestion}
                            disabled={currentQuestion.required && !isAnswered}
                            className={`px-6 py-2 rounded-lg font-medium transition-all flex items-center ${
                                currentQuestion.required && !isAnswered
                                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                                    : 'bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white'
                            }`}
                        >
                            {currentQuestionIndex === questions.length - 1 ? 'Bitir' : 'Növbəti'}
                            <ChevronRight className="w-4 h-4 ml-2" />
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    if (currentStep === 'name') {
        return (
            <div className="min-h-screen flex items-center justify-center p-4">
                <div className="max-w-md w-full bg-white rounded-2xl shadow-2xl p-8 text-center animate-fadeIn">
                    <div className="mb-6">
                        <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                            <User className="w-8 h-8 text-white" />
                        </div>
                        <h2 className="text-2xl font-bold text-gray-800 mb-2">
                            Son addım!
                        </h2>
                        <p className="text-gray-600">
                            İstəsəniz adınızı daxil edin (məcburi deyil)
                        </p>
                    </div>

                    <input
                        type="text"
                        value={userName}
                        onChange={(e) => setUserName(e.target.value)}
                        placeholder="Gizli şəxs"
                        className="w-full p-4 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none mb-6 text-center"
                        maxLength={50}
                    />

                    <button
                        onClick={completeQuiz}
                        disabled={loading}
                        className={`w-full py-3 rounded-lg font-medium transition-all ${
                            loading
                                ? 'bg-gray-300 cursor-not-allowed'
                                : 'bg-gradient-to-r from-green-500 to-blue-600 hover:from-green-600 hover:to-blue-700 text-white'
                        }`}
                    >
                        {loading ? 'Göndərilir...' : 'Quizi Tamamla'}
                    </button>
                </div>
            </div>
        );
    }

    if (currentStep === 'complete') {
        return (
            <div className="min-h-screen flex items-center justify-center p-4">
                <div className="max-w-md w-full bg-white rounded-2xl shadow-2xl p-8 text-center animate-fadeIn">
                    <div className="mb-6">
                        <div className="w-20 h-20 bg-gradient-to-r from-green-500 to-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                            <CheckCircle className="w-10 h-10 text-white" />
                        </div>
                        <h2 className="text-2xl font-bold text-gray-800 mb-2">
                            Təşəkkür edirik! 🎉
                        </h2>
                        <p className="text-gray-600 mb-4">
                            Vaxtınızı ayırdığınız üçün çox sağ olun. Cavablarınız bizim üçün çox dəyərlidir.
                        </p>
                        <div className="bg-gray-50 rounded-lg p-4 mb-6">
                            <p className="text-sm text-gray-600">
                                Cavabladığınız sual sayı: <span className="font-semibold text-blue-600">{Object.keys(answers).length}</span>
                            </p>
                            {userName && (
                                <p className="text-sm text-gray-600 mt-1">
                                    Ad: <span className="font-semibold text-blue-600">{userName}</span>
                                </p>
                            )}
                        </div>
                    </div>

                    <button
                        onClick={restartQuiz}
                        className="w-full py-3 rounded-lg font-medium bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white transition-all"
                    >
                        Yeni Quiz Başlat
                    </button>

                    <p className="text-xs text-gray-500 mt-4">
                        Cavablarınız təhlükəsizdir və məxfi saxlanılır
                    </p>
                </div>
            </div>
        );
    }

    return null;
};

export default QuizPage;