import { useState, useMemo, useEffect } from 'react';
import { View, Text, TextInput, ScrollView, TouchableOpacity, ActivityIndicator, ImageBackground } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { QuizRepository } from '../src/api/quizRepository';
import { Quiz } from '../src/types/quiz';
import { Search, Home, ChevronRight, Menu } from '../src/components/icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation, useRouter, useLocalSearchParams } from 'expo-router';
import { useTelegram } from '../src/hooks/useTelegram';
import { cn } from '../src/utils/cn';
import { QuizListCard, FolderCard } from '../src/features/home/components/QuizListItems';
import { SafeAreaView } from 'react-native-safe-area-context';
import { DrawerActions } from '@react-navigation/native';
import { useTranslation } from 'react-i18next';
import '../src/i18n';

import { useThemeStore } from '../src/store/useThemeStore';
import { useQuizStore } from '../src/store/quizStore'; // Import store

export default function HomeScreen() {
  const { toggleTheme, theme } = useThemeStore();
  const isHoliday = theme === 'holiday'; // Derived for specific logic if absolutely needed, but prefer className
  const router = useRouter();
  const params = useLocalSearchParams();
  const navigation = useNavigation();
  const { resetQuiz } = useQuizStore();
  const { t } = useTranslation();

  // Simple state navigation for folders since we don't have URL params like web
  // Stack structure: [''] -> ['Nature'] -> ['Nature', 'Dogs']
  const [pathStack, setPathStack] = useState(['']);

  // Reset quiz state on mount to ensure Sidebar shows correctly
  useEffect(() => {
      resetQuiz();
  }, []);

  // Handle deep linking via "folder" param
  useEffect(() => {
      // Check if folder is present and not empty
      if (params.folder) {
          const folderPath = String(params.folder).split('/');
          // Ensure we start with root ''
          setPathStack(['', ...folderPath]);
      } else {
          // If folder param is effectively empty or undefined, reset to root
          setPathStack(['']);
      }
  }, [params.folder]);

  const currentPath = pathStack.length > 1 ? pathStack.join('/').slice(1) : ''; // slice(1) to remove initial empty string

  const [searchQuery, setSearchQuery] = useState('');

  const { data: quizzes, isLoading, error } = useQuery<Quiz[]>({
    queryKey: ['quizzes'],
    queryFn: async () => {
      return await QuizRepository.getAll();
    }
  });

  interface DisplayData {
    items: Quiz[];
    folders: string[];
    isSearch?: boolean;
  }

  const displayData = useMemo<DisplayData>(() => {
    if (!quizzes) return { items: [], folders: [] };

    if (searchQuery) {
      const filtered = quizzes.filter(quiz => {
        const catTitle = typeof quiz.category === 'string' ? quiz.category : quiz.category?.title;
        return quiz.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (catTitle && catTitle.toLowerCase().includes(searchQuery.toLowerCase()));
      });
      // Return flat list for search
      return { items: filtered, folders: [], isSearch: true };
    }

    const items: Quiz[] = [];
    const folders = new Set<string>();

    quizzes.forEach(quiz => {
      const catTitle = typeof quiz.category === 'string' ? quiz.category : quiz.category?.title;
      // Normalize backslashes to forward slashes to handle mixed path separators
      const categoryTitle = (catTitle || '').replace(/\\/g, '/');

      if (currentPath === '') {
        if (categoryTitle === '' || categoryTitle === 'Разное') {
          items.push(quiz);
        } else {
          const firstPart = categoryTitle.split('/')[0];
          folders.add(firstPart);
        }
      } else {
        if (categoryTitle === currentPath) {
          items.push(quiz);
        } else if (categoryTitle.startsWith(currentPath + '/')) {
          const subPath = categoryTitle.slice(currentPath.length + 1);
          const firstPart = subPath.split('/')[0];
          folders.add(firstPart);
        }
      }
    });

    return { 
        items, 
        folders: Array.from(folders).sort(), 
        isSearch: false 
    };
  }, [quizzes, searchQuery, currentPath]); // Removing t from dependency to avoid loop, it's stable enough

  const navigateToFolder = (folder: string) => {
    setPathStack(prev => [...prev, folder]);
  };

  const navigateBreadcrumb = (index: number) => {
    setPathStack(prev => prev.slice(0, index + 1));
  };

  const selectQuiz = (id) => {
    // Construct semantic URL if we have a path
    // pathStack[0] is '', pathStack[1] is Category, etc.
    // We want /quiz/Category/Sub/ID
    
    // If we are deep in folders, use that for the URL
    if (pathStack.length > 1) {
        const categories = pathStack.slice(1).join('/'); // "Cinema/Transformers"
        router.push(`/quiz/${categories}/${id}`);
    } else {
        // Just ID if at root (or relies on quiz data later? simpler to just link ID)
        router.push(`/quiz/${id}`);
    }
  };
  




  if (isLoading) return (
    <View className="flex-1 items-center justify-center bg-black">
      <ActivityIndicator size="large" color="#ffffff" />
    </View>
  );

  const bgImage = require('../assets/home-alone-bg.jpg');

  return (
    <View className="flex-1">
      <ImageBackground
        source={bgImage}
        className="flex-1 w-full h-full"
        style={{ width: '100%', height: '100%' }}
        resizeMode="cover"
      >
        <LinearGradient
            colors={isHoliday ? ['rgba(28, 25, 23, 0.4)', 'rgba(69, 10, 10, 0.6)'] : ['rgba(0,0,0,0.3)', 'rgba(0,0,0,0.7)']}
            style={{ flex: 1 }}
        >
            <SafeAreaView className="flex-1 w-full h-full items-center">
      {/* Background Image could go here using ImageBackground, using simple color for now */}

      <ScrollView className="flex-1 w-full" contentContainerStyle={{ paddingBottom: 100 }}>
        <View className="w-full max-w-5xl mx-auto px-4">
            {/* Header */}
            <View className="mt-8 mb-6">
                <View className="flex-row justify-between items-center mb-6">
                    <View className="flex-1">
                        <View className="flex-row items-center mb-1">
                            {isHoliday && <Text className="mr-2 text-2xl">🎄</Text>}
                            <Text className={cn(
                                "text-4xl font-black font-serif tracking-tight",
                                isHoliday ? "text-amber-50" : "text-white"
                            )}>
                                {isHoliday ? t('home.holiday_title') : t('home.title')}
                            </Text>
                        </View>
                        <Text className={cn(
                            "text-base font-medium opacity-80",
                            isHoliday ? "text-amber-100/90" : "text-slate-400"
                        )}>
                            {isHoliday ? t('home.holiday_subtitle') : t('home.subtitle')}
                        </Text>
                    </View>
                    <TouchableOpacity 
                        onPress={() => navigation.dispatch(DrawerActions.openDrawer())}
                        className={cn(
                            "w-12 h-12 items-center justify-center rounded-2xl shadow-xl",
                            isHoliday ? "bg-red-600 shadow-red-900/20 shadow-offset-[0,4] shadow-radius-10" : "bg-white/10"
                        )}
                        style={isHoliday ? { 
                            shadowColor: '#450a0a',
                            shadowOffset: { width: 0, height: 4 },
                            shadowOpacity: 0.3,
                            shadowRadius: 8,
                            elevation: 8
                        } : {}}
                    >
                        <Menu size={24} color="#fff" strokeWidth={2.5} />
                    </TouchableOpacity>
                </View>
            </View>

        {/* Search */}
        <View className="mb-8 relative">
            <View className="absolute left-4 top-4 z-10">
            <Search size={20} color={isHoliday ? "#64748b" : "#666"} />
            </View>
            <TextInput
            placeholder={t('home.search_placeholder')}
            placeholderTextColor={isHoliday ? "#94a3b8" : "#666"}
            value={searchQuery}
            onChangeText={setSearchQuery}
            className={cn(
                "w-full pl-12 pr-4 py-3 rounded-2xl text-lg border",
                isHoliday ? "bg-white/90 text-slate-900 border-white/20 shadow-sm" : "bg-neutral-900 text-white border-transparent"
            )}
            />
        </View>

        {/* Breadcrumbs */}
        {!searchQuery && pathStack.length > 0 && (
          <View className="flex-row flex-wrap gap-2 mb-6">
            {pathStack.map((part, index) => (
              <TouchableOpacity
                key={index}
                onPress={() => navigateBreadcrumb(index)}
                className="flex-row items-center"
              >
                {index === 0 ? <Home size={14} color={isHoliday ? "#fbbf24" : "#999"} /> : null}
                <Text className={cn(
                  "text-sm font-medium",
                  index === pathStack.length - 1 
                    ? (isHoliday ? "text-white font-bold" : "text-white font-bold") 
                    : (isHoliday ? "text-amber-200/80" : "text-gray-500")
                )}>
                  {index === 0 ? t('sidebar.home') : t(`category.${part.toLowerCase()}`, part)}
                </Text>
                {index < pathStack.length - 1 && <ChevronRight size={14} color={isHoliday ? "#fbbf24" : "#555"} />}
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Content */}
        {/* Categories Section */}
        {displayData.folders.length > 0 && (
          <View className="mb-10">
            <View className="flex-row items-center mb-6">
              <View className={cn("h-[1px] flex-1", isHoliday ? "bg-amber-100/20" : "bg-white/10")} />
              <Text className={cn("mx-4 text-[10px] font-black uppercase tracking-[3px]", isHoliday ? "text-amber-200" : "text-slate-500")}>
                {t('home.categories', 'Категории')}
              </Text>
              <View className={cn("h-[1px] flex-1", isHoliday ? "bg-amber-100/20" : "bg-white/10")} />
            </View>
            <View className="flex-row flex-wrap -mx-3">
              {displayData.folders.map(folder => (
                <View key={folder} className="w-1/2 md:w-1/4 p-3" style={{ minWidth: 140 }}>
                  <FolderCard
                    folder={folder}
                    onClick={() => navigateToFolder(folder)}
                    isHoliday={isHoliday}
                  />
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Quizzes Section */}
        {displayData.items.length > 0 && (
          <View>
            <View className="flex-row items-center mb-6">
              <View className={cn("h-[1px] flex-1", isHoliday ? "bg-amber-100/20" : "bg-white/10")} />
              <Text className={cn("mx-4 text-[10px] font-black uppercase tracking-[3px]", isHoliday ? "text-amber-200" : "text-slate-500")}>
                {t('home.quizzes', 'Викторины')}
              </Text>
              <View className={cn("h-[1px] flex-1", isHoliday ? "bg-amber-100/20" : "bg-white/10")} />
            </View>
            <View className="flex-row flex-wrap -mx-3">
              {displayData.items.map(quiz => (
                <View key={quiz.id} className="w-full md:w-1/3 p-3" style={{ minWidth: 260 }}>
                  <QuizListCard
                    quiz={quiz}
                    onSelect={selectQuiz}
                    isHoliday={isHoliday}
                  />
                </View>
              ))}
            </View>
          </View>
        )}
      </View>
      </ScrollView>
        </SafeAreaView>
      </LinearGradient>
      </ImageBackground>
    </View>
  );
}
