import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/app/app.dart';

void main() {
  testWidgets('App boots to onboarding with QF attribution', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HudaayahApp()));
    await tester.pumpAndSettle();

    expect(find.text('Hudaayah'), findsOneWidget);
    expect(find.textContaining('Quran Foundation'), findsOneWidget);
    expect(find.text("Get Started — It's Free"), findsOneWidget);
  });
}
