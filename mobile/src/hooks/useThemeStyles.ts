import { useThemeStore, ThemeType } from '../store/useThemeStore';
import { THEME_CONFIG } from '../theme';
import { useMemo } from 'react';

export interface ThemeStyles {
    themeId: ThemeType;
    config: any;
    styles: any;
    isHoliday: boolean;
    isCyber: boolean;
    isNight: boolean;
    isSummer: boolean;
    isAutumn: boolean;
    isRomance: boolean;
}

export function useThemeStyles(): ThemeStyles {
    const { theme } = useThemeStore();

    return useMemo(() => {
        const config = THEME_CONFIG[theme as keyof typeof THEME_CONFIG] || THEME_CONFIG['holiday'];
        return {
            themeId: theme,
            config,
            styles: config.styles,
            isHoliday: theme === 'holiday',
            isCyber: theme === 'cyber',
            isNight: theme === 'night',
            isSummer: theme === 'summer',
            isAutumn: theme === 'autumn',
            isRomance: theme === 'romance',
        };
    }, [theme]);
}
