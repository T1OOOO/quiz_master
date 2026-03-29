import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';

import '../../fixtures/auth_fixtures.dart';
import '../../fixtures/quiz_fixtures.dart';
import 'api_client_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockQuizDio;
  late MockDio mockAuthDio;
  late ApiClient apiClient;

  setUp(() {
    mockQuizDio = MockDio();
    mockAuthDio = MockDio();
    apiClient = ApiClient(quizDio: mockQuizDio, authDio: mockAuthDio);
  });

  group('ApiClient - Quizzes', () {
    test('getAllQuizzes should return list of quizzes', () async {
      final expectedQuizzes = QuizFixtures.createQuizList();
      when(mockQuizDio.get('/quizzes')).thenAnswer(
        (_) async => Response(
          data: expectedQuizzes
              .map(
                (q) => {
                  'id': q.id,
                  'title': q.title,
                  'description': q.description,
                  'category': q.categoryString,
                  'questions': q.questions
                      .map(
                        (question) => {
                          'id': question.id,
                          'text': question.text,
                          'options': question.options,
                        },
                      )
                      .toList(),
                },
              )
              .toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/quizzes'),
        ),
      );

      final result = await apiClient.getAllQuizzes();

      expect(result, isA<List<Quiz>>());
      expect(result.length, expectedQuizzes.length);
      expect(result.first.id, expectedQuizzes.first.id);
      verify(mockQuizDio.get('/quizzes')).called(1);
    });

    test('getAdminQuizzes should return admin quiz list', () async {
      final expectedQuizzes = QuizFixtures.createQuizList();
      when(
        mockQuizDio.get('/admin/quizzes', options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          data: expectedQuizzes
              .map(
                (q) => {
                  'id': q.id,
                  'title': q.title,
                  'description': q.description,
                  'category': q.categoryString,
                  'questions': q.questions
                      .map(
                        (question) => {
                          'id': question.id,
                          'text': question.text,
                          'options': question.options,
                        },
                      )
                      .toList(),
                },
              )
              .toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/admin/quizzes'),
        ),
      );

      final result = await apiClient.getAdminQuizzes('token123');

      expect(result, isA<List<Quiz>>());
      expect(result.length, expectedQuizzes.length);
      verify(
        mockQuizDio.get('/admin/quizzes', options: anyNamed('options')),
      ).called(1);
    });

    test('getQuizById should return quiz', () async {
      final expectedQuiz = QuizFixtures.createQuiz(id: 'quiz1');
      when(mockQuizDio.get('/quizzes/quiz1')).thenAnswer(
        (_) async => Response(
          data: {
            'id': expectedQuiz.id,
            'title': expectedQuiz.title,
            'description': expectedQuiz.description,
            'category': expectedQuiz.categoryString,
            'questions': expectedQuiz.questions
                .map((q) => {'id': q.id, 'text': q.text, 'options': q.options})
                .toList(),
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/quizzes/quiz1'),
        ),
      );

      final result = await apiClient.getQuizById('quiz1');

      expect(result, isA<Quiz>());
      expect(result.id, 'quiz1');
      verify(mockQuizDio.get('/quizzes/quiz1')).called(1);
    });

    test('getQuizSummary should return quiz summary', () async {
      final expectedQuiz = QuizFixtures.createQuiz(id: 'quiz1');
      when(
        mockQuizDio.get('/quizzes/quiz1', queryParameters: {'mode': 'summary'}),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'id': expectedQuiz.id,
            'title': expectedQuiz.title,
            'description': expectedQuiz.description,
            'category': expectedQuiz.categoryString,
            'questions': expectedQuiz.questions
                .map((q) => {'id': q.id, 'text': q.text, 'options': q.options})
                .toList(),
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/quizzes/quiz1'),
        ),
      );

      final result = await apiClient.getQuizSummary('quiz1');

      expect(result, isA<Quiz>());
      expect(result.id, 'quiz1');
      verify(
        mockQuizDio.get('/quizzes/quiz1', queryParameters: {'mode': 'summary'}),
      ).called(1);
    });

    test('getQuestion should return question', () async {
      final expectedQuestion = QuizFixtures.createQuestion(id: 'q1');
      when(mockQuizDio.get('/quizzes/quiz1/questions/q1')).thenAnswer(
        (_) async => Response(
          data: {
            'id': expectedQuestion.id,
            'text': expectedQuestion.text,
            'options': expectedQuestion.options,
            'explanation': expectedQuestion.explanation,
            'image_url': expectedQuestion.imageUrl,
            'difficulty': expectedQuestion.difficulty,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/quizzes/quiz1/questions/q1'),
        ),
      );

      final result = await apiClient.getQuestion('quiz1', 'q1');

      expect(result, isA<Question>());
      expect(result.id, 'q1');
      verify(mockQuizDio.get('/quizzes/quiz1/questions/q1')).called(1);
    });

    test('checkAnswer should return feedback', () async {
      final expectedFeedback = QuizFixtures.createFeedback(correct: true);
      when(
        mockQuizDio.post('/quizzes/quiz1/check', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'correct': expectedFeedback.correct,
            'explanation': expectedFeedback.explanation,
            'correct_answer': expectedFeedback.correctAnswer,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/quizzes/quiz1/check'),
        ),
      );

      final result = await apiClient.checkAnswer('quiz1', 'q1', 0);

      expect(result, isA<Feedback>());
      expect(result.correct, true);
      verify(
        mockQuizDio.post('/quizzes/quiz1/check', data: anyNamed('data')),
      ).called(1);
    });
  });

  group('ApiClient - Auth', () {
    test('login should return AuthResponse', () async {
      final request = AuthFixtures.createAuthRequest();
      final expectedResponse = AuthFixtures.createAuthResponse();
      when(mockAuthDio.post('/login', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: {
            'token': expectedResponse.token,
            'refresh_token': expectedResponse.refreshToken,
            'user': {
              'id': expectedResponse.user.id,
              'username': expectedResponse.user.username,
              'email': expectedResponse.user.email,
              'avatar': expectedResponse.user.avatar,
              'role': expectedResponse.user.role,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/login'),
        ),
      );

      final result = await apiClient.login(request);

      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      expect(result.refreshToken, expectedResponse.refreshToken);
      expect(result.user.username, expectedResponse.user.username);
      verify(mockAuthDio.post('/login', data: anyNamed('data'))).called(1);
    });

    test('register should return AuthResponse', () async {
      final request = AuthFixtures.createAuthRequest();
      final expectedResponse = AuthFixtures.createAuthResponse();
      when(mockAuthDio.post('/register', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: {
            'token': expectedResponse.token,
            'refresh_token': expectedResponse.refreshToken,
            'user': {
              'id': expectedResponse.user.id,
              'username': expectedResponse.user.username,
              'email': expectedResponse.user.email,
              'avatar': expectedResponse.user.avatar,
              'role': expectedResponse.user.role,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/register'),
        ),
      );

      final result = await apiClient.register(request);

      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      expect(result.refreshToken, expectedResponse.refreshToken);
      verify(mockAuthDio.post('/register', data: anyNamed('data'))).called(1);
    });

    test('guestLogin should return AuthResponse', () async {
      final expectedResponse = AuthFixtures.createAuthResponse();
      when(mockAuthDio.post('/guest', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: {
            'token': expectedResponse.token,
            'refresh_token': expectedResponse.refreshToken,
            'user': {
              'id': expectedResponse.user.id,
              'username': expectedResponse.user.username,
              'email': expectedResponse.user.email,
              'avatar': expectedResponse.user.avatar,
              'role': expectedResponse.user.role,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/guest'),
        ),
      );

      final result = await apiClient.guestLogin('guestuser');

      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      expect(result.refreshToken, expectedResponse.refreshToken);
      verify(mockAuthDio.post('/guest', data: anyNamed('data'))).called(1);
    });

    test('refresh should return AuthResponse', () async {
      final expectedResponse = AuthFixtures.createAuthResponse();
      when(mockAuthDio.post('/refresh', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: {
            'token': expectedResponse.token,
            'refresh_token': expectedResponse.refreshToken,
            'user': {
              'id': expectedResponse.user.id,
              'username': expectedResponse.user.username,
              'email': expectedResponse.user.email,
              'avatar': expectedResponse.user.avatar,
              'role': expectedResponse.user.role,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/refresh'),
        ),
      );

      final result = await apiClient.refresh('refresh_token_123');

      expect(result, isA<AuthResponse>());
      expect(result.refreshToken, expectedResponse.refreshToken);
      verify(mockAuthDio.post('/refresh', data: anyNamed('data'))).called(1);
    });
  });

  group('ApiClient - Statistics', () {
    test('getLeaderboard should return list of entries', () async {
      final expectedEntries = [
        LeaderboardEntry(username: 'user1', score: 10, total: 10),
        LeaderboardEntry(username: 'user2', score: 9, total: 10),
      ];
      when(
        mockAuthDio.get('/leaderboard', queryParameters: {'limit': 10}),
      ).thenAnswer(
        (_) async => Response(
          data: expectedEntries
              .map(
                (e) => {
                  'username': e.username,
                  'score': e.score,
                  'total': e.total,
                  'quiz_title': e.quizTitle,
                },
              )
              .toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/leaderboard'),
        ),
      );

      final result = await apiClient.getLeaderboard(limit: 10);

      expect(result, isA<List<LeaderboardEntry>>());
      expect(result.length, 2);
      expect(result.first.username, 'user1');
      verify(
        mockAuthDio.get('/leaderboard', queryParameters: {'limit': 10}),
      ).called(1);
    });

    test('getAdminLeaderboard should return list of entries', () async {
      final expectedEntries = [
        LeaderboardEntry(username: 'admin1', score: 10, total: 10),
      ];
      when(
        mockAuthDio.get(
          '/admin/leaderboard',
          queryParameters: {'limit': 10},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: expectedEntries
              .map(
                (entry) => {
                  'username': entry.username,
                  'score': entry.score,
                  'total': entry.total,
                  'quiz_title': entry.quizTitle,
                },
              )
              .toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/admin/leaderboard'),
        ),
      );

      final result = await apiClient.getAdminLeaderboard('token123', limit: 10);

      expect(result, isA<List<LeaderboardEntry>>());
      expect(result.single.username, 'admin1');
      verify(
        mockAuthDio.get(
          '/admin/leaderboard',
          queryParameters: {'limit': 10},
          options: anyNamed('options'),
        ),
      ).called(1);
    });

    test('submitScore should return true on success', () async {
      when(
        mockAuthDio.post(
          '/submit',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'status': 'saved'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/submit'),
        ),
      );

      final result = await apiClient.submitScore('quiz1', 8, 10, 'token123');

      expect(result, true);
      verify(
        mockAuthDio.post(
          '/submit',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).called(1);
    });

    test('submitScore should return false on failure', () async {
      when(
        mockAuthDio.post(
          '/submit',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/submit'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/submit'),
          ),
        ),
      );

      final result = await apiClient.submitScore('quiz1', 8, 10, 'token123');

      expect(result, false);
    });
  });
}
