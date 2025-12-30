import { useState, useMemo, useEffect } from 'react';
import { View, Text, TextInput, ScrollView, TouchableOpacity, ActivityIndicator, ImageBackground } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { QuizRepository } from '../src/api/quizRepository';
import { Quiz } from '../src/types/quiz';
import { Search, Home, ChevronRight, Menu } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation } from 'expo-router';
import { useThemeStyles } from '../src/hooks/useThemeStyles';
import { useTelegram } from '../src/hooks/useTelegram';
import { cn } from '../src/utils/cn';
import { QuizListCard, FolderCard } from '../src/features/home/components/QuizListItems';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { DrawerActions } from '@react-navigation/native';
import { translateCategory } from '../src/utils/translations';

import { useQuizStore } from '../src/store/quizStore'; // Import store

export default function HomeScreen() {
  const { styles, isHoliday, config, themeId } = useThemeStyles();
  const router = useRouter();
  const params = useLocalSearchParams();
  const navigation = useNavigation();
  const { resetQuiz } = useQuizStore(); // Destructure resetQuiz

  // Simple state navigation for folders since we don't have URL params like web
  // Stack structure: [''] -> ['Nature'] -> ['Nature', 'Dogs']
  const [pathStack, setPathStack] = useState(['']);

  // Reset quiz state on mount to ensure Sidebar shows correctly
  useEffect(() => {
      resetQuiz();
  }, []);

  // Handle deep linking via "folder" param
  useEffect(() => {
      if (params.folder) {
          const folderPath = String(params.folder).split('/');
          // Ensure we start with root ''
          setPathStack(['', ...folderPath]);
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

    return { items, folders: Array.from(folders).sort(), isSearch: false };
  }, [quizzes, searchQuery, currentPath]);

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
            <View className="mt-6 mb-8">
            <View className="flex-row justify-between items-start mb-2">
            <View className="flex-1">
                <Text className={cn("text-3xl font-black mb-2 font-serif", isHoliday ? "text-amber-100" : "text-white")}>
                {isHoliday ? "🎄 Новогодние викторины" : "Викторины"}
                </Text>
                <Text className={cn("text-base font-medium", isHoliday ? "text-amber-200/80" : "text-gray-400")}>
                {isHoliday ? "Выберите подарок под елкой" : "Выберите тему"}
                </Text>
            </View>
            <TouchableOpacity 
                onPress={() => navigation.dispatch(DrawerActions.openDrawer())}
                className={cn("p-2 rounded-xl shadow-sm", isHoliday ? "bg-white/10 border border-white/20" : "bg-white/10")}
            >
                <Menu size={24} color="#fff" />
            </TouchableOpacity>
            </View>
        </View>

        {/* Search */}
        <View className="mb-8 relative">
            <View className="absolute left-4 top-4 z-10">
            <Search size={20} color={isHoliday ? "#64748b" : "#666"} />
            </View>
            <TextInput
            placeholder="Поиск..."
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
                  {index === 0 ? " Главная" : translateCategory(part)}
                </Text>
                {index < pathStack.length - 1 && <ChevronRight size={14} color={isHoliday ? "#fbbf24" : "#555"} />}
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Content */}
        <View>
          {displayData.folders.map(folder => (
            <FolderCard
              key={folder}
              folder={translateCategory(folder)}
              onClick={() => navigateToFolder(folder)}
              styles={styles}
              isHoliday={isHoliday}
            />
          ))}

          {displayData.items.map(quiz => (
            <QuizListCard
              key={quiz.id}
              quiz={quiz}
              onSelect={selectQuiz}
              styles={styles}
              isHoliday={isHoliday}
            />
          ))}
            {/* Quiz Sections */}
            {/* Assuming QuizListItems is a new component that was added and needs a closing View */}
        </View>
      </View>
      </ScrollView>
        </SafeAreaView>
      </LinearGradient>
      </ImageBackground>
    </View>
  );
}
