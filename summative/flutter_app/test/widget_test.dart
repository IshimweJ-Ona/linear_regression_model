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
    'Light 5-color analytics, searchable Female/Province cohorts, benchmark plot, and error handling',
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
      // Deterministically await the real bundled LFS 2022 JSON load & parse
      // before settling finite entrance/chart animations.
      await tester.runAsync(() async {
        final element = tester.element(find.byType(SkillBridgeHomePage));
        await ProviderScope.containerOf(element)
            .read(analyticsDataProvider.future);
      });
      await tester.pump();
      await tester.pumpAndSettle();

      // Light editorial theme + real national LFS 2022 counts
      expect(find.text('SkillBridge'), findsOneWidget);
      expect(find.text('Dataset Overview'), findsOneWidget);
      expect(find.text('7231'), findsOneWidget);

      // Searchable filter on Section 01: search "Female" and select Female
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

      // Searchable filter on Section 01: search "Southern" and select Southern Province
      await tester.tap(find.byKey(const Key('overview_cohort_filter')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('cohort_search_input')),
        'Southern',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Southern Province'));
      await tester.pumpAndSettle();
      expect(find.text('1042'), findsOneWidget);

      // Toggle Section 01 to By Province breakdown and confirm all 5 provinces appear
      await tester.tap(find.text('By Province'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Southern'), findsWidgets);
      expect(find.textContaining('Western'), findsWidgets);
      expect(find.textContaining('Northern'), findsWidgets);
      expect(find.textContaining('Eastern'), findsWidgets);

      final listFinder = find.byType(Scrollable).first;
      // Scroll to Section 02 and confirm heatmap filter stayed independent.
      await tester.scrollUntilVisible(
        find.byKey(const Key('heatmap_cohort_filter')),
        300,
        scrollable: listFinder,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heatmap_cohort_filter')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('heatmap_cohort_filter')),
          matching: find.text('All Youth (18-35)'),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Model Comparison'),
        400,
        scrollable: listFinder,
      );
      expect(find.text('BEST'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Make a Prediction'),
        400,
        scrollable: listFinder,
      );
      await tester.pumpAndSettle();

      // Verify all 13 TextFields + Predict button exist on main form
      expect(find.byType(TextField), findsNWidgets(13));
      expect(find.text('1. Worker Profile'), findsOneWidget);
      expect(find.text('Predict'), findsOneWidget);

      // Tap Predict -> renders value + LFS 2022 benchmark plot
      await tester.scrollUntilVisible(
        find.byKey(const Key('prediction_output_area')),
        350,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();

      expect(find.text('177,430 RWF / month'), findsOneWidget);
      expect(
        find.text('Benchmark Comparison vs. LFS 2022 Peers (k RWF / mo)'),
        findsOneWidget,
      );
      expect(find.text('Your Prediction'), findsOneWidget);
      expect(find.text('National Median (P50)'), findsOneWidget);
      expect(find.text('Recent Saved Estimates (Local)'), findsOneWidget);

      // Wrong type in Age field ("abc")
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Age (18-35)'),
        -300,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.widgetWithText(TextField, 'Age (18-35)'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Age (18-35)'),
        'abc',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Wrong type'), findsOneWidget);

      // Out-of-range in Age field ("15")
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Age (18-35)'),
        -300,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.widgetWithText(TextField, 'Age (18-35)'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Age (18-35)'),
        '15',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Out of range'), findsOneWidget);

      // Missing field after Clear
      await tester.scrollUntilVisible(
        find.byKey(const Key('clear_form_button')),
        -350,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.byKey(const Key('clear_form_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear_form_button')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Predict'),
        450,
        scrollable: listFinder,
      );
      await tester.ensureVisible(find.text('Predict'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This field is required'), findsOneWidget);
    },
  );
}
