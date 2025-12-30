import React from 'react';
import { View, Text, TouchableOpacity, Image } from 'react-native';
import { Folder, Gift, ChevronRight, ArrowRight } from 'lucide-react-native';
import { cn } from '../../../utils/cn';
import { ThemeDecoration } from '../../../theme/components/ThemeDecoration';

interface FolderCardProps {
    folder: string;
    onClick: () => void;
    styles: any;
    isHoliday: boolean;
}

export function FolderCard({ folder, onClick, styles, isHoliday }: FolderCardProps) {
    return (
        <TouchableOpacity
            onPress={onClick}
            className={cn(
                "group relative rounded-2xl overflow-hidden min-h-[160px] mb-4 p-6 items-center justify-center",
                styles.card
            )}
            style={{
                backgroundColor: isHoliday ? 'rgba(255, 255, 255, 0.95)' : 'rgba(30, 41, 59, 0.7)',
                borderWidth: isHoliday ? 1 : 2,
                borderColor: isHoliday ? 'rgba(226, 232, 240, 0.8)' : 'rgba(148, 163, 184, 0.2)', // Slate-200
                borderStyle: isHoliday ? 'solid' : 'dashed', // Clean solid border for snow theme
                shadowColor: isHoliday ? "#000" : "transparent",
                shadowOpacity: 0.05,
                shadowRadius: 10,
                elevation: 2
            }}
            activeOpacity={0.9}
        >
            <ThemeDecoration type="card-overlay" />
            <View className={cn(
                "w-16 h-16 items-center justify-center rounded-2xl mb-4",
                isHoliday ? "bg-sky-100" : "bg-cyan-500/10"
            )}>
                <Folder size={32} color={isHoliday ? "#0ea5e9" : "#06b6d4"} />
            </View>
            <Text className={cn("text-xl font-bold text-center", isHoliday ? "text-slate-800" : "text-white")}>
                {folder}
            </Text>
        </TouchableOpacity>
    );
}

interface QuizListCardProps {
    quiz: {
        id: string;
        title: string;
        description?: string;
        questions_count?: number;
    };
    onSelect: (id: string) => void;
    styles: any;
    isHoliday: boolean;
}

export function QuizListCard({ quiz, onSelect, styles, isHoliday }: QuizListCardProps) {
    return (
        <TouchableOpacity
            onPress={() => onSelect(quiz.id)}
            className={cn(
                "rounded-2xl overflow-hidden mb-4 min-h-[180px] flex-col relative",
                styles.card
            )}
            style={{
                backgroundColor: isHoliday ? 'rgba(255, 255, 255, 0.95)' : 'rgba(30, 41, 59, 0.7)',
                borderWidth: isHoliday ? 1 : 2,
                borderColor: isHoliday ? 'rgba(226, 232, 240, 0.8)' : 'rgba(148, 163, 184, 0.2)',
                borderStyle: isHoliday ? 'solid' : 'dashed',
                shadowColor: isHoliday ? "#000" : "transparent",
                shadowOpacity: 0.05,
                shadowRadius: 10,
                elevation: 2
            }}
            activeOpacity={0.9}
        >
            <ThemeDecoration type="card-overlay" />

            {isHoliday && (
                <View className="absolute top-4 right-4 z-10 opacity-80">
                    <Gift size={24} color="#0ea5e9" /> 
                </View>
            )}

            <View className={cn("p-6 flex-1")}>
                <Text className={cn("text-lg font-extrabold mb-3 pr-8", isHoliday ? "text-slate-900" : "text-white")}>
                    {quiz.title}
                </Text>

                <Text numberOfLines={2} className={cn("text-sm mb-6", isHoliday ? "text-slate-500" : "text-slate-300")}>
                    {quiz.description || "Интересная викторина для проверки знаний."}
                </Text>

                <View className={cn(
                    "mt-auto pt-4 flex-row items-center justify-between",
                )}>
                    <View className={cn("px-2 py-1 rounded shadow-sm", isHoliday ? "bg-slate-100" : "bg-slate-800")}>
                        <Text className={cn("text-[10px] font-bold", isHoliday ? "text-slate-500" : "text-slate-400")}>
                            {quiz.questions_count || 0} вопр.
                        </Text>
                    </View>
                    <View className="flex-row items-center">
                        <Text className={cn("text-xs font-bold mr-1", isHoliday ? "text-sky-600" : "text-cyan-400")}>
                            Играть
                        </Text>
                        <ArrowRight size={14} color={isHoliday ? "#0284c7" : "#22d3ee"} />
                    </View>
                </View>
            </View>
        </TouchableOpacity>
    );
}
