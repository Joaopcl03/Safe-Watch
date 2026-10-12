import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_watch/main.dart';

void main() {
  testWidgets('Safe Watch app smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: SafeWatchApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify initial tabs (Séries screen) and bottom navigation
    expect(find.text('MINHA LISTA'), findsOneWidget);
    expect(find.text('EM BREVE'), findsOneWidget);
    expect(find.text('Séries'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
