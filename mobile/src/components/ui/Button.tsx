import { Text, TouchableOpacity } from 'react-native';
import { cn } from '../../utils/cn';
import { useThemeStore } from '../../store/useThemeStore';

export function Button({ variant = 'default', size = 'default', className, children, ...props }) {
    const { theme } = useThemeStore();
    const isHoliday = theme === 'holiday';

    const baseStyles = "items-center justify-center rounded-xl flex-row";

    const variants = {
        default: isHoliday ? "bg-red-600" : "bg-cyan-600",
        outline: "border border-stone-600 bg-transparent",
        holiday: "bg-red-600 border border-red-700",
        ghost: "bg-transparent"
    };

    const sizes = {
        default: "px-4 py-3",
        sm: "px-3 py-2",
        lg: "px-6 py-4",
        icon: "p-2"
    };

    const textStyles = {
        default: "text-white font-bold",
        outline: "text-stone-300 font-medium",
        holiday: "text-white font-bold",
        ghost: "text-stone-300"
    };

    return (
        <TouchableOpacity
            className={cn(baseStyles, variants[variant], sizes[size], className)}
            activeOpacity={0.8}
            {...props}
        >
            <Text className={cn(textStyles[variant], size === 'sm' && "text-xs")}>
                {children}
            </Text>
        </TouchableOpacity>
    );
}
