import { create } from 'zustand';

/**
 * Theme constants
 */
export const THEMES = {
  HOLIDAY: 'holiday',
  NIGHT: 'night',
  SUMMER: 'summer',
  CYBER: 'cyber',
  AUTUMN: 'autumn',
  ROMANCE: 'romance',
} as const;

export type ThemeType = typeof THEMES[keyof typeof THEMES];

interface ThemeState {
    theme: ThemeType;
    setTheme: (theme: ThemeType) => void;
    toggleTheme: () => void;
}

/**
 * Theme store for managing application theme state
 * Simplified version without persistence to avoid import.meta errors
 */
export const useThemeStore = create<ThemeState>((set) => ({
  theme: THEMES.HOLIDAY, // Default theme
  
  setTheme: (theme) => set({ theme }),
  
  toggleTheme: () => set((state) => {
    const themeKeys = Object.values(THEMES);
    const currentIndex = themeKeys.indexOf(state.theme);
    const nextIndex = (currentIndex + 1) % themeKeys.length;
    return { theme: themeKeys[nextIndex] };
  }),
}));
