import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kolamkari/main.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/providers/app_providers.dart';

void main() {
  testWidgets('KolamKari app initial load smoke test', (WidgetTester tester) async {
    // Provide a mocked or stubbed storage in memory
    final storageService = StorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const KolamKariApp(),
      ),
    );

    await tester.pump();

    // Verify Onboarding / Branding header is rendered
    expect(find.text('KolamKari'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
