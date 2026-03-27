// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';

/// Generate mocks with: dart run build_runner build
@GenerateMocks([
  Dio,
  ApiClient,
  QuizRepository,
  AuthRepositoryInterface,
  FlutterSecureStorage,
])
void main() {}

/// Test service locator instance
final testGetIt = GetIt.asNewInstance();

/// Initialize test dependencies with mocks
Future<void> configureTestDependencies() async {
  // Reset before configuring
  await testGetIt.reset();

  // Register test implementations here
  // Example: testGetIt.registerSingleton<ApiClient>(MockApiClient());
}

/// Reset test dependencies
Future<void> resetTestDependencies() async {
  await testGetIt.reset();
}
