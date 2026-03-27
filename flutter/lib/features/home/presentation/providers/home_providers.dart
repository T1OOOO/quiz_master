import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';

part 'home_providers.g.dart';

final quizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getAllQuizzes();
});

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

@riverpod
class CurrentPath extends _$CurrentPath {
  @override
  List<String> build() => [''];

  void add(String folder) {
    state = [...state, folder];
  }

  void navigateTo(int index) {
    state = state.sublist(0, index + 1);
  }
}

final filteredQuizzesProvider = Provider<DisplayData>((ref) {
  final quizzesAsync = ref.watch(quizzesProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final pathStack = ref.watch(currentPathProvider);

  return quizzesAsync.when(
    data: (quizzes) {
      final currentPath = pathStack.length > 1
          ? pathStack.join('/').substring(1)
          : '';

      if (searchQuery.isNotEmpty) {
        final filtered = quizzes.where((quiz) {
          final catTitle = quiz.categoryString ?? quiz.category?.title ?? '';
          return quiz.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              catTitle.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
        return DisplayData(items: filtered, folders: [], isSearch: true);
      }

      final items = <Quiz>[];
      final folders = <String>{};

      for (final quiz in quizzes) {
        final catTitle = (quiz.categoryString ?? quiz.category?.title ?? '')
            .replaceAll('\\', '/');

        if (currentPath == '') {
          if (catTitle == '' || catTitle == 'Разное' || catTitle == 'General') {
            items.add(quiz);
          } else {
            final firstPart = catTitle.split('/')[0];
            folders.add(firstPart);
          }
        } else {
          if (catTitle == currentPath) {
            items.add(quiz);
          } else if (catTitle.startsWith('$currentPath/')) {
            final subPath = catTitle.substring(currentPath.length + 1);
            final firstPart = subPath.split('/')[0];
            folders.add(firstPart);
          }
        }
      }

      return DisplayData(
        items: items,
        folders: folders.toList()..sort(),
        isSearch: false,
      );
    },
    loading: () => DisplayData(items: [], folders: []),
    error: (error, stackTrace) => DisplayData(items: [], folders: []),
  );
});

class DisplayData {
  final List<Quiz> items;
  final List<String> folders;
  final bool isSearch;

  DisplayData({
    required this.items,
    required this.folders,
    this.isSearch = false,
  });
}
