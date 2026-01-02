import React from 'react';
import { View, Text, TouchableOpacity, FlatList } from 'react-native';
import { CheckCircle, XCircle, ChevronRight, X, Gift, ArrowLeft } from './icons';
import { useThemeStore } from '../store/useThemeStore';
import { cn } from '../utils/cn';
import { useQuizStore } from '../store/quizStore';
import { useTranslation } from 'react-i18next';

interface QuizQuestionListProps {
  onClose?: () => void;
  className?: string; // Add className support just in case
}

export function QuizQuestionList({ onClose }: QuizQuestionListProps) {
  const { theme } = useThemeStore();
  const { t } = useTranslation();
  const isHoliday = theme === 'holiday';
  const { questions, currentQuestionIndex, answers, feedback, quizTitle, selectQuestion } = useQuizStore();
  const flatListRef = React.useRef<FlatList>(null);

  // Auto-scroll to current question
  React.useEffect(() => {
    if (questions.length > 0 && flatListRef.current) {
        flatListRef.current.scrollToIndex({ 
            index: Math.max(0, currentQuestionIndex - 1), 
            animated: true, 
            viewPosition: 0 // scroll so previous item is at top
        });
    }
  }, [currentQuestionIndex]);

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
        icon: <Gift size={20} color={isHoliday ? "#92400e" : "rgba(var(--text-primary), 1)"} />,
        containerClass: isHoliday ? "bg-amber-100" : "bg-accent/20",
        textClass: isHoliday ? "text-amber-950 font-black" : "text-text-primary font-bold"
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
          icon: <Text className="text-[12px] font-bold text-text-secondary">{index + 1}</Text>,
          containerClass: "bg-surface-secondary",
          textClass: "text-text-primary font-bold"
        };
    }
  };

  return (
      <View className={cn(
        "w-full h-full border-r overflow-hidden relative border-border", // Removed bg-card to let wrapper bg show
        // Semantic BG handled by wrapper in [...id].tsx for glass effect
      )}>
        {/* Festive/Standard Sidebar Header */}
        <View className={cn(
          "flex-row items-center border-b px-5 pt-12 pb-6 z-20 shadow-sm transition-colors",
          isHoliday ? "bg-white border-red-100" : "bg-card border-border"
        )}>
           {isHoliday ? (
              <View className="mr-3 p-2 bg-red-100 rounded-xl -rotate-2 border border-red-200">
                 <Gift size={24} color="#dc2626" />
              </View>
           ) : (
              <View className="mr-3">
                 <TouchableOpacity 
                    onPress={onClose}
                    disabled={!onClose}
                    className="p-2 bg-accent/10 rounded-xl border border-accent/20 active:opacity-70"
                 >
                    {/* Replaced Dot with ArrowLeft as requested */}
                    <ArrowLeft size={24} color="rgba(var(--accent), 1)" />
                 </TouchableOpacity>
              </View>
           )}
          
          <View>
            <Text className={cn("text-xl font-black leading-none", isHoliday ? "text-red-900" : "text-text-primary")}>
              {t('quiz.questions').toUpperCase()}
            </Text>
            <Text className={cn("text-xs font-bold uppercase tracking-widest", isHoliday ? "text-red-400" : "text-text-secondary")}>
              {isHoliday ? t('quiz.gift_list') : t('home.questions_count', { count: questions.length })}
            </Text>
          </View>
          
          {onClose && (
            <TouchableOpacity onPress={onClose} className="absolute right-4 top-10 p-2 bg-card rounded-full shadow-sm border border-border">
              <X size={18} color="rgba(var(--text-secondary), 1)" />
            </TouchableOpacity>
          )}
        </View>
        
        {/* Decorative Timeline Line */}
        {isHoliday && (
            <View className="absolute left-6 top-0 bottom-0 w-1 bg-red-100/50 z-0" />
        )}

        <FlatList
          ref={flatListRef}
          data={questions}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={true}
          className="flex-1 z-10"
          contentContainerStyle={{ paddingVertical: 32, paddingHorizontal: 16 }} // Increased padding to prevent clipping of scaled/rotated items
          onScrollToIndexFailed={(info) => {
            const wait = new Promise(resolve => setTimeout(resolve, 500));
            wait.then(() => {
              flatListRef.current?.scrollToIndex({ index: info.index, animated: true, viewPosition: 0 });
            });
          }}
          renderItem={({ item: question, index }) => {
            const status = getQuestionStatus(index);
            const isCurrent = index === currentQuestionIndex;
            const display = getStatusDisplay(index, status, isCurrent);
            
            // Map status to semantic classes instead of styles.item object
            let itemClasses = "bg-card border-transparent"; // Default
            if (isCurrent) itemClasses = isHoliday ? "bg-amber-50 border-amber-200" : "bg-accent/10 border-accent";
            else if (status === 'correct') itemClasses = "bg-emerald-900/20 border-emerald-500/50";
            else if (status === 'incorrect') itemClasses = "bg-rose-900/20 border-rose-500/50";
            else itemClasses = "bg-card-secondary border-transparent";
            
            // Dynamic Classes for "Fun" feel
            // Reduced rotation to minimize clipping risk
            const rotationClass = isCurrent ? "-rotate-1" : "rotate-0";
            const scaleClass = isCurrent ? "scale-105 z-20" : "scale-100 z-10";
            
            return (
              <View className="flex-row items-center relative mb-4 pl-2">
                 {isHoliday && (
                     <View className={cn(
                         "absolute left-[-4px] w-3 h-3 rounded-full border-2 border-white z-0",
                         isCurrent ? "bg-amber-400 w-4 h-4 left-[-6px]" : "bg-red-200"
                     )} />
                 )}
                 
                 <TouchableOpacity
                    onPress={() => handleQuestionClick(index)}
                    className={cn(
                      "flex-row items-center flex-1 ml-4 shadow-sm p-3 rounded-xl border transition-all",
                      itemClasses,
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
                          "text-[13px] leading-tight font-medium",
                          isHoliday ? "text-stone-800" : "text-text-primary"
                        )}
                        numberOfLines={2}
                      >
                        {question.text}
                      </Text>
                    </View>
                  </TouchableOpacity>
              </View>
            );
          }}
        />
      </View>
  );
}
