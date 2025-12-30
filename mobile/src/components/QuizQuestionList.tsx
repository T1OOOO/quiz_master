import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { CheckCircle, XCircle, Circle, ChevronRight, X, Gift } from 'lucide-react-native';
import { useThemeStyles } from '../hooks/useThemeStyles';
import { cn } from '../utils/cn';
import { useQuizStore } from '../store/quizStore';

interface QuizQuestionListProps {
  onClose?: () => void;
  className?: string; // Add className support just in case
}

export function QuizQuestionList({ onClose }: QuizQuestionListProps) {
  const { styles, isHoliday } = useThemeStyles();
  const { questions, currentQuestionIndex, answers, feedback, quizTitle, selectQuestion } = useQuizStore();

  // Get question status
  const getQuestionStatus = (index: number) => {
    const question = questions[index];
    if (!question) return 'unanswered';
    
    const answer = answers[question.id];
    if (answer === undefined) return 'unanswered';
    
    const feedbackItem = feedback[question.id];
    if (!feedbackItem) return 'answered';
    
    return feedbackItem.correct ? 'correct' : 'incorrect';
  };

  const handleQuestionClick = (index: number) => {
    selectQuestion(index);
  };

  // Get status icon and color
  const getStatusDisplay = (index: number, status: string, isCurrent: boolean) => {
    if (isCurrent) {
      return {
        icon: <Gift size={20} color="#92400e" />,
        containerClass: "bg-amber-100",
        textClass: "text-amber-950 font-black"
      };
    }
    
    switch (status) {
      case 'correct':
        return {
          icon: <CheckCircle size={18} color="white" />,
          containerClass: "bg-emerald-600/20",
          textClass: "text-white font-bold"
        };
      case 'incorrect':
        return {
          icon: <XCircle size={18} color="white" />,
          containerClass: "bg-rose-600/20",
          textClass: "text-white font-bold"
        };
      default:
        return {
          icon: <Text className="text-[12px] font-bold text-red-100">{index + 1}</Text>,
          containerClass: "bg-red-600/20",
          textClass: "text-white font-bold"
        };
    }
  };

  return (
      <View className={cn(
        "w-full h-full border-r overflow-hidden relative",
        styles.sidebar
      )}>
        {/* Festive Header - High Contrast */}
        <View className={cn(
          "flex-row items-center border-b px-5 pt-12 pb-6 bg-white z-20 shadow-sm",
          isHoliday ? "border-red-100" : "border-white/10"
        )}>
          <View className="mr-3 p-2 bg-red-100 rounded-xl -rotate-2 border border-red-200">
             <Gift size={24} color="#dc2626" />
          </View>
          <View>
            <Text className="text-xl font-black text-red-900 leading-none">
              QUESTIONS
            </Text>
            <Text className="text-xs font-bold text-red-400 uppercase tracking-widest">
              Your Gift List
            </Text>
          </View>
          
          {onClose && (
            <TouchableOpacity onPress={onClose} className="absolute right-4 top-10 p-2 bg-white rounded-full shadow-sm border border-stone-100">
              <X size={18} color="#ef4444" />
            </TouchableOpacity>
          )}
        </View>
        
        {/* Decorative Timeline Line */}
        {isHoliday && (
            <View className="absolute left-6 top-0 bottom-0 w-1 bg-red-100/50 z-0" />
        )}

        <ScrollView 
          showsVerticalScrollIndicator={false}
          className="flex-1 z-10"
          contentContainerStyle={{ paddingVertical: 20, paddingHorizontal: 10 }}
        >
          {questions.map((question, index) => {
            const status = getQuestionStatus(index);
            const isCurrent = index === currentQuestionIndex;
            const display = getStatusDisplay(index, status, isCurrent);
            
            // Map status to theme styles
            let itemStyle = styles.item;
            
            // Dynamic Classes for "Fun" feel
            const rotationClass = isCurrent ? "-rotate-1" : index % 2 === 0 ? "rotate-0" : "rotate-0";
            const scaleClass = isCurrent ? "scale-105 z-20" : "scale-100 z-10";
            
            if (isCurrent) itemStyle = cn(itemStyle, styles.itemActive);
            else if (status === 'correct') itemStyle = cn(itemStyle, styles.itemCorrect);
            else if (status === 'incorrect') itemStyle = cn(itemStyle, styles.itemIncorrect);
            else itemStyle = cn(itemStyle, styles.itemUnanswered);
            
            return (
              <View key={question.id} className="flex-row items-center relative mb-4">
                 {/* Timeline Connector Dot */}
                 {isHoliday && (
                     <View className={cn(
                         "absolute left-[-4px] w-3 h-3 rounded-full border-2 border-white z-0",
                         isCurrent ? "bg-amber-400 w-4 h-4 left-[-6px]" : "bg-red-200"
                     )} />
                 )}
                 
                 <TouchableOpacity
                    onPress={() => handleQuestionClick(index)}
                    className={cn(
                      "flex-row items-center flex-1 ml-4 shadow-sm",
                      itemStyle,
                      rotationClass,
                      scaleClass
                    )}
                    activeOpacity={0.9}
                  >
                    <View className={cn(
                      "w-10 h-10 rounded-full items-center justify-center mr-3 shadow-inner",
                      display.containerClass
                    )}>
                      {display.icon}
                    </View>
                    <View className="flex-1">
                      <Text 
                        className={cn(
                          "text-[13px] leading-tight",
                          display.textClass
                        )}
                        numberOfLines={2}
                      >
                        {question.text}
                      </Text>
                    </View>
                  </TouchableOpacity>
              </View>
            );
          })}
        </ScrollView>
      </View>
  );
}
