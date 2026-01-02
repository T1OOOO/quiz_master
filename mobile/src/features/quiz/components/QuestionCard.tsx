import React from 'react';
import { View, Text, TouchableOpacity, Image, ScrollView, Dimensions } from 'react-native';
import Markdown from 'react-native-markdown-display';
import { cn } from '../../../utils/cn';
import { useTelegram } from '../../../hooks/useTelegram';
import { useThemeStore } from '../../../store/useThemeStore';
import { ThemeDecoration } from '../../../theme/components/ThemeDecoration';
import { Button } from '../../../components/ui/Button'; // Ensure this exists
import { Trash2, Shuffle, CheckCircle, XCircle, ChevronRight, Info, Gift, Snowflake } from '../../../components/icons';
import { useTranslation } from 'react-i18next';
import { useRouter } from 'expo-router';
import { ReportButton } from '../../../components/ReportButton';

import { Quiz, Question, Feedback, QuizStats } from '../../../types/quiz';

interface Breadcrumb {
    label: string;
    onPress?: () => void;
}

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
    isShuffled,
    stats,
    category,
    quizTitle,
    onNext,
    isLast
}: QuestionCardProps) {
    const { t } = useTranslation();
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';
    const { hapticFeedback } = useTelegram();
    const router = useRouter();

    if (!question) return null;

    const handleSelect = (idx: number) => {
        if (feedback || disabled) return;
        hapticFeedback('selection');
        onAnswer(idx);
    };

    const getOptionStatus = (idx: number) => {
        if (!feedback) {
            return selectedAnswer === idx ? 'selected' : 'neutral';
        }
        const currentOptionText = question.options[idx];
        if (feedback.correct_text === currentOptionText) return 'correct';
        if (selectedAnswer === idx && !feedback.correct) return 'incorrect';
        return 'neutral';
    };

    return (
        <ScrollView 
            className="flex-1 w-full" 
            contentContainerStyle={{ paddingVertical: 12, paddingHorizontal: 4 }}
            showsVerticalScrollIndicator={false}
        >
            {/* Main Card Frame */}
            <View className="rounded-3xl border border-border p-4 shadow-2xl relative overflow-hidden bg-card">
                
                {/* Top Toolbar with Stats - Compact Premium Design */}
                <View className="mb-2">
                    <View className="flex-row justify-between items-center px-3 py-2 rounded-xl bg-white/5 backdrop-blur-sm border border-white/10 shadow-lg">
                        {/* Left Group: Question Stats */}
                        <View className="flex-row items-center gap-2">
                            {/* Progress */}
                            <View className="flex-row items-center gap-1 px-2 py-0.5 rounded-lg bg-blue-500/10">
                                <Text className="text-[13px]">❓</Text>
                                <Text className="text-[11px] font-black tracking-tight text-blue-500">
                                    {currentIdx + 1}/{totalQuestions}
                                </Text>
                            </View>
                            
                            {/* Results */}
                            <View className="flex-row items-center gap-1.5">
                                <View className="flex-row items-center gap-1 px-1.5 py-0.5 rounded-lg bg-green-500/10">
                                    <Text className="text-[11px]">✅</Text>
                                    <Text className="text-[11px] font-bold text-green-600">
                                        {stats?.correct || 0}
                                    </Text>
                                </View>
                                <View className="flex-row items-center gap-1 px-1.5 py-0.5 rounded-lg bg-red-500/10">
                                    <Text className="text-[11px]">❌</Text>
                                    <Text className="text-[11px] font-bold text-red-500">
                                        {stats?.incorrect || 0}
                                    </Text>
                                </View>
                            </View>
                            
                            {/* Difficulty */}
                            {question.difficulty && (
                                <>
                                    <View className="w-px h-4 bg-white/10" />
                                    <View className="flex-row items-center gap-1 px-2 py-0.5 rounded-lg bg-purple-500/10">
                                        <Text className="text-[12px]">⚡</Text>
                                        <Text className="text-[10px] font-black text-purple-600">
                                            {question.difficulty}/10
                                        </Text>
                                    </View>
                                </>
                            )}
                        </View>

                        {/* Right Group: Actions */}
                        <View className="flex-row items-center gap-1">
                            {/* Reset */}
                            <TouchableOpacity 
                                onPress={onReset} 
                                className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 active:bg-white/15 border border-white/10"
                                // @ts-ignore
                                title={t('quiz.reset', 'Сбросить прогресс')}
                            >
                                <Text className="text-[14px]">🔄</Text>
                            </TouchableOpacity>
                            
                            {/* Shuffle */}
                            <TouchableOpacity 
                                onPress={onShuffleQuiz} 
                                className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 active:bg-white/15 border border-white/10"
                                // @ts-ignore
                                title={t('quiz.mix', 'Перемешать вопросы')}
                            >
                                <Text className="text-[14px]">🔀</Text>
                            </TouchableOpacity>
                            
                            {/* Report */}
                            <View className="p-1.5 rounded-lg bg-white/5 border border-white/10">
                                <ReportButton questionId={question.id} questionText={question.text} />
                            </View>
                        </View>
                    </View>
                </View>

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
                                color: isHoliday ? '#1e293b' : '#e5e5e5', // Fallback for MD until generic support verified
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

                {/* Options - Responsive Layout */}
                <View className="flex-row flex-wrap px-1 mb-2">
                    {question.options.map((opt: string, idx: number) => {
                        const status = getOptionStatus(idx);
                        
                        // Calculate if text is long (more than 30 chars = full width)
                        const isLongText = opt.length > 30;
                        
                        let bgClass = isHoliday ? "bg-white border-amber-200 shadow-sm" : "bg-card-secondary border-border shadow-sm";
                        let textClass = "text-text-primary font-bold";
                        let ornamentClass = isHoliday ? "bg-red-50 border-red-100" : "bg-accent/10";
                        let ornamentText = isHoliday ? "text-red-800" : "text-accent";
                        
                        // Active State
                        if (status === 'selected') {
                            if (isHoliday) {
                                bgClass = "bg-amber-50 border-amber-400 shadow-md";
                                textClass = "text-amber-900";
                                ornamentClass = "bg-amber-200 border-amber-300";
                                ornamentText = "text-amber-900";
                            } else {
                                bgClass = "bg-accent/10 border-accent shadow-md"; 
                                textClass = "text-accent"; 
                                ornamentClass = "bg-accent/20";
                                ornamentText = "text-accent-dark";
                            }
                        } else if (status === 'correct') {
                            bgClass = "bg-emerald-50 border-emerald-300";
                            textClass = "text-emerald-900";
                            ornamentClass = "bg-emerald-200";
                            ornamentText = "text-emerald-800";
                        } else if (status === 'incorrect') {
                            bgClass = "bg-rose-50 border-rose-300";
                            textClass = "text-rose-900";
                            ornamentClass = "bg-rose-200";
                            ornamentText = "text-rose-800";
                        }

                        return (
                            <TouchableOpacity
                                key={idx}
                                onPress={() => handleSelect(idx)}
                                disabled={disabled || !!feedback}
                                className={cn(
                                    "p-2 rounded-xl flex-row items-center transition-all mb-2 border",
                                    isLongText ? "w-full" : "w-[49%]",
                                    !isLongText && idx % 2 === 0 && "mr-[2%]",
                                    bgClass,
                                )}
                                activeOpacity={0.7}
                            >
                                {/* Simple Circle/Ornament Indicator */}
                                <View className={cn(
                                    "w-6 h-6 items-center justify-center rounded-full mr-2 border border-black/10 flex-shrink-0",
                                    ornamentClass
                                )}>
                                    <Text className={cn("text-[9px] font-black", ornamentText)}>
                                        {String.fromCharCode(65 + idx)}
                                    </Text>
                                </View>
                                
                                <View className="flex-1 justify-center">
                                    <Markdown style={{ 
                                        body: { 
                                            color: status === 'selected' || status === 'correct' || status === 'incorrect' ? '#1e293b' : '#334155',
                                            fontSize: 13, 
                                            lineHeight: 16, 
                                            fontWeight: '600', 
                                            fontFamily: 'serif' 
                                        } 
                                    }}>
                                        {opt}
                                    </Markdown>
                                </View>
                            </TouchableOpacity>
                        );
                    })}
                </View>

                {/* Explanation Overlay/Compact - Vertical but Tight */}
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
                
                {/* Next Button inside the Frame - Compact Height */}
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
