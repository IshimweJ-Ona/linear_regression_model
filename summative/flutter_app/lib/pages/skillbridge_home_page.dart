import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/prediction_section.dart';

class SkillBridgeHomePage extends ConsumerWidget {
  const SkillBridgeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: analyticsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load LFS 2022 analytics: $err',
                  style: const TextStyle(color: AppColors.coral),
                ),
              ),
            ),
            data: (bundle) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                const _DashboardHeader(),
                const SizedBox(height: 16),
                DatasetOverviewSection(bundle: bundle),
                CorrelationHeatmapSection(bundle: bundle),
                ScatterTrendSection(bundle: bundle),
                SgdLossSection(bundle: bundle),
                ModelComparisonSection(bundle: bundle),
                FeatureImportanceSection(bundle: bundle),
                const PredictionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cyan, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.trending_up_rounded,
            color: AppColors.bgTop,
            size: 26,
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
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45)),
          ),
          child: const Text(
            'RWANDA',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
