import '../global.css';
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
import { useWindowDimensions } from 'react-native';

function RootLayoutNav() {
  const colorScheme = useColorScheme();
  const dimensions = useWindowDimensions();
  
  // Show drawer permanently on larger screens (tablets/desktop)
  const isLargeScreen = dimensions.width >= 768;

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
          <Drawer
            drawerContent={(props) => <CustomDrawerContent {...props} />}
            screenOptions={{
              headerShown: false,
              drawerType: isLargeScreen ? 'permanent' : 'front',
              drawerStyle: {
                width: isLargeScreen ? 280 : '80%',
                maxWidth: 300,
              },
              swipeEnabled: !isLargeScreen,
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
    </GestureHandlerRootView>
  );
}
