import React from 'react';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { View, Text, ActivityIndicator, SafeAreaView, TouchableOpacity, ImageBackground } from 'react-native';
import { ArrowLeft, Menu, X } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useQuizStore } from '../../src/store/quizStore';
import { Quiz, Question, Feedback, QuizStats } from '../../src/types/quiz';
import { QuestionCard } from '../../src/features/quiz/components/QuestionCard';
import { QuizQuestionList } from '../../src/components/QuizQuestionList';
import { useThemeStyles } from '../../src/hooks/useThemeStyles';
import { cn } from '../../src/utils/cn';
import { translateCategory } from '../../src/utils/translations';

interface Breadcrumb {
    label: string;
    onPress?: () => void;
}

export default function QuizPage() {
    const { id } = useLocalSearchParams<{ id: string | string[] }>();
    const router = useRouter();
    const { styles, isHoliday } = useThemeStyles();
    const [showQuestionList, setShowQuestionList] = React.useState(true);

    // Store state
    const quizId = Array.isArray(id) ? id[id.length - 1] : id;
    const { 
        status, 
        error, 
        questions, 
        currentQuestionIndex, 
        answers, 
        feedback,
        quizTitle,
        quizCategory, // Added
        initQuiz, 
        resetQuiz,
        selectQuestion,
        submitAnswer,
        retryQuiz,
        shuffleQuestions
    } = useQuizStore();

    // Calculate stats
    const stats: QuizStats = React.useMemo(() => {
        let correct = 0;
        let incorrect = 0;
        Object.values(feedback).forEach(f => {
            if (f.correct) correct++;
            else incorrect++;
        });
        return { 
            correct, 
            incorrect,
            answered: correct + incorrect,
            total: questions.length
        };
    }, [feedback, questions.length]);

    // Initial load
    React.useEffect(() => {
        if (quizId) {
            initQuiz(quizId);
        }
        return () => {
            resetQuiz();
        };
    }, [quizId]);

    // Build breadcrumbs
    const breadcrumbs: Breadcrumb[] = React.useMemo(() => {
        const crumbs: Breadcrumb[] = [{
            label: 'Главная',
            onPress: () => router.replace('/')
        }]; // Always Home first

        // Add Category hierarchy if available
        if (quizCategory) {
            // Normalize separators first
            const normalizedCategory = quizCategory.replace(/\\/g, '/');
            const parts = normalizedCategory.split('/');
            let accumulatedPath = '';
            
            parts.forEach((part, index) => {
                accumulatedPath = index === 0 ? part : `${accumulatedPath}/${part}`;
                // Capture the current path value for the closure
                const targetFolder = accumulatedPath; 
                
                crumbs.push({
                    label: translateCategory(part),
                    onPress: () => router.push({ pathname: '/', params: { folder: targetFolder } })
                });
            });
        }

        // Add Quiz Title if available
        if (quizTitle) {
             crumbs.push({ label: quizTitle });
        } else if (id) {
             // Fallback to ID if title not yet loaded
             const quizIdStr = Array.isArray(id) ? id[id.length - 1] : id;
              crumbs.push({ label: decodeURIComponent(quizIdStr) });
        }

        return crumbs;
    }, [id, quizTitle, quizCategory]); // Re-run when questions/store updates

    const handleBack = () => {
        router.back();
    };

    if (status === 'loading' || status === 'idle') {
        return (
            <LinearGradient
                colors={['#0f172a', '#020617']}
                className="flex-1 items-center justify-center"
            >
                <ActivityIndicator size="large" color="#3b82f6" />
                <Text className="text-white mt-4 font-medium">Loading quiz...</Text>
            </LinearGradient>
        );
    }

    if (error || status === 'error') {
        return (
            <LinearGradient
                colors={['#0f172a', '#020617']}
                className="flex-1 items-center justify-center p-6"
            >
                <Text className="text-red-400 text-lg text-center mb-4">{error || 'Failed to load quiz'}</Text>
                <TouchableOpacity
                    onPress={handleBack}
                    className="bg-slate-700 px-6 py-3 rounded-lg"
                >
                    <Text className="text-white font-medium">Go Back</Text>
                </TouchableOpacity>
            </LinearGradient>
        );
    }

    return (
        <View className="flex-1 bg-[#0f172a]">
            {/* Background Layer - Absolute to prevent shifting */}
            <LinearGradient
                colors={isHoliday ? ['#450a0a', '#180808'] : ['#0f172a', '#020617']}
                className="absolute w-full h-full"
            />
            
            {isHoliday && (
                <ImageBackground
                    source={require('../../assets/home-alone-bg.jpg')}
                    className="absolute w-full h-full"
                    resizeMode="cover"
                    imageStyle={{ opacity: 0.6 }} // Adjusted opacity for better text contrast
                />
            )}

            <SafeAreaView className="flex-1 w-full">
                <View className="flex-1 flex-row w-full overflow-hidden">
                    {/* 
                        Sidebar Area
                        Integrated smoothly into the layout.
                    */}
                    <View className={cn(
                        "h-full border-r transition-all duration-500 ease-in-out z-50 overflow-hidden",
                        styles.sidebar,
                        showQuestionList ? "w-80" : "w-16"
                    )}>
                        {!showQuestionList ? (
                            <View className="flex-1 items-center pt-10">
                                <TouchableOpacity 
                                    onPress={() => setShowQuestionList(true)}
                                    className="p-4 bg-stone-500/10 rounded-2xl shadow-sm border border-stone-200/20"
                                >
                                    <Menu size={24} color={isHoliday ? "#78716c" : "#60a5fa"} />
                                </TouchableOpacity>
                            </View>
                        ) : (
                            <QuizQuestionList
                                onClose={() => setShowQuestionList(false)}
                            />
                        )}
                    </View>

                    {/* 
                        Main Content Area
                        Automatically centers content in the remaining space.
                    */}
                    <View className="flex-1 flex-col h-full bg-transparent">
                        {/* Top Header Bar */}
                        <View className="flex-row items-center justify-between px-8 py-6">
                            <View className="flex-row items-center space-x-6">
                                <TouchableOpacity 
                                    onPress={handleBack}
                                    className="p-3 bg-white/40 shadow-sm rounded-2xl border border-white/50"
                                >
                                    <ArrowLeft size={22} color={isHoliday ? "#78716c" : "#e2e8f0"} />
                                </TouchableOpacity>
                                
                                <View>
                                    {/* Breadcrumbs */}
                                    <View className="flex-row items-center flex-wrap mb-1">
                                        {breadcrumbs.map((crumb, index) => (
                                            <View key={index} className="flex-row items-center">
                                                {index > 0 && (
                                                    <Text className="mx-1 text-[10px] text-slate-400">{'>'}</Text>
                                                )}
                                                <TouchableOpacity 
                                                    onPress={crumb.onPress} 
                                                    disabled={!crumb.onPress}
                                                    hitSlop={{ top: 10, bottom: 10, left: 5, right: 5 }}
                                                >
                                                    <Text className={cn(
                                                        "text-[10px] font-bold tracking-widest uppercase", 
                                                        index === breadcrumbs.length - 1 
                                                            ? "text-slate-100 opacity-100" 
                                                            : "text-slate-300 opacity-70"
                                                    )}>
                                                        {crumb.label}
                                                    </Text>
                                                </TouchableOpacity>
                                            </View>
                                        ))}
                                    </View>
                                    
                                    <Text className={cn("text-xl font-serif font-bold italic text-white shadow-sm")}>
                                        Question {currentQuestionIndex + 1}
                                    </Text>
                                </View>
                            </View>
                        </View>

                        {/* Question Card Centering Area */}
                        {/* Question Card Centering Area */}
                        <View className="flex-1 items-center justify-start px-4 pt-4 md:px-0 pb-12">
                            <View className="w-full max-w-xl shadow-xl">
                                <QuestionCard
                                    question={questions[currentQuestionIndex]}
                                    totalQuestions={questions.length}
                                    currentIdx={currentQuestionIndex}
                                    onNext={() => selectQuestion(currentQuestionIndex + 1)}
                                    onAnswer={(idx) => submitAnswer(questions[currentQuestionIndex].id, idx)}
                                    selectedAnswer={answers[questions[currentQuestionIndex].id]}
                                    feedback={feedback[questions[currentQuestionIndex].id]}
                                    isLast={currentQuestionIndex === questions.length - 1}
                                    isShuffled={false}
                                    onReset={retryQuiz}
                                    onShuffleQuiz={shuffleQuestions}
                                    breadcrumbs={breadcrumbs}
                                    quizTitle={quizTitle || undefined}
                                    stats={stats}
                                />
                            </View>
                        </View>
                    </View>
                </View>
            </SafeAreaView>
        </View>
    );
}
