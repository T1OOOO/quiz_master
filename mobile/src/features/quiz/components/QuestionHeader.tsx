import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useTranslation } from 'react-i18next';
import { ReportButton } from '../../../components/ReportButton';
import { QuizStats } from '../../../types/quiz';

interface QuestionHeaderProps {
    currentIdx: number;
    totalQuestions: number;
    stats?: QuizStats;
    difficulty?: number;
    onReset: () => void;
    onShuffleQuiz: () => void;
    questionId: string;
    questionText: string;
}

export function QuestionHeader({
    currentIdx,
    totalQuestions,
    stats,
    difficulty,
    onReset,
    onShuffleQuiz,
    questionId,
    questionText
}: QuestionHeaderProps) {
    const { t } = useTranslation();

    return (
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
                    {difficulty && (
                        <>
                            <View className="w-px h-4 bg-white/10" />
                            <View className="flex-row items-center gap-1 px-2 py-0.5 rounded-lg bg-purple-500/10">
                                <Text className="text-[12px]">⚡</Text>
                                <Text className="text-[10px] font-black text-purple-600">
                                    {difficulty}/10
                                </Text>
                            </View>
                        </>
                    )}
                </View>

                {/* Right Group: Actions */}
                <View className="flex-row items-center gap-1">
                    <TouchableOpacity 
                        onPress={onReset} 
                        className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 active:bg-white/15 border border-white/10"
                    >
                        <Text className="text-[14px]">🔄</Text>
                    </TouchableOpacity>
                    
                    <TouchableOpacity 
                        onPress={onShuffleQuiz} 
                        className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 active:bg-white/15 border border-white/10"
                    >
                        <Text className="text-[14px]">🔀</Text>
                    </TouchableOpacity>
                    
                    <View className="p-1.5 rounded-lg bg-white/5 border border-white/10">
                        <ReportButton questionId={questionId} questionText={questionText} />
                    </View>
                </View>
            </View>
        </View>
    );
}
