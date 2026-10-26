import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/buttons.dart';

/// Welcome & Onboarding — matches the Stitch "Welcome & Onboarding" screen (01):
/// a soft vertical gradient, the "Hudaayah" wordmark, a feathered hero
/// illustration, a short headline + subtitle, a rounded-full "Get started" CTA,
/// and a "Sign in" link. Presentational only (static screen).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// Decorative soft background gradient (design-mapping §2 screen 01 — a
  /// one-off tint with no ColorScheme slot). Source HTML: 01-welcome-onboarding.
  static const _onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBFAF7), Color(0xFFF4F8F6)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _onboardingGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top — centered wordmark.
                Center(
                  child: Text(
                    'Hudaayah',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppTheme.primary),
                  ),
                ),
                // Middle — feathered hero illustration.
                const Expanded(child: _HeroIllustration()),
                // Bottom — headline, subtitle, CTA, sign-in link.
                Text(
                  'Your journey with the Quran.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: AppTheme.primary),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: Text(
                      'Build a beautiful daily habit, one verse at a time.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryPillButton(
                  label: 'Get started',
                  onPressed: () => context.go('/auth'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => context.go('/auth'),
                            child: Text(
                              'Sign in',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero image inside a rounded-3xl clipped container with a radial feathered
/// fade (ShaderMask) over an ambient amber bloom (decorative).
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient blur bloom behind the hero (secondary-fixed/20).
          Positioned.fill(
            child: Center(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondaryFixed.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius3xl),
            child: ShaderMask(
              shaderCallback: (bounds) => const RadialGradient(
                radius: 0.75,
                colors: [Colors.black, Colors.transparent],
                stops: [0.6, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/onboarding-hero.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
