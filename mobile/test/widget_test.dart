import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/app/app.dart';
import 'package:hudaayah/core/storage/secure_storage.dart';

/// In-memory storage so widget tests avoid the platform secure-storage channel.
class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> _m = {};
  @override
  Future<String?> readAccessToken() async => _m['access'];
  @override
  Future<String?> readRefreshToken() async => _m['refresh'];
  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    _m['access'] = access;
    if (refresh != null) _m['refresh'] = refresh;
  }

  @override
  Future<void> clear() async => _m.clear();
}

void main() {
  testWidgets('App boots to onboarding with QF attribution', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
        child: const HudaayahApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Redesigned onboarding (design-mapping §2 screen 01): the "Hudaayah"
    // wordmark, the new headline/subtitle, the "Get started" pill CTA, and a
    // "Sign in" link. The Basmala, pillar cards, and onboarding QF attribution
    // were removed in the redesign (attribution now lives on content screens).
    expect(find.text('Hudaayah'), findsOneWidget);
    expect(find.text('Your journey with the Quran.'), findsOneWidget);
    expect(
      find.textContaining('Build a beautiful daily habit'),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
