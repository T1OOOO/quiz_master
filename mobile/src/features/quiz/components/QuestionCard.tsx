import React from 'react';
import { View, Text, TouchableOpacity, Image, ScrollView, Dimensions } from 'react-native';
import Markdown from 'react-native-markdown-display';
import { cn } from '../../../utils/cn';
import { useTelegram } from '../../../hooks/useTelegram';
import { useThemeStyles } from '../../../hooks/useThemeStyles';
import { ThemeDecoration } from '../../../theme/components/ThemeDecoration';
import { Button } from '../../../components/ui/Button'; // Ensure this exists
import { Home, ChevronRight } from 'lucide-react-native';
import { useRouter } from 'expo-router';

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
    breadcrumbs?: Breadcrumb[];
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
    breadcrumbs,
    isLast
}: QuestionCardProps) {
    const { styles, isHoliday, config } = useThemeStyles();
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
            {/* Main Card Frame - Clean Winter White "Fresh Snow" */}
            <View className={cn(
                "rounded-3xl border border-slate-200 p-4 shadow-2xl relative overflow-hidden",
                isHoliday ? "bg-white" : "bg-neutral-900 border-neutral-700"
            )}>
                
                {/* Top Toolbar with Stats - Ultra Compact */}
                <View className="mb-2 flex-row justify-between items-center px-1">
                    <View className="flex-row items-center gap-2">
                        {/* Progress */}
                        <View className={cn("px-2 py-0.5 rounded-full border shadow-sm", styles.pill)}>
                            <Text className={cn("text-[10px] font-black tracking-widest", styles.pillActive)}>
                                {currentIdx + 1}/{totalQuestions}
                            </Text>
                        </View>
                    </View>

                    {/* Right Side: Score & Buttons */}
                    <View className="flex-row items-center gap-1.5">
                         {/* Score Board - Compact */}
                        <View className={cn(
                            "px-2 py-0.5 rounded-full border flex-row gap-2 items-center shadow-sm mr-1",
                            isHoliday ? "bg-white border-slate-100" : "bg-neutral-800 border-neutral-700"
                        )}>
                            <View className="flex-row items-center gap-1">
                                <Text className="text-[10px]">🎉</Text>
                                <Text className={cn("text-[10px] font-bold", isHoliday ? "text-emerald-600" : "text-green-400")}>
                                    {stats?.correct || 0}
                                </Text>
                            </View>
                            <View className="w-px h-2.5 bg-slate-200" />
                            <View className="flex-row items-center gap-1">
                                <Text className="text-[10px]">❄️</Text>
                                <Text className={cn("text-[10px] font-bold", isHoliday ? "text-slate-400" : "text-red-400")}>
                                    {stats?.incorrect || 0}
                                </Text>
                            </View>
                        </View>

                        <TouchableOpacity onPress={onReset} className="px-2 py-0.5 bg-slate-100 rounded-full border border-slate-200">
                             <Text className={cn("text-[9px] font-bold uppercase tracking-wider text-slate-500")}>Reset</Text>
                        </TouchableOpacity>
                        <TouchableOpacity onPress={onShuffleQuiz} className="px-2 py-0.5 bg-slate-100 rounded-full border border-slate-200">
                            <Text className={cn("text-[9px] font-bold uppercase tracking-wider text-slate-500")}>Mix</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                {/* Image - Compact */}
                {question.image_url && (
                    <View className="w-full h-28 mb-2 rounded-xl overflow-hidden bg-slate-100 border-2 border-white shadow-sm">
                        <Image
                            source={{ uri: question.image_url }}
                            className={cn("w-full h-full", styles.cardImage)}
                            resizeMode="cover"
                        />
                    </View>
                )}

                {/* Question Text - Dark Slate */}
                <View className="mb-2 px-1">
                    <View style={{ opacity: 1 }}>
                        <Markdown style={{ body: { color: isHoliday ? '#1e293b' : '#e5e5e5', fontSize: 16, fontWeight: '800', lineHeight: 22, fontFamily: 'serif' } }}>
                            {question.text}
                        </Markdown>
                    </View>

                    <View className="mt-1 flex-row">
                        <View className={cn(
                            "px-2 py-0.5 rounded-lg border shadow-sm",
                            feedback ? (feedback.correct ? "border-emerald-200 bg-emerald-50" : "border-rose-200 bg-rose-50") : "border-blue-200 bg-blue-50"
                        )}>
                            <Text className={cn(
                                "text-[9px] font-black uppercase tracking-widest",
                                feedback ? (feedback.correct ? "text-emerald-800" : "text-rose-800") : "text-blue-800"
                            )}>
                                {feedback ? (feedback.correct ? '🎉 Верно' : '❌ Ошибка') : '❄️ Вопрос'}
                            </Text>
                        </View>
                    </View>
                </View>

                {/* Options - Festive Gift Cards Grid */}
                <View className="flex-row flex-wrap justify-between px-1 mb-2">
                    {question.options.map((opt: string, idx: number) => {
                        const status = getOptionStatus(idx);
                        
                        let bgClass = "bg-white border border-slate-200 shadow-sm";
                        let textClass = "text-slate-700 font-bold";
                        let ornamentClass = "bg-slate-100";
                        let ornamentText = "text-slate-400";
                        
                        // Active State
                        if (status === 'selected') {
                            bgClass = isHoliday ? "bg-amber-50 border-amber-300 shadow-md" : "bg-sky-50 border-sky-300";
                            textClass = isHoliday ? "text-amber-900" : "text-sky-900";
                            ornamentClass = isHoliday ? "bg-amber-200" : "bg-sky-200";
                            ornamentText = isHoliday ? "text-amber-800" : "text-sky-800";
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
                                    "w-[49%] p-2 rounded-xl flex-row items-center transition-all mb-2", 
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
                                    <Markdown style={{ body: { color: status === 'selected' || status === 'correct' || status === 'incorrect' ? '#1e293b' : '#334155', fontSize: 13, lineHeight: 16, fontWeight: '600', fontFamily: 'serif' } }}>
                                        {opt}
                                    </Markdown>
                                </View>
                            </TouchableOpacity>
                        );
                    })}
                </View>

                {/* Explanation Overlay/Compact */}
                {feedback && (
                    <View className="mb-2 mx-1 p-2.5 rounded-xl bg-slate-50 border border-slate-200 shadow-sm">
                        <Text className="text-[9px] font-bold uppercase text-sky-600 mb-0.5">
                            ✨ Интересный факт
                        </Text>
                        <Markdown style={{ body: { color: '#475569', fontSize: 12, lineHeight: 16 } }}>
                            {feedback.explanation || "Нет объяснения."}
                        </Markdown>
                    </View>
                )}
                
                {/* Next Button inside the Frame */}
                {feedback && onNext && (
                    <View className="w-full mt-0.5">
                         <TouchableOpacity
                            onPress={onNext}
                            className={cn(
                                "w-full py-2.5 rounded-xl items-center justify-center shadow-md",
                                isHoliday ? "bg-sky-500 border-b-4 border-sky-700 active:border-b-0 active:translate-y-1" : "bg-white"
                            )}
                            activeOpacity={0.8}
                        >
                            <Text className={cn(
                                "font-bold text-xs uppercase tracking-wider",
                                isHoliday ? "text-white" : "text-black"
                            )}>
                                {isLast ? "Завершить" : "Далее"}
                            </Text>
                        </TouchableOpacity>
                    </View>
                )}

            </View>
        </ScrollView>
    );
}
