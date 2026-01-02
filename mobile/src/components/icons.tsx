// Universal icon wrapper that works on all platforms
// Uses lucide-react for web and lucide-react-native for native platforms

import { Platform } from 'react-native';

// Type for icon props
export interface IconProps {
  size?: number;
  color?: string;
  strokeWidth?: number;
  className?: string;
  style?: any;
  [key: string]: any;
}

// Conditional import based on platform
// Use lazy loading to avoid Metro trying to resolve both modules
let IconModule: any = null;

// Lazy load the appropriate icon library
const getIconModule = () => {
  if (IconModule !== null) {
    return IconModule;
  }
  
  if (Platform.OS === 'web') {
    // For web, use lucide-react
    try {
      IconModule = require('lucide-react');
    } catch (e) {
      console.warn('lucide-react not available, using fallback');
      IconModule = null;
    }
  } else {
    // For native platforms, use lucide-react-native
    try {
      IconModule = require('lucide-react-native');
    } catch (e) {
      console.warn('lucide-react-native not available, using fallback');
      IconModule = null;
    }
  }
  
  return IconModule;
}

// Fallback component if icons are not available
const FallbackIcon = ({ size = 24, color = 'currentColor', ...props }: IconProps) => {
  return null; // Return nothing if icons are not available
};

// Create icon components with platform-specific implementation
export const createIcon = (iconName: string) => {
  const module = getIconModule();
  if (!module || !module[iconName]) {
    return FallbackIcon;
  }
  
  const Icon = module[iconName];
  
  // Return a component that works on both platforms
  return (props: IconProps) => {
    if (Platform.OS === 'web') {
      // For web, lucide-react uses different prop names
      const { size = 24, color = 'currentColor', strokeWidth = 2, className, style, ...restProps } = props;
      return <Icon size={size} color={color} strokeWidth={strokeWidth} className={className} style={style} {...restProps} />;
    } else {
      // For native, lucide-react-native uses standard props
      const { size = 24, color, strokeWidth = 2, style, ...restProps } = props;
      return <Icon size={size} color={color} strokeWidth={strokeWidth} style={style} {...restProps} />;
    }
  };
};

// Export commonly used icons
export const Folder = createIcon('Folder');
export const Gift = createIcon('Gift');
export const ChevronRight = createIcon('ChevronRight');
export const ArrowRight = createIcon('ArrowRight');
export const ArrowLeft = createIcon('ArrowLeft');
export const Search = createIcon('Search');
export const Home = createIcon('Home');
export const Menu = createIcon('Menu');
export const X = createIcon('X');
export const Trash2 = createIcon('Trash2');
export const Shuffle = createIcon('Shuffle');
export const CheckCircle = createIcon('CheckCircle');
export const XCircle = createIcon('XCircle');
export const Circle = createIcon('Circle');
export const Info = createIcon('Info');
export const Snowflake = createIcon('Snowflake');
export const Palette = createIcon('Palette');
export const User = createIcon('User');
export const LogOut = createIcon('LogOut');
export const Play = createIcon('Play');
export const Star = createIcon('Star');
export const HelpCircle = createIcon('HelpCircle');
export const Flag = createIcon('Flag');
export const Send = createIcon('Send');

// Category Icons
export const Clapperboard = createIcon('Clapperboard');
export const Film = createIcon('Film');
export const Utensils = createIcon('Utensils');
export const Leaf = createIcon('Leaf');
export const Heart = createIcon('Heart');
export const Brain = createIcon('Brain');
export const BookOpen = createIcon('BookOpen');
export const Feather = createIcon('Feather');
export const Puzzle = createIcon('Puzzle');
export const Lightbulb = createIcon('Lightbulb');
export const Camera = createIcon('Camera');
export const Music = createIcon('Music');
