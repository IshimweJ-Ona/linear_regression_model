import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_models.dart';
import '../services/analytics_asset_service.dart';

final analyticsAssetServiceProvider = Provider<AnalyticsAssetService>((ref) {
  return const AnalyticsAssetService();
});

/// Loads the real LFS 2022 dataset & model analytics JSON once and caches it.
final analyticsDataProvider = FutureProvider<AnalyticsBundle>((ref) async {
  return ref.read(analyticsAssetServiceProvider).loadAnalytics();
});

/// Master visibility state for the collapsible Analytics section (collapsed by default).
class AnalyticsVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setVisible(bool visible) => state = visible;
}

final analyticsVisibleProvider =
    NotifierProvider<AnalyticsVisibilityNotifier, bool>(
      AnalyticsVisibilityNotifier.new,
    );

/// Reusable independent string filter notifier (each section gets its own instance).
class SectionFilterNotifier extends Notifier<String> {
  SectionFilterNotifier(this._initialValue);
  final String _initialValue;

  @override
  String build() => _initialValue;

  void setFilter(String value) => state = value;
}

final overviewFilterProvider = NotifierProvider<SectionFilterNotifier, String>(
  () => SectionFilterNotifier('All Youth (18-35)'),
);

final overviewViewModeProvider =
    NotifierProvider<SectionFilterNotifier, String>(
      () => SectionFilterNotifier('Summary'),
    );

final heatmapCohortFilterProvider =
    NotifierProvider<SectionFilterNotifier, String>(
      () => SectionFilterNotifier('All Youth (18-35)'),
    );

final heatmapFilterProvider = NotifierProvider<SectionFilterNotifier, String>(
  () => SectionFilterNotifier('All 6 Vars'),
);

final scatterFilterProvider = NotifierProvider<SectionFilterNotifier, String>(
  () => SectionFilterNotifier('All Youth (18-35)'),
);

final sgdFilterProvider = NotifierProvider<SectionFilterNotifier, String>(
  () => SectionFilterNotifier('eta0=0.01 (100 ep)'),
);

final modelMetricFilterProvider =
    NotifierProvider<SectionFilterNotifier, String>(
      () => SectionFilterNotifier('Test MSE'),
    );

final featureTopNFilterProvider =
    NotifierProvider<SectionFilterNotifier, String>(
      () => SectionFilterNotifier('Top 6'),
    );
