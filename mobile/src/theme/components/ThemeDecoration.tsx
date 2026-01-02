import React from 'react';
import { View } from 'react-native';
import { Gift } from '../../components/icons';
import { useThemeStore } from '../../store/useThemeStore';
import { cn } from '../../utils/cn';

export function ThemeDecoration({ type }: { type: string }) {
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';
    const isCyber = theme === 'cyber';

    if (type === 'global') {
        // TODO: Implement Mobile Snowfall (e.g. using reanimated)
        return null;
    }

    if (type === 'sidebar') {
        if (isHoliday) {
            return (
                <>
                    {/* Vertical Ribbon */}
                    <View className="absolute top-0 bottom-0 left-8 w-12 bg-red-600 shadow-md opacity-90 z-0 items-center">
                        <View className="mt-12">
                            <Gift className="text-yellow-400 w-6 h-6" color="#facc15" />
                        </View>
                    </View>
                </>
            );
        }
        if (isCyber) {
            return (
                <View className="absolute inset-x-0 top-0 h-1 bg-cyan-500 opacity-50 shadow-sm" />
            );
        }
    }

    if (type === 'sidebar-header') {
        if (isHoliday) {
            return (
                <View className="absolute left-[-10] top-6 w-20 h-12 bg-white shadow-lg transform -rotate-6 rounded-sm border border-stone-200 items-center justify-center z-10">
                    <View className="w-3 h-3 rounded-full bg-slate-200 absolute top-1/2 -left-1.5 -translate-y-1/2" />
                    <Gift className="w-6 h-6 text-red-600" color="#dc2626" />
                </View>
            );
        }
    }

    if (type === 'sidebar-item-loop') {
        if (isHoliday) {
            return <View className="absolute -top-3.5 -left-3 w-4 h-4 rounded-full border-2 border-yellow-600/50" />;
        }
    }

    if (type === 'card-overlay') {
        if (isHoliday) {
            return (
                <>
                    {/* Miniature Stamp Decoration */}
                </>
            );
        }
    }

    if (type === 'option-mark') {
        if (isHoliday) {
            return (
                <View className="absolute -right-1 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full border border-slate-800/20 items-center justify-center rotate-[-12deg] opacity-50">
                    <View className="absolute inset-x-0 top-1/2 h-px bg-slate-800/10" />
                    <View className="absolute inset-x-0 top-1/2 h-px bg-slate-800/10 rotate-90" />
                </View>
            );
        }
    }

    return null;
}
