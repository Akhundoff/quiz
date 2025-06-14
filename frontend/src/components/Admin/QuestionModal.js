import React, { useState, useEffect } from 'react';
import { X, Plus, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { adminService } from '../../services/api';

const QuestionModal = ({ question, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        text: '',
        type: 'radio',
        options: [''],
        required: true,
        isActive: true,
    });
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (question) {
            setFormData({
                text: question.text || '',
                type: question.type || 'radio',
                options: question.options || [''],
                required: question.required ?? true,
                isActive: question.isActive ?? true,
            });
        }
    }, [question]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            // Sual mətni yoxlanması
            if (!formData.text.trim()) {
                toast.error('Sual mətni daxil edin');
                return;
            }

            if (formData.type !== 'text' && formData.options.filter(opt => opt.trim()).length < 2) {
                toast.error('Ən azı 2 variant daxil edin');
                return;
            }

            const submitData = {
                ...formData,
                text: formData.text.trim(),
                options: formData.type === 'text' ? null : formData.options.filter(opt => opt.trim()),
            };

            if (question) {
                await adminService.updateQuestion(question.id, submitData);
            } else {
                await adminService.createQuestion(submitData);
            }

            onSave();
        } catch (error) {
            toast.error('Xəta baş verdi');
        } finally {
            setLoading(false);
        }
    };

    const addOption = () => {
        setFormData({
            ...formData,
            options: [...formData.options, ''],
        });
    };

    const removeOption = (index) => {
        if (formData.options.length > 1) {
            setFormData({
                ...formData,
                options: formData.options.filter((_, i) => i !== index),
            });
        }
    };

    const updateOption = (index, value) => {
        const newOptions = [...formData.options];
        newOptions[index] = value;
        setFormData({
            ...formData,
            options: newOptions,
        });
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                <div className="flex justify-between items-center p-6 border-b">
                    <h2 className="text-xl font-semibold">
                        {question ? 'Sualı Redaktə Et' : 'Yeni Sual Əlavə Et'}
                    </h2>
                    <button
                        onClick={onClose}
                        className="text-gray-400 hover:text-gray-600"
                    >
                        <X className="w-6 h-6" />
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-6">
                    {/* ƏLAVƏ EDİLDİ: Question Text Input */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Sual mətni *
                        </label>
                        <textarea
                            value={formData.text}
                            onChange={(e) => setFormData({ ...formData, text: e.target.value })}
                            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-h-[100px] resize-vertical"
                            placeholder="Sualınızı burada yazın..."
                            required
                        />
                    </div>

                    {/* Question Type */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Sual növü *
                        </label>
                        <select
                            value={formData.type}
                            onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        >
                            <option value="radio">Bir variant seçimi (Radio)</option>
                            <option value="checkbox">Çox variant seçimi (Checkbox)</option>
                            <option value="text">Mətn cavabı</option>
                        </select>
                    </div>

                    {/* Options (for radio/checkbox) */}
                    {formData.type !== 'text' && (
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Cavab variantları *
                            </label>
                            <div className="space-y-3">
                                {formData.options.map((option, index) => (
                                    <div key={index} className="flex items-center space-x-2">
                                        <input
                                            type="text"
                                            value={option}
                                            onChange={(e) => updateOption(index, e.target.value)}
                                            className="flex-1 p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                            placeholder={`Variant ${index + 1}`}
                                            required
                                        />
                                        {formData.options.length > 1 && (
                                            <button
                                                type="button"
                                                onClick={() => removeOption(index)}
                                                className="p-2 text-red-600 hover:bg-red-100 rounded"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        )}
                                    </div>
                                ))}
                                <button
                                    type="button"
                                    onClick={addOption}
                                    className="flex items-center text-blue-600 hover:text-blue-700"
                                >
                                    <Plus className="w-4 h-4 mr-1" />
                                    Variant əlavə et
                                </button>
                            </div>
                        </div>
                    )}

                    {/* Settings */}
                    <div className="grid grid-cols-2 gap-4">
                        <div className="flex items-center">
                            <input
                                type="checkbox"
                                id="required"
                                checked={formData.required}
                                onChange={(e) => setFormData({ ...formData, required: e.target.checked })}
                                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            />
                            <label htmlFor="required" className="ml-2 text-sm text-gray-700">
                                Məcburi sual
                            </label>
                        </div>

                        <div className="flex items-center">
                            <input
                                type="checkbox"
                                id="isActive"
                                checked={formData.isActive}
                                onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            />
                            <label htmlFor="isActive" className="ml-2 text-sm text-gray-700">
                                Aktiv sual
                            </label>
                        </div>
                    </div>

                    {/* Submit Buttons */}
                    <div className="flex justify-end space-x-3 pt-6 border-t">
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-4 py-2 text-gray-700 bg-gray-200 rounded-lg hover:bg-gray-300 transition-colors"
                        >
                            Ləğv et
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className={`px-4 py-2 rounded-lg transition-colors ${
                                loading
                                    ? 'bg-gray-300 cursor-not-allowed'
                                    : 'bg-blue-600 hover:bg-blue-700 text-white'
                            }`}
                        >
                            {loading ? 'Saxlanılır...' : (question ? 'Yenilə' : 'Əlavə et')}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default QuestionModal;