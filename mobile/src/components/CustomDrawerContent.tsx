import React from 'react';
import { View, Text, TouchableOpacity, ImageBackground } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { DrawerContentScrollView } from '@react-navigation/drawer';
import { useThemeStore } from '../store/useThemeStore';
import { useQuizStore } from '../store/quizStore';
import { Palette, User, LogOut, CheckCircle, XCircle, Circle, ChevronRight, Home } from './icons';
import { cn } from '../utils/cn';

import { useTranslation } from 'react-i18next';
// ... imports

export function CustomDrawerContent(props: any) {
  const { toggleTheme, theme } = useThemeStore(); // Directly use theme from store
  const { t } = useTranslation();
  const { 
    quizId, 
    quizTitle, 
    questions, 
    answers, 
    feedback, 
    selectQuestion,
    currentQuestionIndex
  } = useQuizStore();

  const getThemeName = () => {
    const names: Record<string, string> = {
      'holiday': t('theme.holiday', '🎄 Новый год'),
      'night': t('theme.night', '🌙 Ночь'),
      'summer': t('theme.summer', '☀️ Лето'),
      'cyber': t('theme.cyber', '🤖 Кибер'),
      'autumn': t('theme.autumn', '🍂 Осень'),
      'romance': t('theme.romance', '💕 Романтика')
    };
    return names[theme] || theme;
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
    // We can use a semantic color var for icons too if needed, 
    // but for now let's keep it simple with hardcoded 'active' vs 'inactive' semantic-ish colors
    // or use conditional classes on the Icon wrapper if possible (not easy with direct Lucide props).
    // Let's rely on standard colors for status (red/green) and theme accent for current.
    
    // NOTE: Lucide icons expect hex/rgb strings usually, not css vars directly in 'color' prop easily 
    // without helper. For now we stick to safe colors or simple logic.
    const activeColor = "#fbbf24"; // Amber-400 equivalent (our accent)
    const inactiveColor = "#9ca3af"; // Gray-400

    if (isCurrent) {
      return <ChevronRight size={18} color={activeColor} />;
    }
    
    switch (status) {
      case 'correct':
        return <CheckCircle size={18} color="#22c55e" />;
      case 'incorrect':
        return <XCircle size={18} color="#ef4444" />;
      default:
        return <Circle size={18} color={inactiveColor} />;
    }
  };

  const bgImage = require('../../assets/home-alone-bg.jpg');
  const isInQuiz = quizId && questions.length > 0;

  // Semantic styles mapping
  // We use our defined Tailwind classes: bg-primary, text-primary, border-border, etc.
  
  return (
    <View className="flex-1 overflow-hidden bg-primary">
        <ImageBackground
            source={bgImage}
            className="flex-1 w-full h-full"
            style={{ width: '100%', height: '100%' }}
            resizeMode="cover"
        >
            <LinearGradient
            // We can't easily use CSS vars in LinearGradient 'colors' prop array in RN yet 
            // without resolving them. For now, we keep the semi-transparent overlay 
            // but maybe simplifying to a single CSS-based overlay View if we wanted full purity.
            // Let's keep it visually compatible for now.
            colors={['rgba(var(--bg-primary), 0.85)', 'rgba(var(--bg-secondary), 0.95)']}
            style={{ flex: 1 }}
            >
            <View className="flex-1 m-2 rounded-[2.5rem] overflow-hidden border border-border bg-white/5">
                <DrawerContentScrollView {...props} contentContainerStyle={{ paddingTop: 0 }}>
                {/* User Profile Section */}
                <View className="p-6 mb-4 border-b border-border">
                    <View className="w-16 h-16 rounded-full mb-3 items-center justify-center overflow-hidden bg-white/10 border border-white/20">
                        <User size={32} color="rgba(var(--text-primary), 1)" />
                    </View>
                    <Text className="text-xl font-bold mb-1 font-serif text-primary">
                        {t('sidebar.guest', 'Гость')}
                    </Text>
                    <Text className="text-sm text-text-sub">
                        {t('sidebar.login_prompt', 'Войдите, чтобы сохранять прогресс')}
                    </Text>
                </View>

            {/* Conditional: Question List OR Navigation */}
            {isInQuiz ? (
              <View className="px-4 mb-6">
                <Text className="text-xs font-bold uppercase mb-3 ml-2 text-text-sub">
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
                          isCurrent ? "bg-accent/20 border border-accent/30" : "bg-white/5"
                        )}
                      >
                        <View className="mr-3">
                          {getStatusIcon(status, isCurrent)}
                        </View>
                        <View className="flex-1">
                          <Text 
                            className={cn(
                              "text-sm font-medium",
                              isCurrent ? "text-accent" : "text-text-sub"
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
                      <Text className="text-xs font-bold uppercase mb-3 ml-2 text-text-sub">
                          {t('sidebar.menu', 'Меню')}
                      </Text>
                      <TouchableOpacity 
                          onPress={() => props.navigation.navigate('index')}
                          className="flex-row items-center p-3 rounded-xl mb-1 bg-white/5 active:bg-white/10"
                      >
                          <Home size={20} color="rgba(var(--text-primary), 1)" />
                          <Text className="ml-3 font-medium text-primary">{t('sidebar.home', 'Главная')}</Text>
                      </TouchableOpacity>
                      
                      <TouchableOpacity 
                          disabled={true}
                          className="flex-row items-center p-3 rounded-xl opacity-50"
                      >
                          <User size={20} color="rgba(var(--text-primary), 1)" />
                          <Text className="ml-3 font-medium text-primary">{t('sidebar.profile', 'Профиль (Скоро)')}</Text>
                      </TouchableOpacity>
                  </View>

                  {/* Guest Stats (Simplified) */}
                   <View className="p-4 rounded-xl bg-white/5 border border-white/10">
                      <Text className="text-xs font-bold uppercase mb-2 text-text-sub">
                          {t('sidebar.stats_title', 'Ваша статистика')}
                      </Text>
                      <Text className="text-sm mb-2 text-text-sub">
                        {t('sidebar.quizzes_completed', 'Пройдено тестов')}: <Text className="font-bold text-accent">0</Text>
                      </Text>
                  </View>
              </View>
            )}

            {/* Theme Toggler in Drawer */}
            <View className="px-4 mt-6">
                <Text className="text-xs font-bold uppercase mb-3 ml-2 text-text-sub">{t('sidebar.settings', 'Настройки')}</Text>
                <TouchableOpacity 
                    onPress={toggleTheme}
                    className="flex-row items-center p-3 rounded-xl active:bg-white/5 bg-white/5 border border-white/10"
                >
                    <Palette size={20} color="rgba(var(--accent), 1)" />
                    <View className="ml-3">
                        <Text className="font-medium text-primary">{t('sidebar.theme', 'Тема оформления')}</Text>
                        <Text className="text-xs text-text-sub">{getThemeName()}</Text>
                    </View>
                </TouchableOpacity>
            </View>
            </DrawerContentScrollView>

            {/* Footer */}
            <View className="p-4 border-t pb-8 border-border">
            <TouchableOpacity className="flex-row items-center p-2">
                <LogOut size={20} color="rgba(var(--error), 1)" />
                <Text className="ml-3 font-medium text-text-sub">{t('sidebar.logout', 'Выйти')}</Text>
            </TouchableOpacity>
            </View>
                </View>
            </LinearGradient>
        </ImageBackground>
    </View>
  );
}
