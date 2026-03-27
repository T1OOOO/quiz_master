import '../config/app_config.dart';

/// Helper to build full image URL from server
/// Images from questions are already full URLs from API
/// Background images can be loaded from server or assets
class ImageUtils {
  static const String baseUrl = AppConfig.serverBaseUrl;

  /// Get full URL for image from server
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If relative path, construct full URL
    if (imagePath.startsWith('/')) {
      return '$baseUrl$imagePath';
    }

    return '$baseUrl/$imagePath';
  }

  /// Check if image should be loaded from network
  static bool isNetworkImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    // Network images start with http/https
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return true;
    }

    // Relative paths are also network images
    if (!imagePath.startsWith('assets/') && !imagePath.startsWith('lib/')) {
      return true;
    }

    return false;
  }
}
