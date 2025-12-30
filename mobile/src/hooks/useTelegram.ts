import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

const isWeb = Platform.OS === 'web';
const isTelegram = isWeb && typeof window !== 'undefined' && !!window.Telegram?.WebApp?.initData;
const tg = isTelegram ? window.Telegram.WebApp : null;

export function useTelegram() {
    const [theme, setTheme] = useState(tg?.themeParams || {
        bg_color: '#ffffff',
        text_color: '#000000',
        hint_color: '#000000',
        link_color: '#000000',
        button_color: '#000000',
        button_text_color: '#ffffff',
        secondary_bg_color: '#ffffff',
    });

    const onClose = () => {
        if (tg) tg.close();
    };

    const onToggleButton = () => {
        if (!tg) return;
        if (tg.MainButton.isVisible) {
            tg.MainButton.hide();
        } else {
            tg.MainButton.show();
        }
    };

    useEffect(() => {
        if (tg) {
            tg.ready();
            tg.expand();

            const handleThemeChange = () => {
                setTheme(tg.themeParams);
            };

            tg.onEvent('themeChanged', handleThemeChange);
            return () => {
                tg.offEvent('themeChanged', handleThemeChange);
            };
        }
    }, []);

    const showMainButton = (text, onClick) => {
        if (tg) {
            tg.MainButton.setText(text);
            tg.MainButton.onClick(onClick);
            tg.MainButton.show();
        }
    };

    const hideMainButton = () => {
        tg?.MainButton.hide();
    };

    const setHeaderColor = (color) => {
        tg?.setHeaderColor(color);
    };

    const hapticFeedback = async (type = 'light') => {
        if (isTelegram && tg) {
            switch (type) {
                case 'impact':
                    tg.HapticFeedback.impactOccurred('medium');
                    break;
                case 'notification':
                    tg.HapticFeedback.notificationOccurred('success');
                    break;
                case 'selection':
                    tg.HapticFeedback.selectionChanged();
                    break;
                default:
                    tg.HapticFeedback.impactOccurred('light');
            }
        } else {
            // Native Haptics using Expo
            switch (type) {
                case 'impact':
                    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                    break;
                case 'notification':
                    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                    break;
                case 'selection':
                    await Haptics.selectionAsync();
                    break;
                default:
                    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            }
        }
    };

    return {
        onClose,
        onToggleButton,
        tg,
        user: tg?.initDataUnsafe?.user || { id: 123, first_name: 'GuestUser', username: 'guest' }, // Mock for native
        queryId: tg?.initDataUnsafe?.query_id || null,
        theme,
        showMainButton,
        hideMainButton,
        setHeaderColor,
        hapticFeedback,
        isTelegram
    };
}
