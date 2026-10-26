import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/presentation/sign_in_screen.dart';
import '../features/exercises/presentation/exercise_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/home_screen.dart';
import '../features/progress/presentation/lesson_completion_screen.dart';
import '../features/quran_reader/data/lesson_repository.dart';
import '../features/quran_reader/presentation/reader_screen.dart';
import '../features/quran_reader/presentation/surah_selection_screen.dart';
import '../features/review/presentation/review_session_screen.dart';
import 'home_shell.dart';

/// Bridges a Riverpod provider to a [Listenable] so GoRouter re-evaluates its
/// redirect whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authControllerProvider, (_, next) => notifyListeners());
  }
  final Ref _ref;
}

/// Loads a lesson, then shows its exercise session. Keeps the practice route
/// decoupled from how the lesson is fetched.
class _PracticeLoader extends ConsumerWidget {
  const _PracticeLoader({required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonProvider(lessonId));
    return lessonAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          const Scaffold(body: Center(child: Text('Could not load practice.'))),
      data: (lesson) => ExerciseScreen(lesson: lesson),
    );
  }
}

/// App router. Four main destinations (Home, Learn, Review, Profile) live in a
/// persistent bottom-nav shell; onboarding/auth and full-screen flows (lesson
/// practice) are top-level routes outside the shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      // While restoring the session, don't bounce the user around.
      if (auth.isLoading) return null;

      final signedIn = auth.valueOrNull?.isSignedIn ?? false;
      final loc = state.matchedLocation;
      final onAuthFlow = loc == '/auth' || loc == '/onboarding';

      if (!signedIn && !onAuthFlow) return '/auth';
      if (signedIn && loc == '/auth') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const SignInScreen(),
      ),
      // Full-screen lesson practice (no bottom nav while practising).
      GoRoute(
        path: '/lesson/:id/practice',
        name: 'practice',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          return _PracticeLoader(lessonId: id);
        },
      ),
      // Full-screen reader opened by selecting a surah / "Continue".
      GoRoute(
        path: '/reader/:id',
        name: 'reader',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          return ReaderScreen(lessonId: id);
        },
      ),
      // Full-screen lesson completion celebration; summary passed via `extra`.
      GoRoute(
        path: '/lesson/:id/complete',
        name: 'lessonComplete',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final summary = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return LessonCompletionScreen(lessonId: id, summary: summary);
        },
      ),
      // Persistent bottom-nav shell for the four main destinations.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(
            initialLocation: '/surah',
            routes: [
              GoRoute(
                path: '/surah',
                name: 'surah',
                builder: (context, state) => const SurahSelectionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/review',
              name: 'review',
              builder: (context, state) => const ReviewSessionScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
