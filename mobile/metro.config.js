const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");

const config = getDefaultConfig(__dirname, { isCSSEnabled: true });

// Configure resolver to handle platform-specific modules
const originalResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  // For web platform, don't try to resolve lucide-react-native
  if (platform === 'web' && moduleName === 'lucide-react-native') {
    return {
      type: 'empty',
    };
  }
  // For native platforms, don't try to resolve lucide-react (use lucide-react-native instead)
  if (platform !== 'web' && moduleName === 'lucide-react') {
    return {
      type: 'empty',
    };
  }
  // Default resolution
  if (originalResolveRequest) {
    return originalResolveRequest(context, moduleName, platform);
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = withNativeWind(config, { input: "./global.css" });
