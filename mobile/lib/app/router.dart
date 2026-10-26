import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/presentation/sign_in_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/quran_reader/presentation/reader_screen.dart';

/// Bridges a Riverpod provider to a [Listenable] so GoRouter re-evaluates its
/// redirect whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authControllerProvider, (_, next) => notifyListeners());
  }
  final Ref _ref;
}

/// App router. Routes mirror the ui-spec screen map. Phase 2 wires
/// /onboarding, /auth, and /profile with an auth-aware redirect. Remaining
/// routes (/home, /lesson/:id, /reader/:surah, /exercise, /progress) land with
/// their features.
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
      if (signedIn && loc == '/auth') return '/profile';
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
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/reader/:id',
        name: 'reader',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          return ReaderScreen(lessonId: id);
        },
      ),
    ],
  );
});
