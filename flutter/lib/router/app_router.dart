import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_master/features/admin/presentation/screens/admin_screen.dart';
import 'package:quiz_master/features/debug/presentation/screens/debug_screen.dart';
import 'package:quiz_master/features/home/presentation/screens/home_screen.dart';
import 'package:quiz_master/features/quiz/presentation/screens/quiz_screen.dart';
import 'package:quiz_master/features/settings/presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(initialLocation: '/', routes: $appRoutes);
});

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

@TypedGoRoute<QuizRoute>(path: '/quiz/:id')
class QuizRoute extends GoRouteData with $QuizRoute {
  final String id;
  const QuizRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      QuizScreen(quizId: id);
}

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

@TypedGoRoute<DebugRoute>(path: '/debug')
class DebugRoute extends GoRouteData with $DebugRoute {
  const DebugRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DebugScreen();
}

@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with $AdminRoute {
  const AdminRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AdminScreen();
}
