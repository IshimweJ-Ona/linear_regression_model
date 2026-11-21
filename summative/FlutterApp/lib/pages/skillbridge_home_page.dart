import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/prediction_section.dart';

/// Prediction-first SkillBridge mobile screen with a compact header, intro panel,
/// validated 13-input prediction experience, and collapsible LFS 2022 analytics.
class SkillBridgeHomePage extends ConsumerWidget {
  const SkillBridgeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final showAnalytics = ref.watch(analyticsVisibleProvider);
    final bundle = analyticsAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: NotificationListener<ScrollStartNotification>(
          onNotification: (notification) {
            if (notification.dragDetails != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            return false;
          },
          child: Scrollbar(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const _HeroHeaderBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      PredictionSection(bundle: bundle),
                      _AnalyticsMasterHeader(
                        showAnalytics: showAnalytics,
                        onToggle: () => ref
                            .read(analyticsVisibleProvider.notifier)
                            .toggle(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            ),
                        child: showAnalytics
                            ? Padding(
                                key: const ValueKey('analytics_expanded'),
                                padding: const EdgeInsets.only(top: 14),
                                child: analyticsAsync.when(
                                  loading: () => const _AnalyticsLoadingCard(),
                                  error: (err, _) =>
                                      _AnalyticsErrorCard(error: '$err'),
                                  data: (loadedBundle) => Column(
                                    children: [
                                      DatasetOverviewSection(
                                        bundle: loadedBundle,
                                      ),
                                      CorrelationHeatmapSection(
                                        bundle: loadedBundle,
                                      ),
                                      ScatterTrendSection(bundle: loadedBundle),
                                      SgdLossSection(bundle: loadedBundle),
                                      ModelComparisonSection(
                                        bundle: loadedBundle,
                                      ),
                                      FeatureImportanceSection(
                                        bundle: loadedBundle,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('analytics_collapsed'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeaderBanner extends StatelessWidget {
  const _HeroHeaderBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/hero_population.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => Container(color: AppColors.navyTint),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.72, 1.0],
                  colors: [
                    AppColors.canvas.withValues(alpha: 0.08),
                    AppColors.canvas.withValues(alpha: 0.14),
                    AppColors.canvas,
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 30, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardHeader(),
                SizedBox(height: 14),
                _IntroPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paper.withValues(alpha: 0.96)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealTint.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.45)),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SkillBridge',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Youth Employment Earnings Predictor • LFS 2022',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.55)),
            ),
            child: const Text(
              'RWANDA',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyTint.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy, width: 1.25),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estimate expected monthly cash earnings (RWF) for Rwandan youth aged 18–35 using the trained RandomForestRegressor. All 13 model fields below are required.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12.2,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMasterHeader extends StatelessWidget {
  const _AnalyticsMasterHeader({
    required this.showAnalytics,
    required this.onToggle,
  });

  final bool showAnalytics;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navyTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.navy,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LFS 2022 Analytics & Model Insights',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      showAnalytics
                          ? '6 interactive charts expanded below (tap any card chevron to collapse individually)'
                          : '6 charts collapsed by default — explore dataset, correlations, loss & feature weights',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              key: const Key('master_analytics_toggle'),
              onPressed: onToggle,
              icon: Icon(
                showAnalytics
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 19,
              ),
              label: Text(showAnalytics ? 'Hide analytics' : 'Show analytics'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                backgroundColor: AppColors.tealTint,
                side: BorderSide(color: AppColors.teal.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLoadingCard extends StatelessWidget {
  const _AnalyticsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.teal,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Loading Rwanda LFS 2022 analytics…',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsErrorCard extends StatelessWidget {
  const _AnalyticsErrorCard({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimsonTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson),
      ),
      child: Text(
        'Failed to load LFS 2022 analytics: $error',
        style: const TextStyle(color: AppColors.crimsonText, fontSize: 12.5),
      ),
    );
  }
}
