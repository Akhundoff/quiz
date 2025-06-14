import React from 'react';
import { BarChart3, Users, FileText, TrendingUp, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

const Statistics = ({ statistics, loading }) => {
    if (loading) {
        return (
            <div className="text-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                <p className="text-gray-600 mt-2">Yüklənir...</p>
            </div>
        );
    }

    if (!statistics) {
        return (
            <div className="text-center py-12">
                <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600">Statistika məlumatları yoxdur</p>
            </div>
        );
    }

    const StatCard = ({ title, value, icon: Icon, color = 'blue', subtitle, trend }) => (
        <div className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="flex items-center">
                <div className={`p-3 rounded-lg bg-${color}-100`}>
                    <Icon className={`w-6 h-6 text-${color}-600`} />
                </div>
                <div className="ml-4 flex-1">
                    <p className="text-sm font-medium text-gray-600">{title}</p>
                    <div className="flex items-baseline space-x-2">
                        <p className="text-2xl font-bold text-gray-900">{value}</p>
                        {trend && (
                            <span className={`text-xs font-medium ${trend > 0 ? 'text-green-600' : 'text-red-600'}`}>
                {trend > 0 ? '↗' : '↘'} {Math.abs(trend)}%
              </span>
                        )}
                    </div>
                    {subtitle && (
                        <p className="text-sm text-gray-500 mt-1">{subtitle}</p>
                    )}
                </div>
            </div>
        </div>
    );

    const ProgressBar = ({ label, current, total, color = 'blue' }) => {
        const percentage = total > 0 ? (current / total) * 100 : 0;

        return (
            <div className="mb-4">
                <div className="flex justify-between text-sm text-gray-600 mb-2">
                    <span>{label}</span>
                    <span>{current} / {total}</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                        className={`bg-${color}-600 h-2 rounded-full transition-all duration-300`}
                        style={{ width: `${Math.min(percentage, 100)}%` }}
                    ></div>
                </div>
                <div className="text-right text-xs text-gray-500 mt-1">
                    {percentage.toFixed(1)}%
                </div>
            </div>
        );
    };

    const QuestionChart = ({ questionStats }) => {
        if (!questionStats || questionStats.length === 0) {
            return (
                <div className="text-center py-8">
                    <FileText className="w-12 h-12 text-gray-300 mx-auto mb-2" />
                    <p className="text-gray-500">Sual statistikası yoxdur</p>
                </div>
            );
        }

        const maxResponses = Math.max(...questionStats.map(q => q.responseCount));

        return (
            <div className="space-y-4">
                {questionStats.map((stat, index) => (
                    <div key={stat.questionId} className="border-b border-gray-100 pb-4 last:border-0">
                        <div className="flex justify-between items-start mb-2">
                            <div className="flex-1 pr-4">
                                <h4 className="font-medium text-gray-900 text-sm mb-1">
                                    Sual #{stat.questionId}
                                </h4>
                                <p className="text-sm text-gray-600 line-clamp-2">
                                    {stat.questionText}
                                </p>
                            </div>
                            <div className="text-right flex-shrink-0">
                                <p className="text-lg font-semibold text-blue-600">
                                    {stat.responseCount}
                                </p>
                                <p className="text-xs text-gray-500">cavab</p>
                            </div>
                        </div>

                        {/* Response bar */}
                        <div className="w-full bg-gray-100 rounded-full h-2">
                            <div
                                className="bg-blue-500 h-2 rounded-full transition-all duration-500"
                                style={{
                                    width: `${maxResponses > 0 ? (stat.responseCount / maxResponses) * 100 : 0}%`
                                }}
                            ></div>
                        </div>
                    </div>
                ))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            {/* Welcome Header */}
            <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg p-6 text-white">
                <h2 className="text-2xl font-bold mb-2">Dashboard</h2>
                <p className="text-blue-100">
                    Quiz sisteminin ümumi göstəriciləri və statistikaları
                </p>
            </div>

            {/* Overview Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard
                    title="Ümumi Sessionlar"
                    value={statistics.totalSessions?.toLocaleString() || '0'}
                    icon={Users}
                    color="blue"
                    subtitle={`${statistics.recentSessions || 0} son 30 gündə`}
                />
                <StatCard
                    title="Tamamlanmış Quizlər"
                    value={statistics.completedSessions?.toLocaleString() || '0'}
                    icon={CheckCircle}
                    color="green"
                    subtitle={`${statistics.completionRate || 0}% tamamlanma dərəcəsi`}
                />
                <StatCard
                    title="Aktiv Suallar"
                    value={statistics.totalQuestions?.toLocaleString() || '0'}
                    icon={FileText}
                    color="purple"
                    subtitle="Hal-hazırda aktiv"
                />
                <StatCard
                    title="Ümumi Cavablar"
                    value={statistics.totalResponses?.toLocaleString() || '0'}
                    icon={BarChart3}
                    color="orange"
                    subtitle={`${statistics.averageResponsesPerSession || 0} ortalama`}
                />
            </div>

            {/* Detailed Stats Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

                {/* Completion Analysis */}
                <div className="bg-white rounded-lg shadow-sm p-6">
                    <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
                        <TrendingUp className="w-5 h-5 mr-2 text-green-600" />
                        Tamamlanma Analizi
                    </h3>

                    <div className="space-y-4">
                        <ProgressBar
                            label="Tamamlanmış Sessionlar"
                            current={statistics.completedSessions || 0}
                            total={statistics.totalSessions || 0}
                            color="green"
                        />

                        <ProgressBar
                            label="Yarımçıq Sessionlar"
                            current={statistics.incompleteSessions || 0}
                            total={statistics.totalSessions || 0}
                            color="orange"
                        />

                        <div className="pt-4 border-t border-gray-100">
                            <div className="flex justify-between text-sm">
                                <span className="text-gray-600">Tamamlanma dərəcəsi:</span>
                                <span className="font-semibold text-green-600">
                  {statistics.completionRate || 0}%
                </span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Recent Activity */}
                <div className="bg-white rounded-lg shadow-sm p-6">
                    <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
                        <Clock className="w-5 h-5 mr-2 text-blue-600" />
                        Son Aktivlik
                    </h3>

                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center">
                                <div className="w-3 h-3 bg-blue-500 rounded-full mr-3"></div>
                                <span className="text-sm text-gray-600">Son 30 gün</span>
                            </div>
                            <span className="font-semibold text-blue-600">
                {statistics.recentSessions || 0} session
              </span>
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center">
                                <div className="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
                                <span className="text-sm text-gray-600">Ortalama cavab</span>
                            </div>
                            <span className="font-semibold text-green-600">
                {statistics.averageResponsesPerSession || 0}
              </span>
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center">
                                <div className="w-3 h-3 bg-purple-500 rounded-full mr-3"></div>
                                <span className="text-sm text-gray-600">Aktiv suallar</span>
                            </div>
                            <span className="font-semibold text-purple-600">
                {statistics.totalQuestions || 0}
              </span>
                        </div>

                        {/* Activity indicator */}
                        <div className="pt-4 border-t border-gray-100">
                            <div className="flex items-center">
                                <div className="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
                                <span className="text-xs text-gray-500">Sistem aktiv</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Quick Actions */}
                <div className="bg-white rounded-lg shadow-sm p-6">
                    <h3 className="text-lg font-medium text-gray-900 mb-4">
                        Tez Əməliyyatlar
                    </h3>

                    <div className="space-y-3">
                        <button className="w-full text-left p-3 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors">
                            <div className="flex items-center">
                                <FileText className="w-4 h-4 text-blue-600 mr-3" />
                                <span className="text-sm font-medium text-blue-800">
                  Yeni Sual Əlavə Et
                </span>
                            </div>
                        </button>

                        <button className="w-full text-left p-3 bg-green-50 hover:bg-green-100 rounded-lg transition-colors">
                            <div className="flex items-center">
                                <BarChart3 className="w-4 h-4 text-green-600 mr-3" />
                                <span className="text-sm font-medium text-green-800">
                  Cavabları İxrac Et
                </span>
                            </div>
                        </button>

                        <button className="w-full text-left p-3 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors">
                            <div className="flex items-center">
                                <Users className="w-4 h-4 text-purple-600 mr-3" />
                                <span className="text-sm font-medium text-purple-800">
                  İstifadəçi Cavabları
                </span>
                            </div>
                        </button>
                    </div>
                </div>
            </div>

            {/* Question Statistics */}
            <div className="bg-white rounded-lg shadow-sm">
                <div className="p-6 border-b border-gray-200">
                    <h3 className="text-lg font-medium text-gray-900 flex items-center">
                        <BarChart3 className="w-5 h-5 mr-2 text-blue-600" />
                        Sual Statistikaları
                    </h3>
                    <p className="text-sm text-gray-600 mt-1">
                        Hər sual üzrə cavab sayı və populyarlıq dərəcəsi
                    </p>
                </div>
                <div className="p-6">
                    <QuestionChart questionStats={statistics.questionStats} />
                </div>
            </div>

            {/* Summary Footer */}
            <div className="bg-gray-50 rounded-lg p-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
                    <div>
                        <div className="text-2xl font-bold text-blue-600">
                            {((statistics.completedSessions || 0) / (statistics.totalSessions || 1) * 100).toFixed(1)}%
                        </div>
                        <div className="text-sm text-gray-600">Uğur dərəcəsi</div>
                    </div>
                    <div>
                        <div className="text-2xl font-bold text-green-600">
                            {statistics.totalResponses || 0}
                        </div>
                        <div className="text-sm text-gray-600">Toplam məlumat</div>
                    </div>
                    <div>
                        <div className="text-2xl font-bold text-purple-600">
                            {statistics.recentSessions || 0}
                        </div>
                        <div className="text-sm text-gray-600">Son aktivlik</div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Statistics;