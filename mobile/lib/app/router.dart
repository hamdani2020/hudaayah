import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/onboarding_screen.dart';

/// App router. Routes mirror the ui-spec screen map
/// (/onboarding, /auth, /home, /lesson/:id, /reader/:surah, /exercise,
/// /progress, /profile). Only /onboarding is wired in Phase 1; the rest are
/// added as their features land.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
