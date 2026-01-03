import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import Markdown from 'react-native-markdown-display';
import { cn } from '../../../utils/cn';
import { useThemeStore } from '../../../store/useThemeStore';

interface AnswerOptionsProps {
    options: string[];
    selectedAnswer: number | null;
    onAnswer: (idx: number) => void;
    feedback?: any;
    disabled?: boolean;
}

export function AnswerOptions({ options, selectedAnswer, onAnswer, feedback, disabled }: AnswerOptionsProps) {
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';

    const handleSelect = (idx: number) => {
        if (feedback || disabled) return;
        onAnswer(idx);
    };

    const getOptionStatus = (idx: number) => {
        if (!feedback) {
            return selectedAnswer === idx ? 'selected' : 'neutral';
        }
        const currentOptionText = options[idx];
        if (feedback.correct_text === currentOptionText) return 'correct';
        if (selectedAnswer === idx && !feedback.correct) return 'incorrect';
        return 'neutral';
    };

    // Calculate optimal layout
    const layoutConfig = useMemo(() => {
        const maxLength = Math.max(...options.map(opt => opt.length));
        const avgLength = options.reduce((sum, opt) => sum + opt.length, 0) / options.length;
        
        const shouldUseSingleColumn = maxLength > 50 || avgLength > 35;
        
        let optimalFontSize = 14;
        if (maxLength > 100) optimalFontSize = 11;
        else if (maxLength > 60) optimalFontSize = 12;
        else if (maxLength > 40) optimalFontSize = 13;
        
        return {
            useSingleColumn: shouldUseSingleColumn,
            fontSize: optimalFontSize,
            lineHeight: optimalFontSize * 1.4,
        };
    }, [options]);

    return (
        <View className={cn(
            "px-1 mb-2",
            layoutConfig.useSingleColumn ? "flex-col" : "flex-row flex-wrap"
        )}>
            {options.map((opt: string, idx: number) => {
                const status = getOptionStatus(idx);
                
                let bgClass = isHoliday ? "bg-white border-amber-200 shadow-sm" : "bg-card-secondary border-border shadow-sm";
                let textClass = "text-text-primary font-bold";
                let ornamentClass = isHoliday ? "bg-red-50 border-red-100" : "bg-accent/10";
                let ornamentText = isHoliday ? "text-red-800" : "text-accent";
                
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

                const widthClass = layoutConfig.useSingleColumn ? "w-full" : "w-[49%]";
                const marginClass = !layoutConfig.useSingleColumn && idx % 2 === 0 ? "mr-[2%]" : "";

                return (
                    <TouchableOpacity
                        key={idx}
                        onPress={() => handleSelect(idx)}
                        disabled={disabled || !!feedback}
                        className={cn(
                            "p-2.5 rounded-xl flex-row items-start transition-all mb-2 border min-h-[44px]",
                            widthClass,
                            marginClass,
                            bgClass,
                        )}
                        activeOpacity={0.7}
                    >
                        <View className={cn(
                            "w-7 h-7 items-center justify-center rounded-full mr-2.5 border border-black/10 flex-shrink-0 mt-0.5",
                            ornamentClass
                        )}>
                            <Text className={cn("text-[10px] font-black", ornamentText)}>
                                {String.fromCharCode(65 + idx)}
                            </Text>
                        </View>
                        
                        <View className="flex-1 justify-center flex-shrink">
                            <Markdown style={{ 
                                body: { 
                                    color: status === 'selected' || status === 'correct' || status === 'incorrect' ? '#1e293b' : '#334155',
                                    fontSize: layoutConfig.fontSize, 
                                    lineHeight: layoutConfig.lineHeight, 
                                    fontWeight: '600', 
                                    fontFamily: 'serif',
                                    flexWrap: 'wrap',
                                    flexShrink: 1
                                },
                            }}>
                                {opt}
                            </Markdown>
                        </View>
                    </TouchableOpacity>
                );
            })}
        </View>
    );
}
