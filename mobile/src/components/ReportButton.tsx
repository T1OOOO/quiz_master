import React, { useState } from 'react';
import { View, Text, Modal, TextInput, TouchableOpacity, Alert } from 'react-native';
import { Flag, X, Send } from './icons'; // Ensure icons are exported
import { useTranslation } from 'react-i18next';
import { cn } from '../utils/cn';
import { useThemeStore } from '../store/useThemeStore';
import { QuizRepository } from '../api/quizRepository';
import { useQuizStore } from '../store/quizStore';
import { Platform } from 'react-native';

interface ReportButtonProps {
    questionId: string;
    questionText: string;
}

export function ReportButton({ questionId, questionText }: ReportButtonProps) {
    const [modalVisible, setModalVisible] = useState(false);
    const [comment, setComment] = useState('');
    const { t } = useTranslation();
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';

    const { quizId } = useQuizStore();

    const handleSendReport = async () => {
        if (!quizId) return;
        
        // Call API
        await QuizRepository.reportIssue(quizId, questionId, comment, questionText);
        
        // Show success
        if (Platform.OS === 'web') {
            window.alert(t('quiz.report_sent'));
        } else {
            Alert.alert(t('common.success'), t('quiz.report_sent'), [{ text: "OK" }]);
        }
        setModalVisible(false);
        setComment('');
    };

    return (
        <>
            <TouchableOpacity 
                onPress={() => setModalVisible(true)}
                className="hover:opacity-70 active:opacity-50"
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                // @ts-ignore - title works on web for tooltip
                title={t('quiz.report', 'Пожаловаться на вопрос')}
            >
                <Text className="text-[15px]">⚠️</Text>
            </TouchableOpacity>

            <Modal
                animationType="fade"
                transparent={true}
                visible={modalVisible}
                onRequestClose={() => setModalVisible(false)}
            >
                <View className="flex-1 justify-center items-center bg-black/60 px-4">
                    <View className={cn(
                        "w-full max-w-sm rounded-2xl p-5 shadow-xl",
                        isHoliday ? "bg-[#fffbf0] border border-amber-100" : "bg-card border border-border"
                    )}>
                        {/* Header */}
                        <View className="flex-row justify-between items-center mb-4">
                            <Text className={cn(
                                "text-lg font-bold",
                                isHoliday ? "text-amber-900" : "text-text-primary"
                            )}>
                                {t('quiz.report_issue')}
                            </Text>
                            <TouchableOpacity onPress={() => setModalVisible(false)} className="p-1">
                                <X size={20} color={isHoliday ? "#b45309" : "#94a3b8"} />
                            </TouchableOpacity>
                        </View>

                        {/* Description */}
                        <Text className={cn(
                            "text-sm mb-4 leading-5",
                            isHoliday ? "text-amber-800/80" : "text-text-secondary"
                        )}>
                            {t('quiz.report_description')}
                        </Text>

                        {/* Input */}
                        <TextInput
                            style={{ 
                                textAlignVertical: 'top',
                                minHeight: 100,
                            }}
                            className={cn(
                                "w-full p-3 rounded-xl border mb-4 text-sm",
                                isHoliday 
                                    ? "bg-white border-amber-200 text-stone-800 placeholder:text-stone-400" 
                                    : "bg-black/20 border-white/10 text-text-primary placeholder:text-text-muted"
                            )}
                            placeholder={t('quiz.report_placeholder')}
                            multiline={true}
                            value={comment}
                            onChangeText={setComment}
                            placeholderTextColor={isHoliday ? "#a8a29e" : "#64748b"}
                        />

                        {/* Send Button */}
                        <TouchableOpacity
                            onPress={handleSendReport}
                            className={cn(
                                "w-full py-3 rounded-xl flex-row justify-center items-center gap-2",
                                isHoliday ? "bg-amber-500 active:bg-amber-600" : "bg-accent active:bg-accent-dark"
                            )}
                        >
                            <Send size={16} color="white" />
                            <Text className="text-white font-bold text-sm uppercase tracking-wide">
                                {t('common.send')}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modal>
        </>
    );
}
