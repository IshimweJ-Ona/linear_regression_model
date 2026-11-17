import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/prediction_section.dart';

/// Main vertically scrollable SkillBridge dashboard combining all 6 analytics
/// sections with the 13-input live earnings predictor.
class SkillBridgeHomePage extends ConsumerWidget {
  const SkillBridgeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[...previousChildren, ?currentChild],
          ),
          child: analyticsAsync.when(
            loading: () =>
                const _AnalyticsLoadingView(key: ValueKey('loading_view')),
            error: (err, _) => Center(
              key: const ValueKey('error_view'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load LFS 2022 analytics: $err',
                  style: const TextStyle(color: AppColors.crimson),
                ),
              ),
            ),
            data: (bundle) => Scrollbar(
              key: const ValueKey('loaded_view'),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  const _DashboardHeader(),
                  const SizedBox(height: 16),
                  _FadeSlideIn(
                    index: 0,
                    child: DatasetOverviewSection(bundle: bundle),
                  ),
                  _FadeSlideIn(
                    index: 1,
                    child: CorrelationHeatmapSection(bundle: bundle),
                  ),
                  _FadeSlideIn(
                    index: 2,
                    child: ScatterTrendSection(bundle: bundle),
                  ),
                  _FadeSlideIn(index: 3, child: SgdLossSection(bundle: bundle)),
                  _FadeSlideIn(
                    index: 4,
                    child: ModelComparisonSection(bundle: bundle),
                  ),
                  _FadeSlideIn(
                    index: 5,
                    child: FeatureImportanceSection(bundle: bundle),
                  ),
                  _FadeSlideIn(
                    index: 6,
                    child: PredictionSection(bundle: bundle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded loading screen shown cleanly while bundled LFS 2022 analytics initialize.
class _AnalyticsLoadingView extends StatelessWidget {
  const _AnalyticsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const _DashboardHeader(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: const [
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Loading Rwanda LFS 2022 Analytics...',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Preparing 30 demographic & provincial cohorts and model benchmarks',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < 3; i++)
          Container(
            height: i == 0 ? 150 : 190,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.subtleFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 220,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Finite entrance fade + gentle vertical lift settled cleanly by test harnesses.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final durationMs = 240 + (index.clamp(0, 6) * 35);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, inner) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.paper,
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
                  'Youth Earnings Analytics • LFS 2022 (18–35)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navyTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.navy.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'RWANDA',
              style: TextStyle(
                color: AppColors.navy,
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
