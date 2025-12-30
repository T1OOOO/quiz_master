import { THEMES, ThemeType } from '../store/useThemeStore';
import { ThemeConfig } from './types';
import { holidayTheme } from './themes/holiday';
import { nightTheme } from './themes/night';
import { summerTheme } from './themes/summer';
import { cyberTheme } from './themes/cyber';
import { autumnTheme } from './themes/autumn';
import { romanceTheme } from './themes/romance';

export const THEME_CONFIG: Record<ThemeType, ThemeConfig> = {
    [THEMES.HOLIDAY]: holidayTheme as any,
    [THEMES.NIGHT]: nightTheme as any,
    [THEMES.SUMMER]: summerTheme as any,
    [THEMES.CYBER]: cyberTheme as any,
    [THEMES.AUTUMN]: autumnTheme as any,
    [THEMES.ROMANCE]: romanceTheme as any,
};
