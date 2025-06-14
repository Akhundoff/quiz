import React, { useState } from 'react';
import { Eye, Calendar, User, CheckCircle, XCircle } from 'lucide-react';

const ResponsesTable = ({ responses, loading }) => {
    const [selectedSession, setSelectedSession] = useState(null);
    const [expandedSessions, setExpandedSessions] = useState(new Set());

    if (loading) {
        return (
            <div className="text-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                <p className="text-gray-600 mt-2">Yüklənir...</p>
            </div>
        );
    }

    const toggleSession = (sessionId) => {
        const newExpanded = new Set(expandedSessions);
        if (newExpanded.has(sessionId)) {
            newExpanded.delete(sessionId);
        } else {
            newExpanded.add(sessionId);
        }
        setExpandedSessions(newExpanded);
    };

    const formatDate = (dateString) => {
        return new Date(dateString).toLocaleString('az-AZ', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
        });
    };

    return (
        <div className="p-6">
            {responses.data?.length === 0 ? (
                <div className="text-center py-12">
                    <p className="text-gray-600">Hələ cavab yoxdur</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {responses.data?.map((session) => (
                        <div key={session.id} className="border border-gray-200 rounded-lg">
                            <div
                                className="p-4 bg-gray-50 cursor-pointer hover:bg-gray-100 transition-colors"
                                onClick={() => toggleSession(session.id)}
                            >
                                <div className="flex justify-between items-center">
                                    <div className="flex items-center space-x-4">
                                        <div className="flex items-center space-x-2">
                                            {session.isCompleted ? (
                                                <CheckCircle className="w-5 h-5 text-green-600" />
                                            ) : (
                                                <XCircle className="w-5 h-5 text-red-600" />
                                            )}
                                            <span className="font-medium">
                        {session.userName || 'Gizli şəxs'}
                      </span>
                                        </div>
                                        <div className="flex items-center text-sm text-gray-600">
                                            <Calendar className="w-4 h-4 mr-1" />
                                            {formatDate(session.createdAt)}
                                        </div>
                                    </div>
                                    <div className="text-sm text-gray-600">
                                        {session.responses?.length || 0} cavab
                                    </div>
                                </div>
                            </div>

                            {expandedSessions.has(session.id) && (
                                <div className="p-4 border-t border-gray-200">
                                    <div className="mb-4 text-sm text-gray-600">
                                        <p><strong>Session ID:</strong> {session.id}</p>
                                        {session.completedAt && (
                                            <p><strong>Tamamlanma tarixi:</strong> {formatDate(session.completedAt)}</p>
                                        )}
                                    </div>

                                    {session.responses && session.responses.length > 0 ? (
                                        <div className="space-y-3">
                                            {session.responses.map((response) => (
                                                <div key={response.id} className="bg-gray-50 p-3 rounded">
                                                    <p className="font-medium text-gray-900 mb-2">
                                                        {response.question?.text}
                                                    </p>
                                                    <p className="text-gray-700">
                                                        <strong>Cavab:</strong> {response.answerText}
                                                    </p>
                                                    <p className="text-xs text-gray-500 mt-1">
                                                        {formatDate(response.createdAt)}
                                                    </p>
                                                </div>
                                            ))}
                                        </div>
                                    ) : (
                                        <p className="text-gray-600 text-center py-4">
                                            Bu session üçün cavab yoxdur
                                        </p>
                                    )}
                                </div>
                            )}
                        </div>
                    ))}

                    {/* Pagination */}
                    {responses.pagination && responses.pagination.totalPages > 1 && (
                        <div className="flex justify-center items-center space-x-4 mt-6">
              <span className="text-sm text-gray-600">
                Səhifə {responses.pagination.page} / {responses.pagination.totalPages}
              </span>
                            {/* Add pagination buttons here if needed */}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

export default ResponsesTable;