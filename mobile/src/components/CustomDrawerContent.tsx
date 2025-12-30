import React from 'react';
import { View, Text, TouchableOpacity, ImageBackground } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { DrawerContentScrollView, DrawerItemList } from '@react-navigation/drawer';
import { useThemeStyles } from '../hooks/useThemeStyles';
import { useThemeStore } from '../store/useThemeStore';
import { useQuizStore } from '../store/quizStore';
import { Palette, User, LogOut, CheckCircle, XCircle, Circle, ChevronRight, Home } from 'lucide-react-native';
import { cn } from '../utils/cn';

export function CustomDrawerContent(props: any) {
  const { styles, isHoliday, themeId } = useThemeStyles();
  const { toggleTheme } = useThemeStore();
  const { 
    quizId, 
    quizTitle, 
    questions, 
    currentQuestionIndex, 
    answers, 
    feedback, 
    selectQuestion 
  } = useQuizStore();

  const getThemeName = () => {
    const names: Record<string, string> = {
      'holiday': '🎄 Новый год',
      'night': '🌙 Ночь',
      'summer': '☀️ Лето',
      'cyber': '🤖 Кибер',
      'autumn': '🍂 Осень',
      'romance': '💕 Романтика'
    };
    return names[themeId] || themeId;
  };

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

  // Get status icon
  const getStatusIcon = (status: string, isCurrent: boolean) => {
    if (isCurrent) {
      return <ChevronRight size={18} color={isHoliday ? "#fbbf24" : "#60a5fa"} />;
    }
    
    switch (status) {
      case 'correct':
        return <CheckCircle size={18} color="#22c55e" />;
      case 'incorrect':
        return <XCircle size={18} color="#ef4444" />;
      default:
        return <Circle size={18} color={isHoliday ? "#d1d5db" : "#6b7280"} />;
    }
  };

  const bgImage = require('../../assets/home-alone-bg.jpg');
  const isInQuiz = quizId && questions.length > 0;

  return (
    <View className="flex-1 overflow-hidden">
        <ImageBackground
            source={bgImage}
            className="flex-1 w-full h-full"
            style={{ width: '100%', height: '100%' }}
            resizeMode="cover"
        >
            <LinearGradient
            colors={isHoliday ? ['rgba(255, 250, 240, 0.85)', 'rgba(255, 240, 230, 0.95)'] : ['rgba(0,0,0,0.85)', 'rgba(26,26,26,0.95)']}
            style={{ flex: 1 }}
            >
            <View className={cn("flex-1 m-2 rounded-[2.5rem] overflow-hidden border", isHoliday ? "border-white/20 bg-white/50" : "border-gray-800 bg-transparent")}>
                <DrawerContentScrollView {...props} contentContainerStyle={{ paddingTop: 0 }}>
                {/* User Profile Section */}
                <View className={cn("p-6 mb-4 border-b", isHoliday ? "border-black/5" : "border-gray-800")}>
                    <View className={cn("w-16 h-16 rounded-full mb-3 items-center justify-center overflow-hidden", isHoliday ? "bg-amber-100/50 border border-amber-200" : "bg-gray-700")}>
                        <User size={32} color={isHoliday ? "#92400e" : "#ccc"} />
                    </View>
                    <Text className={cn("text-xl font-bold mb-1 font-serif", isHoliday ? "text-amber-900" : "text-white")}>
                        Гость
                    </Text>
                    <Text className={cn("text-sm", isHoliday ? "text-amber-900/60" : "text-gray-500")}>
                        Войдите, чтобы сохранять прогресс
                    </Text>
                </View>

            {/* Conditional: Question List OR Navigation */}
            {/* Conditional: Question List OR Navigation */}
            {isInQuiz ? (
              <View className="px-4 mb-6">
                <Text className={cn("text-xs font-bold uppercase mb-3 ml-2", isHoliday ? "text-amber-200/60" : "text-gray-500")}>
                  {quizTitle || 'Quiz'}
                </Text>
                <View>
                  {questions.map((question, index) => {
                    const status = getQuestionStatus(index);
                    const isCurrent = index === currentQuestionIndex;
                    
                    return (
                      <TouchableOpacity
                        key={question.id}
                        onPress={() => {
                          selectQuestion(index);
                          props.navigation.closeDrawer();
                        }}
                        className={cn(
                          "flex-row items-center p-3 rounded-lg mb-2",
                          isCurrent && (isHoliday ? "bg-red-600/20 border border-red-600/30" : "bg-blue-600/20 border border-blue-600/30"),
                          !isCurrent && (isHoliday ? "bg-white/5" : "bg-gray-800/50")
                        )}
                      >
                        <View className="mr-3">
                          {getStatusIcon(status, isCurrent)}
                        </View>
                        <View className="flex-1">
                          <Text 
                            className={cn(
                              "text-sm font-medium",
                              isCurrent && (isHoliday ? "text-amber-100" : "text-blue-300"),
                              !isCurrent && (isHoliday ? "text-white/80" : "text-gray-300")
                            )}
                            numberOfLines={1}
                          >
                            {index + 1}. {question.text}
                          </Text>
                        </View>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            ) : (
              <View className="px-4 mb-6">
                  {/* Navigation Menu */}
                  <View className="mb-6">
                      <Text className={cn("text-xs font-bold uppercase mb-3 ml-2", isHoliday ? "text-amber-200/60" : "text-gray-500")}>
                          Меню
                      </Text>
                      <TouchableOpacity 
                          onPress={() => props.navigation.navigate('index')}
                          className={cn("flex-row items-center p-3 rounded-xl mb-1", isHoliday ? "bg-white/10" : "bg-gray-800/50")}
                      >
                          <Home size={20} color={isHoliday ? "#fbbf24" : "#fff"} />
                          <Text className={cn("ml-3 font-medium", isHoliday ? "text-amber-100" : "text-white")}>Главная</Text>
                      </TouchableOpacity>
                      
                      <TouchableOpacity 
                          disabled={true}
                          className={cn("flex-row items-center p-3 rounded-xl opacity-50")}
                      >
                          <User size={20} color={isHoliday ? "#fbbf24" : "#fff"} />
                          <Text className={cn("ml-3 font-medium", isHoliday ? "text-amber-100" : "text-white")}>Профиль (Скоро)</Text>
                      </TouchableOpacity>
                  </View>

                  {/* Guest Stats (Simplified) */}
                   <View className={cn("p-4 rounded-xl", isHoliday ? "bg-white/5 border border-white/10" : "bg-gray-800/30")}>
                      <Text className={cn("text-xs font-bold uppercase mb-2", isHoliday ? "text-amber-200/60" : "text-gray-500")}>
                          Ваша статистика
                      </Text>
                      <Text className={cn("text-sm mb-2", isHoliday ? "text-amber-100/80" : "text-gray-400")}>
                        Пройдено тестов: <Text className="font-bold text-white">0</Text>
                      </Text>
                  </View>
              </View>
            )}

            {/* Theme Toggler in Drawer */}
            <View className="px-4 mt-6">
                <Text className={cn("text-xs font-bold uppercase mb-3 ml-2", isHoliday ? "text-amber-200/60" : "text-gray-500")}>Настройки</Text>
                <TouchableOpacity 
                    onPress={toggleTheme}
                    className={cn("flex-row items-center p-3 rounded-xl active:bg-white/5", isHoliday ? "bg-white/5 border border-white/10" : "")}
                >
                    <Palette size={20} color={isHoliday ? "#fbbf24" : "#fff"} />
                    <View className="ml-3">
                        <Text className={cn("font-medium", isHoliday ? "text-amber-100" : "text-white")}>Тема оформления</Text>
                        <Text className={cn("text-xs", isHoliday ? "text-white/60" : "text-gray-500")}>{getThemeName()}</Text>
                    </View>
                </TouchableOpacity>
            </View>
            </DrawerContentScrollView>

            {/* Footer */}
            <View className={cn("p-4 border-t pb-8", isHoliday ? "border-white/10" : "border-gray-800")}>
            <TouchableOpacity className="flex-row items-center p-2">
                <LogOut size={20} color={isHoliday ? "#ef4444" : "#666"} />
                <Text className={cn("ml-3 font-medium", isHoliday ? "text-white/60" : "text-gray-500")}>Выйти</Text>
            </TouchableOpacity>
            </View>
                </View>
            </LinearGradient>
        </ImageBackground>
    </View>
  );
}
