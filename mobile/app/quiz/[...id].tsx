import React from 'react';
import { useLocalSearchParams, useRouter, Stack, useNavigation } from 'expo-router';
import { CommonActions } from '@react-navigation/native';
import { View, Text, ActivityIndicator, SafeAreaView, TouchableOpacity, ImageBackground, Platform, Dimensions, useWindowDimensions } from 'react-native';
import { ArrowLeft, Menu, X, ChevronRight } from '../../src/components/icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useQuizStore } from '../../src/store/quizStore';
import { Quiz, Question, Feedback, QuizStats } from '../../src/types/quiz';
import { QuestionCard } from '../../src/features/quiz/components/QuestionCard';
import { QuizQuestionList } from '../../src/components/QuizQuestionList';
import { useThemeStore } from '../../src/store/useThemeStore';
import { cn } from '../../src/utils/cn';
import { useTranslation } from 'react-i18next'; // Added useTranslation

interface Breadcrumb {
    label: string;
    onPress?: () => void;
}

export default function QuizPage() {
    const { id } = useLocalSearchParams<{ id: string | string[] }>();
    const router = useRouter();
    const { width } = useWindowDimensions();
    const isMobile = width < 768; // Mobile breakpoint
    
    // Removed legacy styles hook
    const [showQuestionList, setShowQuestionList] = React.useState(!isMobile); // Hide by default on mobile
    const { t } = useTranslation();
    // Get theme directly for conditional styling - MUST BE AT TOP LEVEL
    const { theme: currentTheme } = useThemeStore();
    
    // Update sidebar visibility when screen size changes
    React.useEffect(() => {
        if (isMobile) {
            setShowQuestionList(false);
        } else {
            // Auto-expand on large screens
            setShowQuestionList(true);
        }
    }, [isMobile]);

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

    const navigation = useNavigation(); // Get navigation object

    // Build breadcrumbs
    const breadcrumbs: Breadcrumb[] = React.useMemo(() => {
        const crumbs: Breadcrumb[] = [{
            label: t('sidebar.home'),
            onPress: () => { 
                // Force hard reset to root using CommonActions
                navigation.dispatch(
                    CommonActions.reset({
                        index: 0,
                        routes: [{ name: 'index', params: { folder: '' } }],
                    })
                );
            }
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
                    label: t(`category.${part.toLowerCase()}`, part),
                    onPress: () => { router.push({ pathname: '/', params: { folder: targetFolder } }); }
                });
            });
        }

        // Add Quiz Title if available
        if (quizTitle) {
             crumbs.push({ label: quizTitle, onPress: () => {} });
        } else if (id) {
             // Fallback to ID if title not yet loaded
             const quizIdStr = Array.isArray(id) ? id[id.length - 1] : id;
              crumbs.push({ label: decodeURIComponent(quizIdStr), onPress: () => {} });
        }

        return crumbs;
    }, [id, quizTitle, quizCategory, t]); // Re-run when questions/store updates

    const handleAnswer = async (idx: number) => {
        const currentQ = questions[currentQuestionIndex];
        await submitAnswer(currentQ.id, idx);
        
        // Get fresh feedback state
        const freshFeedback = useQuizStore.getState().feedback[currentQ.id];
        
        if (freshFeedback?.correct) {
            // Auto-advance after 2 seconds
            setTimeout(() => {
                const nextIdx = currentQuestionIndex + 1;
                if (nextIdx < questions.length) {
                    selectQuestion(nextIdx);
                }
                // If last question, we just stay there (user can review or go back)
            }, 2000);
        }
    };

    const handleBack = () => {
        router.back();
    };

    // Timeout safety for loading
    const [showRetry, setShowRetry] = React.useState(false);
    
    React.useEffect(() => {
        let timer: any; // Use any to match platform agnostic setTimeout return (number vs object)
        if (status === 'loading' || status === 'idle') {
            timer = setTimeout(() => {
                setShowRetry(true);
            }, 3000); // Show retry after 3 seconds
        }
        return () => clearTimeout(timer);
    }, [status]);

    if (status === 'loading' || status === 'idle') {
        return (
            <LinearGradient
                colors={['rgba(var(--bg-primary), 1)', 'rgba(var(--bg-secondary), 1)']}
                className="flex-1 items-center justify-center p-4"
            >
                <ActivityIndicator size="large" color="rgba(var(--accent), 1)" />
                <Text className="text-text-primary mt-4 font-medium mb-4">{t('common.loading')}</Text>
                
                {showRetry && (
                    <View className="items-center">
                        <Text className="text-text-secondary text-xs mb-3 text-center">
                            {t('common.taking_too_long', 'Taking longer than expected...')}
                        </Text>
                        <TouchableOpacity
                            onPress={() => quizId && initQuiz(quizId)}
                            className="bg-white/10 px-6 py-2 rounded-lg border border-white/20"
                        >
                            <Text className="text-text-primary font-bold uppercase text-xs">
                                {t('common.retry', 'Retry')}
                            </Text>
                        </TouchableOpacity>
                        <Text className="text-text-muted text-[10px] mt-2">ID: {quizId}</Text>
                    </View>
                )}
            </LinearGradient>
        );
    }

    if (error || status === 'error') {
        return (
            <LinearGradient
                colors={['rgba(var(--bg-primary), 1)', 'rgba(var(--bg-secondary), 1)']}
                className="flex-1 items-center justify-center p-6"
            >
                <Text className="text-error text-lg text-center mb-4">{error || t('common.error_load')}</Text>
                <TouchableOpacity
                    onPress={handleBack}
                    className="bg-white/10 px-6 py-3 rounded-lg border border-white/10"
                >
                    <Text className="text-text-primary font-medium">{t('common.go_back')}</Text>
                </TouchableOpacity>
            </LinearGradient>
        );
    }

    const isHoliday = currentTheme === 'holiday';

    return (
        <View className={cn("flex-1", isHoliday ? "bg-transparent" : "bg-primary")}>
            {/* Background Layer - Absolute to prevent shifting */}
            {!isHoliday && (
                <LinearGradient
                    colors={['rgba(var(--bg-primary), 1)', 'rgba(var(--bg-secondary), 1)']}
                    className="absolute w-full h-full"
                />
            )}
            {/* Conditional BG Image for Holiday Theme - check store theme instead of isHoliday prop */}
            {/* Actually, we can rely on className if we trust root, but ImageBackground needs source. */}
            {/* We can use the store to check theme. */}
            <ThemeBackground /> 

            <SafeAreaView className="flex-1 w-full">
                <View className="flex-1 flex-row w-full overflow-hidden">
                    {/* 
                        Sidebar Area - Hidden on mobile devices
                        Integrated smoothly into the layout on tablets/desktop.
                    */}
                    {!isMobile && (
                        <View className={cn(
                            "h-full border-r transition-all duration-500 ease-in-out z-50 overflow-hidden",
                            // Conditional Opacity for Holiday Theme Glass Effect
                            currentTheme === 'holiday' ? "bg-sidebar/90" : "bg-sidebar", 
                            "border-border",
                            showQuestionList ? "w-80" : "w-16"
                        )}>
                            {!showQuestionList ? (
                                <View className="flex-1 items-center pt-10">
                                    <TouchableOpacity 
                                        onPress={() => setShowQuestionList(true)}
                                        className="p-4 bg-white/5 rounded-2xl shadow-sm border border-border/50"
                                    >
                                        <Menu size={24} color="rgba(var(--text-secondary), 1)" />
                                    </TouchableOpacity>
                                </View>
                            ) : (
                                <QuizQuestionList
                                    onClose={() => setShowQuestionList(false)}
                                />
                            )}
                        </View>
                    )}

                    {/* 
                        Main Content Area
                        Automatically centers content in the remaining space.
                    */}
                    <View className="flex-1 flex-col h-full bg-transparent relative">
                        {/* Mobile Back Button (Absolute) - Moved to Bottom */}
                        {isMobile && (
                            <TouchableOpacity 
                                onPress={handleBack}
                                className={cn(
                                    "absolute bottom-6 left-6 z-50 flex-row items-center px-5 py-3 rounded-full shadow-lg backdrop-blur-md border",
                                    isHoliday 
                                        ? "bg-white/95 border-amber-200 shadow-amber-900/10" 
                                        : "bg-surface/90 border-white/10"
                                )}
                                activeOpacity={0.7}
                                hitSlop={{ top: 15, bottom: 15, left: 15, right: 15 }}
                            >
                                <ArrowLeft size={18} color={isHoliday ? "#78350f" : "rgba(var(--text-primary), 1)"} strokeWidth={2.5} />
                                <Text className={cn(
                                    "ml-2 text-xs font-black uppercase tracking-widest",
                                    isHoliday ? "text-amber-900" : "text-text-primary"
                                )}>
                                    {t('common.go_back') || 'Back'}
                                </Text>
                            </TouchableOpacity>
                        )}

                        {/* Desktop/Tablet Header - Hidden on Mobile */}
                        {!isMobile && (
                        <View className={cn(
                            "flex-row items-center justify-between px-8 py-6 z-20",
                            isHoliday ? "pt-8" : ""
                        )}>
                            <View className="flex-row items-center space-x-6">
                                { /* Desktop Back Button Removed as per user request (redundant with breadcrumbs) */ }
                                
                                <View>
                                    {/* Breadcrumbs Card */}
                                    <View className={cn(
                                        "flex-row items-center flex-wrap mb-2 px-3 py-1.5 rounded-full transition-all self-start",
                                        isHoliday ? "bg-[#fffbf0]/90 border border-amber-100 shadow-sm" : ""
                                    )}>
                                        {breadcrumbs.map((crumb, index) => (
                                            <View key={index} className="flex-row items-center">
                                                {index > 0 && (
                                                    <View className="mx-2">
                                                        <ChevronRight 
                                                            size={14} 
                                                            color={isHoliday ? "#fbbf24" : "rgba(var(--text-secondary), 0.6)"} 
                                                            strokeWidth={2.5}
                                                        />
                                                    </View>
                                                )}
                                                <TouchableOpacity  
                                                    onPress={crumb.onPress || (() => {})} 
                                                    disabled={!crumb.onPress}
                                                    hitSlop={{ top: 10, bottom: 10, left: 15, right: 15 }}
                                                >
                                                    <Text className={cn(
                                                        "text-[10px] font-bold tracking-widest uppercase transition-colors", 
                                                        index === breadcrumbs.length - 1 
                                                            ? (isHoliday ? "text-amber-900" : "text-text-primary opacity-100") 
                                                            : (isHoliday ? "text-amber-700/70" : "text-text-secondary opacity-70")
                                                    )}>
                                                        {crumb.label}
                                                    </Text>
                                                </TouchableOpacity>
                                            </View>
                                        ))}
                                    </View>
                                    
                                    {/* Title Card */}
                                    <View className={cn(
                                        "self-start px-4 py-2 rounded-xl transition-all",
                                        isHoliday ? "bg-[#fffbf0]/90 border border-amber-100 shadow-sm" : ""
                                    )}>
                                        <Text className={cn(
                                            "text-xl font-serif font-bold italic",
                                            isHoliday ? "text-red-900" : "text-text-primary text-shadow-sm"
                                        )}>
                                            {t('quiz.question_title', { count: currentQuestionIndex + 1 })}
                                        </Text>
                                    </View>
                                </View>
                            </View>
                        </View>
                        )}

                        {/* Question Card Centering Area */}
                        <View className="flex-1 items-center justify-start px-4 pt-6 md:px-0 pb-28">
                            <View className="w-full max-w-xl shadow-xl flex-1">
                                <QuestionCard
                                    question={questions[currentQuestionIndex]}
                                    totalQuestions={questions.length}
                                    currentIdx={currentQuestionIndex}
                                    onNext={() => selectQuestion(currentQuestionIndex + 1)}
                                    onAnswer={handleAnswer}
                                    selectedAnswer={answers[questions[currentQuestionIndex].id]}
                                    feedback={feedback[questions[currentQuestionIndex].id]}
                                    isLast={currentQuestionIndex === questions.length - 1}
                                    isShuffled={false}
                                    onReset={retryQuiz}
                                    onShuffleQuiz={shuffleQuestions}
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

// Helper for conditional theme background
function ThemeBackground() {
    const { theme } = useThemeStore();
    // On Web, background is handled globally in _layout.tsx to prevent shifting
    if (Platform.OS === 'web') return null;

    if (theme === 'holiday') {
        return (
             <ImageBackground
                source={require('../../assets/home-alone-bg.jpg')}
                className="absolute w-full h-full"
                resizeMode="cover"
                imageStyle={{ opacity: 0.6 }}
            />
        );
    }
    return null;
}
