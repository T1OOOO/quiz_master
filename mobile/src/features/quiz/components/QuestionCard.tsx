import React from 'react';
import { View, Text, TouchableOpacity, Image, ScrollView } from 'react-native';
import Markdown from 'react-native-markdown-display';
import { cn } from '../../../utils/cn';
import { useTelegram } from '../../../hooks/useTelegram';
import { useThemeStore } from '../../../store/useThemeStore';
import { useTranslation } from 'react-i18next';
import { QuizStats, Question, Feedback } from '../../../types/quiz';

// Sub-components
import { QuestionHeader } from './QuestionHeader';
import { AnswerOptions } from './AnswerOptions';

interface QuestionCardProps {
    question: Question;
    selectedAnswer: number | null;
    onAnswer: (idx: number) => void;
    feedback?: Feedback;
    disabled?: boolean;
    currentIdx: number;
    totalQuestions: number;
    onReset: () => void;
    onShuffleQuiz: () => void;
    isShuffled: boolean;
    stats?: QuizStats;
    category?: any;
    quizTitle?: string;
    onNext?: () => void;
    isLast?: boolean;
}

export function QuestionCard({
    question,
    selectedAnswer,
    onAnswer,
    feedback,
    disabled,
    currentIdx,
    totalQuestions,
    onReset,
    onShuffleQuiz,
    stats,
    onNext,
    isLast
}: QuestionCardProps) {
    const { t } = useTranslation();
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';
    const { hapticFeedback } = useTelegram();

    if (!question) return null;

    const handleSelect = (idx: number) => {
        hapticFeedback('selection');
        onAnswer(idx);
    };

    return (
        <ScrollView 
            className="flex-1 w-full" 
            contentContainerStyle={{ paddingVertical: 12, paddingHorizontal: 4 }}
            showsVerticalScrollIndicator={false}
        >
            {/* Main Card Frame */}
            <View className="rounded-3xl border border-border p-4 shadow-2xl relative overflow-hidden bg-card">
                
                <QuestionHeader 
                    currentIdx={currentIdx}
                    totalQuestions={totalQuestions}
                    stats={stats}
                    difficulty={question.difficulty}
                    onReset={onReset}
                    onShuffleQuiz={onShuffleQuiz}
                    questionId={question.id}
                    questionText={question.text}
                />

                {/* Image - Compact */}
                {question.image_url && (
                    <View className="w-full h-28 mb-2 rounded-xl overflow-hidden bg-muted border-2 border-border shadow-sm">
                        <Image
                            source={{ uri: question.image_url }}
                            className="w-full h-full"
                            resizeMode="cover"
                        />
                    </View>
                )}

                {/* Question Text */}
                <View className="mb-2 px-1">
                    <View style={{ opacity: 1 }}>
                        <Markdown style={{ 
                            body: { 
                                color: isHoliday ? '#1e293b' : '#e5e5e5', 
                                fontSize: 16, 
                                fontWeight: '800', 
                                lineHeight: 22, 
                                fontFamily: 'serif' 
                            } 
                        }}>
                            {question.text}
                        </Markdown>
                    </View>

                    <View className="mt-1 flex-row gap-2">
                        {/* Show feedback badge only after answer */}
                        {feedback && (
                            <View className={cn(
                                "px-2 py-0.5 rounded-lg border shadow-sm",
                                feedback.correct ? "border-emerald-200 bg-emerald-50" : "border-rose-200 bg-rose-50"
                            )}>
                                <Text className={cn(
                                    "text-[9px] font-black uppercase tracking-widest",
                                    feedback.correct ? "text-emerald-800" : "text-rose-800"
                                )}>
                                    {feedback.correct ? t('quiz.correct') : t('quiz.incorrect')}
                                </Text>
                            </View>
                        )}
                    </View>
                </View>

                {/* Options */}
                <AnswerOptions 
                    options={question.options}
                    selectedAnswer={selectedAnswer}
                    onAnswer={handleSelect}
                    feedback={feedback}
                    disabled={disabled}
                />

                {/* Explanation Overlay */}
                {feedback && (
                    <View className="mb-1 mx-1 p-2 rounded-lg bg-slate-50 border border-slate-200 shadow-sm">
                        <Text className="text-[9px] font-bold uppercase text-sky-600 mb-0.5">
                            {t('quiz.explanation_title')}
                        </Text>
                        <Markdown style={{ body: { color: '#475569', fontSize: 12, lineHeight: 16 } }}>
                            {feedback.explanation || t('quiz.no_explanation')}
                        </Markdown>
                    </View>
                )}
                
                {/* Next Button */}
                {feedback && onNext && (
                    <View className="w-full mt-0">
                         <TouchableOpacity
                            onPress={onNext}
                            className={cn(
                                "w-full py-2 rounded-lg items-center justify-center shadow-sm",
                                "bg-accent border-b-4 border-accent-dark active:border-b-0 active:translate-y-1"
                            )}
                            activeOpacity={0.8}
                        >
                            <Text className={cn(
                                "font-bold text-xs uppercase tracking-wider text-white"
                            )}>
                                {isLast ? t('quiz.finish') : t('quiz.next')}
                            </Text>
                        </TouchableOpacity>
                    </View>
                )}

            </View>
        </ScrollView>
    );
}
