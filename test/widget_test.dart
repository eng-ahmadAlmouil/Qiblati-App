import 'package:flutter_test/flutter_test.dart';

import 'package:qiblati/app.dart';

void main() {
  testWidgets('shows the splash brand', (WidgetTester tester) async {
    await tester.pumpWidget(const QiblatiApp());

    expect(find.text('قبلتي'), findsOneWidget);
    expect(find.text('رفيقك إلى الطمأنينة'), findsOneWidget);
  });

  testWidgets('opens the qibla home after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const QiblatiApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    expect(find.text('وجهتك إلى القبلة'), findsOneWidget);
    expect(find.text('القبلة'), findsOneWidget);
  });
}
