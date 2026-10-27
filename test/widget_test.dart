import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_v1/term_deposit_page.dart';

void main() {
  testWidgets('deposit menu opens the term deposit form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/deposit': (context) => const TermDepositPage(),
          '/deposit_status': (context) => const TermDepositStatusPage(),
        },
        home: const TermDepositMenuPage(),
      ),
    );

    await tester.tap(find.text('Open Term Deposit'));
    await tester.pumpAndSettle();

    expect(find.text('Hi-Growth Term Deposit'), findsOneWidget);
    expect(find.text('Renewal Option'), findsOneWidget);
  });

  testWidgets('renewal selection shows estimate and requires consent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TermDepositPage()));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No Renewal').last);
    await tester.pumpAndSettle();

    expect(find.text('Term Deposit Type'), findsOneWidget);
    expect(find.text('Deposit Term'), findsOneWidget);
    expect(find.text('20 USD'), findsOneWidget);
    expect(find.text('1.2 USD'), findsOneWidget);
    expect(find.text('Auto Renewal'), findsOneWidget);

    var okButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'OK'),
    );
    expect(okButton.onPressed, isNull);

    final termsLink = find.text(
      'I have read and agreed with the Terms & Conditions',
    );
    await tester.ensureVisible(termsLink);
    await tester.tap(termsLink);
    await tester.pumpAndSettle();
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);

    await tester.tap(find.text('I have read and agree to these terms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    okButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'OK'),
    );
    expect(okButton.onPressed, isNotNull);
  });

  testWidgets('term deposit status shows the two sample records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TermDepositStatusPage()));

    expect(find.text('MM08739738'), findsOneWidget);
    expect(find.text('MM08739739'), findsOneWidget);
    expect(find.text('1000.00 USD'), findsNWidgets(2));
    expect(find.text('27-Apr-2027'), findsNWidgets(2));
  });
}
