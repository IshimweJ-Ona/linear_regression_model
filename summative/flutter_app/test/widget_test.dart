import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/providers/prediction_provider.dart';
import 'package:flutter_app/services/earnings_api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({required http.Client mockClient}) {
    return ProviderScope(
      overrides: [
        earningsApiServiceProvider.overrideWithValue(
          EarningsApiService(client: mockClient, baseUrl: 'https://example.test'),
        ),
      ],
      child: const SkillBridgeApp(),
    );
  }

  testWidgets(
      'Renders all 7 sections, 13 inputs, independent filter, valid prediction, and error states',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockClient = MockClient((request) async {
      expect(request.url.path, '/predict');
      return http.Response(
        jsonEncode({
          'predicted_monthly_income_k_rwf': 177.43,
          'predicted_monthly_income_rwf': 177430,
          'currency': 'RWF',
          'model_version': '1.0.0',
        }),
        200,
      );
    });

    await tester.pumpWidget(buildTestApp(mockClient: mockClient));
    await tester.pumpAndSettle();

    // Top sections render real LFS 2022 data
    expect(find.text('SkillBridge'), findsOneWidget);
    expect(find.text('Dataset Overview'), findsOneWidget);
    expect(find.text('7231'), findsOneWidget);

    // Independent filter on Section 01 updates only Section 01 while Section 02 filter stays intact
    await tester.tap(find.text('Ages 18-35'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kigali city').last);
    await tester.pumpAndSettle();
    expect(find.text('2892'), findsOneWidget);
    expect(find.text('All 6 Vars'), findsOneWidget);

    final listFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Model Comparison'), 400, scrollable: listFinder);
    expect(find.text('BEST'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Make a Prediction'), 400, scrollable: listFinder);
    await tester.pumpAndSettle();

    // Verify all 13 TextFields + Predict button exist
    expect(find.byType(TextField), findsNWidgets(13));
    expect(find.text('Predict'), findsOneWidget);

    // Ensure Predict button is cleanly inside viewport before tapping
    await tester.scrollUntilVisible(
      find.byKey(const Key('prediction_output_area')),
      300,
      scrollable: listFinder,
    );
    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(find.text('177,430 RWF / month'), findsOneWidget);
    expect(find.text('Recent Saved Estimates (Local)'), findsOneWidget);

    // Test wrong type in Age field ("abc")
    await tester.ensureVisible(find.widgetWithText(TextField, 'Age (18-35)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Age (18-35)'), 'abc');
    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Wrong type'), findsOneWidget);

    // Test out-of-range in Age field ("15")
    await tester.ensureVisible(find.widgetWithText(TextField, 'Age (18-35)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Age (18-35)'), '15');
    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Out of range'), findsOneWidget);

    // Test missing field after Clear
    await tester.ensureVisible(find.text('Clear').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This field is required'), findsOneWidget);
  });
}
