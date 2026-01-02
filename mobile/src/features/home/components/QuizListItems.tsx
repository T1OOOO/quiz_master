import React from 'react';
import { View, Text, TouchableOpacity, Image } from 'react-native';
import { 
    Folder, 
    Clapperboard, 
    Utensils, 
    Leaf, 
    Heart, 
    Brain, 
    BookOpen, 
    Gift, 
    HelpCircle,
    Play,
    Star
} from '../../../components/icons';
import { cn } from '../../../utils/cn';
import { useTranslation } from 'react-i18next';
import { ThemeDecoration } from '../../../theme/components/ThemeDecoration';
import { LinearGradient } from 'expo-linear-gradient';

interface FolderCardProps {
    folder: string;
    onClick: () => void;
    isHoliday: boolean;
}

// Map folder names to assets
// Map folder names to styles (Gradient Colors + Icon)
// Using RGBA to allow premium texture to show through (85-95% opacity)
const categoryStyles: Record<string, { colors: readonly [string, string, ...string[]]; Icon: any }> = {
    // Cinema: Red/Wine
    'Cinema': { colors: ['rgba(220, 38, 38, 0.85)', 'rgba(153, 27, 27, 0.95)'], Icon: Clapperboard },
    'Кино': { colors: ['rgba(220, 38, 38, 0.85)', 'rgba(153, 27, 27, 0.95)'], Icon: Clapperboard },
    
    // Gastronomy: Orange/Amber
    'Gastronomy': { colors: ['rgba(245, 158, 11, 0.85)', 'rgba(180, 83, 9, 0.95)'], Icon: Utensils },
    'Гастрономия': { colors: ['rgba(245, 158, 11, 0.85)', 'rgba(180, 83, 9, 0.95)'], Icon: Utensils },
    'Book_of_tasty_and_healthy_food': { colors: ['rgba(245, 158, 11, 0.85)', 'rgba(180, 83, 9, 0.95)'], Icon: Utensils },

    // Nature: Emerald/Forest
    'Nature': { colors: ['rgba(16, 185, 129, 0.85)', 'rgba(6, 95, 70, 0.95)'], Icon: Leaf },
    'Природа': { colors: ['rgba(16, 185, 129, 0.85)', 'rgba(6, 95, 70, 0.95)'], Icon: Leaf },

    // Philias: Pink/Rose
    'Philias': { colors: ['rgba(236, 72, 153, 0.85)', 'rgba(157, 23, 77, 0.95)'], Icon: Heart },
    'Филии': { colors: ['rgba(236, 72, 153, 0.85)', 'rgba(157, 23, 77, 0.95)'], Icon: Heart },

    // Psychology: Violet/Indigo
    'Psychology': { colors: ['rgba(139, 92, 246, 0.85)', 'rgba(91, 33, 182, 0.95)'], Icon: Brain },
    'Психология': { colors: ['rgba(139, 92, 246, 0.85)', 'rgba(91, 33, 182, 0.95)'], Icon: Brain },

    // Philology: Amber/Brown (Classic Book)
    'Philology': { colors: ['rgba(217, 119, 6, 0.85)', 'rgba(120, 53, 15, 0.95)'], Icon: BookOpen },
    'Филология': { colors: ['rgba(217, 119, 6, 0.85)', 'rgba(120, 53, 15, 0.95)'], Icon: BookOpen },

    // New Year: Red/Slate (Festive)
    'NewYear': { colors: ['rgba(220, 38, 38, 0.9)', 'rgba(15, 23, 42, 0.95)'], Icon: Gift },
    'New Year': { colors: ['rgba(220, 38, 38, 0.9)', 'rgba(15, 23, 42, 0.95)'], Icon: Gift },
    'Holiday': { colors: ['rgba(220, 38, 38, 0.9)', 'rgba(15, 23, 42, 0.95)'], Icon: Gift },
    'Новый Год': { colors: ['rgba(220, 38, 38, 0.9)', 'rgba(15, 23, 42, 0.95)'], Icon: Gift },
    'Новый год': { colors: ['rgba(220, 38, 38, 0.9)', 'rgba(15, 23, 42, 0.95)'], Icon: Gift },
};

// Default style for unknown categories
const defaultStyle = { colors: ['rgba(100, 116, 139, 0.9)', 'rgba(71, 85, 105, 0.95)'] as const, Icon: Folder };

export function FolderCard({ folder, onClick, isHoliday }: FolderCardProps) {
    const { t } = useTranslation();

    // Find style by key (case insensitive search)
    const foundKey = Object.keys(categoryStyles).find(k => 
        folder.toLowerCase().includes(k.toLowerCase()) || 
        k.toLowerCase().includes(folder.toLowerCase())
    );
    
    const style = categoryStyles[folder] || (foundKey ? categoryStyles[foundKey] : defaultStyle);
    const GradientColors = style.colors;
    const IconComponent = style.Icon;

    // Use common premium paper texture
    const textureImage = require('../../../../assets/images/bg_soft_premium.png');

    return (
        <TouchableOpacity
            onPress={onClick}
            className={cn(
                "group relative rounded-2xl overflow-hidden shadow-md w-full h-[140px]",
                isHoliday ? "border-2 border-amber-100/50" : "border border-white/20"
            )}
            style={{
                shadowColor: "#000",
                shadowOpacity: 0.25,
                shadowRadius: 10,
                elevation: 6
            }}
            activeOpacity={0.9}
        >
            {/* 1. Base Texture Layer (Paper) */}
            <Image 
                source={textureImage}
                className="absolute w-full h-full"
                resizeMode="cover"
                style={{ opacity: 1 }}
            />

            {/* 2. Main Color Gradient (Semi-transparent) */}
            <LinearGradient
                colors={GradientColors}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                className="absolute w-full h-full"
            />

            {/* 3. Glass/Shine Effect Overlay */}
            <LinearGradient
                colors={['rgba(255,255,255,0.2)', 'transparent', 'rgba(0,0,0,0.1)']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                className="absolute w-full h-full"
            />

            {/* 4. Large Decorative Icon (Background) */}
            <View className="absolute -right-4 -bottom-4 opacity-15 transform rotate-[-15deg]">
                 <IconComponent size={110} color="white" />
            </View>

            {/* 5. Content */}
            <View className="absolute inset-0 p-4 flex-col justify-between">
                {/* Top Icon Badge (GlassMorphism) */}
                <View className="w-9 h-9 rounded-full bg-white/20 items-center justify-center border border-white/30 backdrop-blur-md shadow-sm">
                    <IconComponent size={18} color="white" />
                </View>

                {/* Bottom Text */}
                <View>
                    <Text className="text-white font-bold text-lg shadow-sm leading-tight font-serif tracking-wide">
                        {t(`category.${folder.toLowerCase()}`, folder)}
                    </Text>
                    <View className="h-0.5 w-8 bg-white/40 mt-2 rounded-full" />
                </View>
            </View>
        </TouchableOpacity>
    );
}

interface QuizListCardProps {
    quiz: {
        id: string;
        title: string;
        description?: string;
        questions_count?: number;
        category?: string | { title: string } | any;
        questions?: any[];
    };
    onSelect: (id: string) => void;
    isHoliday: boolean;
}

export function QuizListCard({ quiz, onSelect, isHoliday }: QuizListCardProps) {
    const { t } = useTranslation();
    const count = quiz.questions_count || quiz.questions?.length || 0;
    
    // Unified base background
    const baseBackground = require('../../../../assets/images/bg_soft_premium.png');
    // Specific 3D Illustration
    const illustrationImage = require('../../../../assets/images/bg_quiz_illustrated.png');
    
    // Resolve category string
    const categoryName = typeof quiz.category === 'string' ? quiz.category : quiz.category?.title || '';

    return (
        <TouchableOpacity
            onPress={() => onSelect(quiz.id)}
            className={cn(
                "rounded-3xl overflow-hidden relative flex-col w-full",
                isHoliday ? "bg-card border-none" : "bg-card border border-border"
            )}
            style={{
                shadowColor: isHoliday ? "#78350f" : "#000",
                shadowOpacity: isHoliday ? 0.15 : 0.3,
                shadowRadius: 16,
                elevation: 8,
                backgroundColor: isHoliday ? '#fffbf0' : undefined,
                minHeight: 160
            }}
            activeOpacity={0.9}
        >
            {/* 1. Base Soft Background (Cover) */}
            <Image 
                source={baseBackground} 
                className="absolute w-full h-full" 
                resizeMode="cover"
                style={{ opacity: 1 }} 
            />

            {/* 2. 3D Illustration on the Right (Contained, like a 3D Icon) */}
            <View className="absolute right-0 top-0 bottom-0 w-[50%] overflow-hidden">
                <Image
                    source={illustrationImage}
                    className="w-full h-full"
                    resizeMode="contain" // Shows the whole illustration
                    style={{ 
                        opacity: 0.9,
                        // Move it slightly to the right to look "stamped"
                        transform: [{ translateX: 20 }, { scale: 1.2 }] 
                    }}
                />
            </View>

             <LinearGradient
                colors={isHoliday ? ['rgba(255,251,240,0.5)', 'rgba(255,251,240,0.95)'] : ['rgba(20,20,20,0.5)', 'rgba(20,20,20,0.95)']}
                className="absolute bottom-0 w-full h-full"
                locations={[0, 0.85]}
            />

            {/* Content Area */}
            <View className="p-4 flex-1 flex-col relative z-10">
                {/* Top Row: Title & Badge */}
                <View className="flex-row justify-between items-start mb-2">
                    {/* Title moved to top */}
                    <View className="flex-1 mr-2">
                        <Text 
                            numberOfLines={2} 
                            className={cn(
                                "text-lg font-bold font-serif leading-6", 
                                isHoliday ? "text-stone-900" : "text-text-primary"
                            )}
                        >
                            {quiz.title}
                        </Text>
                    </View>

                    {/* Question Count Badge */}
                    <View className={cn(
                        "px-2.5 py-1.5 rounded-xl flex-row items-center shadow-sm",
                        isHoliday ? "bg-white border border-amber-200" : "bg-card-secondary border border-border"
                    )}>
                        <Text className={cn("text-[10px] uppercase font-black tracking-wider", isHoliday ? "text-amber-800" : "text-text-secondary")}>
                            {count} Q
                        </Text>
                    </View>
                </View>


                {/* Category Breadcrumb */}
                {categoryName && (
                    <View className="flex-row items-center mb-2 flex-wrap">
                        {categoryName.split(/[\/\\]/).map((part: string, index: number, arr: string[]) => (
                            <View key={index} className="flex-row items-center">
                                {index > 0 && (
                                    <Text className={cn(
                                        "mx-1.5 text-[10px] font-bold",
                                        isHoliday ? "text-amber-400" : "text-text-secondary opacity-50"
                                    )}>›</Text>
                                )}
                                <Text className={cn(
                                    "text-[9px] font-bold uppercase tracking-wider",
                                    isHoliday ? "text-amber-700" : "text-text-secondary opacity-70"
                                )}>
                                    {part.trim()}
                                </Text>
                            </View>
                        ))}
                    </View>
                )}
                
                {/* Description */}
                <Text 
                    numberOfLines={2} 
                    className={cn(
                        "text-xs leading-relaxed opacity-80 mb-3", 
                        isHoliday ? "text-stone-600" : "text-text-sub"
                    )}
                >
                    {quiz.description || t('home.quiz_default_desc')}
                </Text>

                {/* Footer: Play Action */}
                <View className="mt-auto pt-2 border-t border-dashed border-border/40">
                    <View className={cn(
                        "w-full py-2 rounded-xl flex-row items-center justify-center",
                        isHoliday 
                            ? "bg-amber-100/50" 
                            : "bg-accent/5"
                    )}>
                        <Text className={cn(
                            "text-[10px] font-black uppercase tracking-widest mr-2 opacity-80", 
                            isHoliday ? "text-amber-900" : "text-accent"
                        )}>
                            {t('home.play')}
                        </Text>
                        <Play size={10} color={isHoliday ? "#78350f" : "rgba(var(--accent), 1)"} fill={isHoliday ? "#78350f" : "rgba(var(--accent), 1)"} />
                    </View>
                </View>
            </View>
        </TouchableOpacity>
    );
}
