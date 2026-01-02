import '../global.css';
import '../src/i18n'; // Initialize i18n
import '../src/api/axios'; // Configure axios
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import 'react-native-reanimated';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import { useColorScheme } from '../src/hooks/useColorScheme';
import { useSegments } from 'expo-router';

const queryClient = new QueryClient();


export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

export const unstable_settings = {
  // Ensure that reloading on `/modal` keeps a back button present.
  initialRouteName: '(tabs)',
};

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
    ...FontAwesome.font,
  });

  // Expo Router uses Error Boundaries to catch errors in the navigation tree.
  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return <RootLayoutNav />;
}

import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { Drawer } from 'expo-router/drawer';
import { CustomDrawerContent } from '../src/components/CustomDrawerContent';
import { useWindowDimensions, View, Platform, StyleSheet, ImageBackground, Text } from 'react-native';

import { vars } from 'nativewind';
import { useThemeStore } from '../src/store/useThemeStore';
// ... other imports ...

// Define a theme with transparent background for the navigator
const TransparentTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: 'transparent',
  },
};

function ThemeBackground() {
    const { theme } = useThemeStore();
    // Only render on Web and Holiday theme
    if (Platform.OS === 'web' && theme === 'holiday') {
        return (
            <View style={StyleSheet.absoluteFill} pointerEvents="none">
                <ImageBackground
                    source={require('../assets/home-alone-bg.jpg')}
                    style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]}
                    resizeMode="cover"
                />
                <View className="absolute inset-0 bg-black/10" />
            </View>
        );
    }
    return null;
}

function RootLayoutNav() {
  const colorScheme = useColorScheme();
  const dimensions = useWindowDimensions();
  const { theme } = useThemeStore();
  const segments = useSegments();
  
  const isLargeScreen = dimensions.width >= 768;
  const themeClass = theme === 'holiday' ? 'theme-holiday' : '';

  // Use TransparentTheme when holiday theme is active to reveal the background image
  const activeTheme = theme === 'holiday' 
      ? TransparentTheme 
      : (colorScheme === 'dark' ? DarkTheme : DefaultTheme);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <View className={`flex-1 ${themeClass}`} style={{ flex: 1 }}>
        {/* Global Background Layer */}
        <ThemeBackground />
        
        <QueryClientProvider client={queryClient}>
          <ThemeProvider value={activeTheme}>
            <Drawer
              drawerContent={(props) => <CustomDrawerContent {...props} />}
              screenOptions={{
                headerShown: false,
                drawerType: (isLargeScreen && segments.length > 0 && segments[0] !== '(tabs)') ? 'permanent' : 'front',
                drawerStyle: {
                  width: isLargeScreen ? 280 : '80%',
                  maxWidth: 300,
                  backgroundColor: theme === 'holiday' ? 'transparent' : undefined,
                },
                swipeEnabled: !isLargeScreen || segments.length === 0 || segments[0] === '(tabs)',
              }}
            >
              <Drawer.Screen 
                  name="index" 
                  options={{ 
                      title: 'Главная',
                      drawerLabel: 'Главная'
                  }} 
              />
              <Drawer.Screen 
                  name="quiz/[...id]" 
                  options={{ 
                      drawerItemStyle: { display: 'none' },
                      drawerType: 'front',
                      swipeEnabled: false,
                      drawerStyle: {
                          width: 0,
                      }
                  }} 
              />
            </Drawer>
          </ThemeProvider>
        </QueryClientProvider>
      </View>
    </GestureHandlerRootView>
  );
}
