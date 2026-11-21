import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/pages/skillbridge_home_page.dart';
import 'package:flutter_app/providers/analytics_providers.dart';
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
          EarningsApiService(
            client: mockClient,
            baseUrl: 'https://example.test',
          ),
        ),
      ],
      child: const SkillBridgeApp(),
    );
  }

  testWidgets(
    'Prediction-first light clinical layout, hero header, strict 13-input validation, /predict, and collapsible analytics',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var apiCalls = 0;
      Map<String, dynamic>? lastPayload;

      final mockClient = MockClient((request) async {
        apiCalls += 1;
        expect(request.url.path, '/predict');
        lastPayload = jsonDecode(request.body) as Map<String, dynamic>;
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
      await tester.runAsync(() async {
        final element = tester.element(find.byType(SkillBridgeHomePage));
        await ProviderScope.containerOf(element)
            .read(analyticsDataProvider.future);
      });
      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Prediction-first screen: hero banner, light theme, intro panel, 3 sections, initial idle output, collapsed analytics
      expect(find.byType(Image), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(SkillBridgeHomePage))).brightness,
        Brightness.light,
      );
      expect(find.text('SkillBridge'), findsOneWidget);
      expect(find.text('Monthly Earnings Predictor'), findsOneWidget);
      expect(find.text('1. Worker Profile'), findsOneWidget);
      expect(find.text('Your prediction will appear here.'), findsOneWidget);
      expect(find.text('Dataset Overview'), findsNothing);

      // Exact input control structure: 5 numeric TextFormFields + 6 DropdownButtonFormFields + Yes/No + Occupation picker
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(6));
      expect(find.text('Internet Use'), findsOneWidget);
      expect(find.text('Occupation Group'), findsOneWidget);

      final listFinder = find.byType(Scrollable).first;

      // 2. Tap Predict with default valid sample -> executes API and shows 177,430 RWF + benchmark plot
      await tester.scrollUntilVisible(
        find.text('Predict'),
        350,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 1);
      expect(lastPayload?['age'], 25);
      expect(lastPayload?['sex'], 'Male');
      expect(find.text('177,430 RWF / month'), findsOneWidget);
      expect(
        find.text('Benchmark Comparison vs. LFS 2022 Peers (k RWF / mo)'),
        findsOneWidget,
      );
      expect(find.text('Your Prediction'), findsOneWidget);
      expect(find.text('National Median (P50)'), findsOneWidget);
      expect(find.text('Recent Saved Estimates (Local)'), findsOneWidget);

      // 3. Strict validation: Age = 'abc' (invalid text) must NOT call /predict
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
        -300,
        scrollable: listFinder,
      );
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
        'abc',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 1);
      expect(find.textContaining('Wrong type'), findsWidgets);

      // 4. Integer field rejects decimals: Age = '25.5' must NOT call /predict
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
        '25.5',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 1);
      expect(find.textContaining('without decimals'), findsWidgets);

      // 5. Range validation: Age = '15' (below 18) displays Out of range and blocks /predict
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
        '15',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 1);
      expect(find.textContaining('Out of range'), findsWidgets);

      // 6. Restore valid integer Age = '25' and enter valid decimal Weekly Hours = '42.5'
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age (18-35)'),
        '25',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Weekly Hours (1-100)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weekly Hours (1-100)'),
        '42.5',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 2);
      expect(lastPayload?['weekly_hours'], 42.5);

      // 7. Empty required validation after Clear must block /predict
      await tester.scrollUntilVisible(
        find.byKey(const Key('clear_form_button')),
        -350,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.byKey(const Key('clear_form_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear_form_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(apiCalls, 2);
      expect(find.textContaining('This field is required'), findsWidgets);

      // 8. Expand collapsible analytics via master control and verify all charts + cohorts
      await tester.scrollUntilVisible(
        find.byKey(const Key('master_analytics_toggle')),
        350,
        scrollable: listFinder,
      );
      await tester.ensureVisible(
        find.byKey(const Key('master_analytics_toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Show analytics'), findsOneWidget);
      expect(find.text('Dataset Overview'), findsNothing);
      await tester.tap(find.byKey(const Key('master_analytics_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Hide analytics'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dataset Overview'),
        300,
        scrollable: listFinder,
      );
      await tester.pumpAndSettle();
      expect(find.text('7231'), findsOneWidget);

      // Searchable cohort filter on Section 01: Female -> 3188
      await tester.tap(find.byKey(const Key('overview_cohort_filter')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('cohort_search_input')),
        'Female',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Female'));
      await tester.pumpAndSettle();
      expect(find.text('3188'), findsOneWidget);

      // Verify By Province displays all 5 provinces cleanly
      await tester.tap(find.text('By Province'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Southern'), findsWidgets);
      expect(find.textContaining('Western'), findsWidgets);
      expect(find.textContaining('Northern'), findsWidgets);
      expect(find.textContaining('Eastern'), findsWidgets);

      // Scroll to Model Comparison (BEST) & Feature Importance
      await tester.scrollUntilVisible(
        find.text('Model Comparison'),
        350,
        scrollable: listFinder,
      );
      expect(find.text('BEST'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Feature Importance'),
        350,
        scrollable: listFinder,
      );
      expect(find.text('Feature Importance'), findsOneWidget);

      // Collapse analytics again via master Hide analytics control
      await tester.scrollUntilVisible(
        find.byKey(const Key('master_analytics_toggle')),
        -400,
        scrollable: listFinder,
      );
      await tester.ensureVisible(
        find.byKey(const Key('master_analytics_toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hide analytics'), findsOneWidget);
      await tester.tap(find.byKey(const Key('master_analytics_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Show analytics'), findsOneWidget);
      expect(find.text('Dataset Overview'), findsNothing);
    },
  );

  testWidgets('API error handling and individual chart collapse/expand', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final errorClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'Model service unavailable'}),
        500,
      );
    });

    await tester.pumpWidget(buildTestApp(mockClient: errorClient));
    await tester.runAsync(() async {
      final element = tester.element(find.byType(SkillBridgeHomePage));
      await ProviderScope.containerOf(element)
          .read(analyticsDataProvider.future);
    });
    await tester.pumpAndSettle();

    final listFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Predict'),
      350,
      scrollable: listFinder,
    );
    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(
      find.text('API Error (500): Model service unavailable'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('master_analytics_toggle')),
      350,
      scrollable: listFinder,
    );
    await tester.ensureVisible(
      find.byKey(const Key('master_analytics_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('master_analytics_toggle')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Dataset Overview'),
      300,
      scrollable: listFinder,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Collapse chart'), findsWidgets);

    await tester.tap(find.byTooltip('Collapse chart').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand chart'), findsOneWidget);

    await tester.tap(find.byTooltip('Expand chart').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand chart'), findsNothing);
  });
}
