import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_master/core/utils/image_utils.dart';

void main() {
  group('ImageUtils', () {
    test('getImageUrl should return empty string for null input', () {
      // Act
      final result = ImageUtils.getImageUrl(null);

      // Assert
      expect(result, '');
    });

    test('getImageUrl should return empty string for empty input', () {
      // Act
      final result = ImageUtils.getImageUrl('');

      // Assert
      expect(result, '');
    });

    test('getImageUrl should return full URL as is for http://', () {
      // Arrange
      const url = 'http://example.com/image.jpg';

      // Act
      final result = ImageUtils.getImageUrl(url);

      // Assert
      expect(result, url);
    });

    test('getImageUrl should return full URL as is for https://', () {
      // Arrange
      const url = 'https://example.com/image.jpg';

      // Act
      final result = ImageUtils.getImageUrl(url);

      // Assert
      expect(result, url);
    });

    test('getImageUrl should construct full URL for relative path starting with /',
        () {
      // Arrange
      const path = '/images/test.jpg';

      // Act
      final result = ImageUtils.getImageUrl(path);

      // Assert
      expect(result, 'http://localhost:8090/images/test.jpg');
    });

    test('getImageUrl should construct full URL for relative path without /',
        () {
      // Arrange
      const path = 'images/test.jpg';

      // Act
      final result = ImageUtils.getImageUrl(path);

      // Assert
      expect(result, 'http://localhost:8090/images/test.jpg');
    });

    test('isNetworkImage should return false for null', () {
      // Act
      final result = ImageUtils.isNetworkImage(null);

      // Assert
      expect(result, false);
    });

    test('isNetworkImage should return false for empty string', () {
      // Act
      final result = ImageUtils.isNetworkImage('');

      // Assert
      expect(result, false);
    });

    test('isNetworkImage should return true for http://', () {
      // Act
      final result = ImageUtils.isNetworkImage('http://example.com/image.jpg');

      // Assert
      expect(result, true);
    });

    test('isNetworkImage should return true for https://', () {
      // Act
      final result = ImageUtils.isNetworkImage('https://example.com/image.jpg');

      // Assert
      expect(result, true);
    });

    test('isNetworkImage should return false for assets path', () {
      // Act
      final result = ImageUtils.isNetworkImage('assets/images/test.jpg');

      // Assert
      expect(result, false);
    });

    test('isNetworkImage should return true for relative path', () {
      // Act
      final result = ImageUtils.isNetworkImage('images/test.jpg');

      // Assert
      expect(result, true);
    });
  });
}
