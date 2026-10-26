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

    // Hero is above the fold.
    expect(find.text('Hudaayah'), findsOneWidget);
    expect(find.textContaining('Build a Heartfelt'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    // CTA and attribution are further down the scroll view.
    final cta = find.text("Get Started — It's Free");
    await tester.scrollUntilVisible(cta, 300, scrollable: scrollable);
    expect(cta, findsOneWidget);

    final attribution = find.textContaining('Quran Foundation');
    await tester.scrollUntilVisible(attribution, 300, scrollable: scrollable);
    expect(attribution, findsOneWidget);
  });
}
