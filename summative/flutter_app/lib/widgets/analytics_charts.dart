import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/analytics_models.dart';
import '../providers/analytics_providers.dart';
import 'section_card.dart';

/// 01. Dataset Overview (All 5 Provinces, Female & Male search, plus Province/Sex breakdowns)
class DatasetOverviewSection extends ConsumerWidget {
  const DatasetOverviewSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(overviewFilterProvider);
    final viewMode = ref.watch(overviewViewModeProvider);
    final stats = bundle.overview[filter] ?? bundle.overview.values.first;

    return SectionCard(
      stepNumber: '01',
      title: 'Dataset Overview',
      subtitle: 'Rwanda LFS 2022 employed youth cash earners (ages 18–35, <= 500k RWF)',
      icon: Icons.dataset_outlined,
      accentColor: AppColors.navy,
      filterWidget: SearchableCohortButton(
        buttonKey: const Key('overview_cohort_filter'),
        selectedKey: filter,
        bundle: bundle,
        onSelected: (v) =>
            ref.read(overviewFilterProvider.notifier).setFilter(v),
      ),
      controlsRow: _SegmentedChips(
        options: const ['Summary', 'By Province', 'By Sex & Track'],
        selected: viewMode,
        onSelected: (v) =>
            ref.read(overviewViewModeProvider.notifier).setFilter(v),
      ),
      footerNote: switch (viewMode) {
        'By Province' => 'Kigali city youth average 81.2k RWF/mo — more than double Southern (40.6k), Eastern (36.0k), Northern (35.7k), and Western (34.7k) provinces.',
        'By Sex & Track' => 'Female youth average 42.5k RWF vs 63.9k for males (-33.5%). Completed TVET tracks average 94.5k RWF (+46% over general education at 64.6k).',
        _ =>
          '$filter represents ${stats.sharePct.toStringAsFixed(1)}% of youth earners (n = ${stats.count}) • ${stats.femalePct.toStringAsFixed(1)}% Female • ${stats.tvetPct.toStringAsFixed(1)}% TVET.',
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        layoutBuilder: _topAlignedLayout,
        child: KeyedSubtree(
          key: ValueKey('$viewMode|$filter'),
          child: switch (viewMode) {
            'By Province' => _ProvinceBreakdownChart(
              bundle: bundle,
              activeCohort: filter,
            ),
            'By Sex & Track' => _SexAndTrackBreakdownChart(
              bundle: bundle,
              activeCohort: filter,
            ),
            _ => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${stats.count}',
                        label:
                            'Youth Workers (${stats.sharePct.toStringAsFixed(1)}%)',
                        accent: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value: '${stats.meanK.toStringAsFixed(1)}k',
                        label: 'Mean Monthly Pay (RWF)',
                        accent: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${stats.medianK.toStringAsFixed(1)}k',
                        label: 'Median Pay (P50)',
                        accent: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value:
                            '${stats.minK.toStringAsFixed(1)}k–${stats.maxK.toStringAsFixed(0)}k',
                        label: 'Min–Max Observed',
                        accent: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PaySpreadStrip(stats: stats),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _SegmentedChips extends StatelessWidget {
  const _SegmentedChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.subtleFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: options.map((opt) {
          final active = opt == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(opt),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.paper : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: active
                      ? Border.all(color: AppColors.borderStrong)
                      : null,
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppColors.navy : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaySpreadStrip extends StatelessWidget {
  const _PaySpreadStrip({required this.stats});
  final OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Monthly Earnings Quartile Spread (0–500k)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: Text(
                  'IQR ${stats.p25K.toStringAsFixed(0)}k–${stats.p75K.toStringAsFixed(0)}k',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: SizedBox(
              height: 28,
              width: double.infinity,
              child: CustomPaint(painter: _QuartileStripPainter(stats)),
            ),
          ),
          const SizedBox(height: 6),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.navy, label: 'P25–P75 IQR'),
              _LegendDot(color: AppColors.ink, label: 'Median (P50)'),
              _LegendDot(color: AppColors.teal, label: 'Mean'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuartileStripPainter extends CustomPainter {
  _QuartileStripPainter(this.stats);
  final OverviewStats stats;

  @override
  void paint(Canvas canvas, Size size) {
    const maxScale = 500.0;
    final yMid = size.height * 0.48;
    double xOf(double k) => (k.clamp(0.0, maxScale) / maxScale) * size.width;

    // Baseline track (min to max)
    canvas.drawLine(
      Offset(xOf(stats.minK), yMid),
      Offset(xOf(stats.maxK), yMid),
      Paint()
        ..color = AppColors.borderStrong
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Interquartile band (P25 to P75)
    final p25x = xOf(stats.p25K);
    final p75x = math.max(p25x + 6, xOf(stats.p75K));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(p25x, yMid - 6, p75x, yMid + 6),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.navy.withValues(alpha: 0.28),
    );

    // Median marker (Ink vertical bar)
    final medX = xOf(stats.medianK);
    canvas.drawLine(
      Offset(medX, yMid - 9),
      Offset(medX, yMid + 9),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Mean dot (Teal circle)
    final meanX = xOf(stats.meanK);
    canvas.drawCircle(
      Offset(meanX, yMid),
      5.0,
      Paint()..color = AppColors.teal,
    );
    canvas.drawCircle(
      Offset(meanX, yMid),
      5.0,
      Paint()
        ..color = AppColors.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _QuartileStripPainter old) => old.stats != stats;
}

class _ProvinceBreakdownChart extends StatelessWidget {
  const _ProvinceBreakdownChart({
    required this.bundle,
    required this.activeCohort,
  });

  final AnalyticsBundle bundle;
  final String activeCohort;

  static const _provinces = [
    'Kigali city',
    'Southern Province',
    'Eastern Province',
    'Northern Province',
    'Western Province',
  ];

  @override
  Widget build(BuildContext context) {
    final rows =
        _provinces
            .where((p) => bundle.overview.containsKey(p))
            .map((p) => MapEntry(p, bundle.overview[p]!))
            .toList()
          ..sort((a, b) => b.value.meanK.compareTo(a.value.meanK));

    final maxMean = rows.isEmpty
        ? 100.0
        : rows.map((r) => r.value.meanK).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mean Monthly Earnings Across All 5 Provinces (k RWF)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in rows)
          _ComparisonBarRow(
            label: entry.key.replaceAll(' Province', ''),
            sublabel:
                'n=${entry.value.count} • Med ${entry.value.medianK.toStringAsFixed(0)}k',
            valueK: entry.value.meanK,
            maxK: maxMean,
            barColor: entry.key == activeCohort || entry.key == 'Kigali city'
                ? AppColors.navy
                : AppColors.teal,
            emphasized: entry.key == activeCohort,
          ),
      ],
    );
  }
}

class _SexAndTrackBreakdownChart extends StatelessWidget {
  const _SexAndTrackBreakdownChart({
    required this.bundle,
    required this.activeCohort,
  });

  final AnalyticsBundle bundle;
  final String activeCohort;

  @override
  Widget build(BuildContext context) {
    final sexKeys = [
      'Male',
      'Female',
    ].where((k) => bundle.overview.containsKey(k)).toList();
    final trackKeys = [
      'Completed TVET',
      'Completed general',
      'No level completed',
    ].where((k) => bundle.overview.containsKey(k)).toList();

    final maxVal = [
      ...sexKeys,
      ...trackKeys,
    ].map((k) => bundle.overview[k]!.meanK).fold<double>(1.0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By Sex (Female vs Male)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final k in sexKeys)
          _ComparisonBarRow(
            label: k,
            sublabel:
                'n=${bundle.overview[k]!.count} • Med ${bundle.overview[k]!.medianK.toStringAsFixed(0)}k',
            valueK: bundle.overview[k]!.meanK,
            maxK: maxVal,
            barColor: k == 'Female' ? AppColors.teal : AppColors.navy,
            emphasized: k == activeCohort,
          ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.hairline),
        const SizedBox(height: 10),
        const Text(
          'By Education Track',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final k in trackKeys)
          _ComparisonBarRow(
            label: k,
            sublabel:
                'n=${bundle.overview[k]!.count} • Med ${bundle.overview[k]!.medianK.toStringAsFixed(0)}k',
            valueK: bundle.overview[k]!.meanK,
            maxK: maxVal,
            barColor: k == 'Completed TVET'
                ? AppColors.teal
                : (k == 'Completed general'
                      ? AppColors.navy
                      : AppColors.ink.withValues(alpha: 0.45)),
            emphasized: k == activeCohort,
          ),
      ],
    );
  }
}

class _ComparisonBarRow extends StatelessWidget {
  const _ComparisonBarRow({
    required this.label,
    required this.sublabel,
    required this.valueK,
    required this.maxK,
    required this.barColor,
    this.emphasized = false,
  });

  final String label;
  final String sublabel;
  final double valueK;
  final double maxK;
  final Color barColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final frac = (valueK / math.max(1.0, maxK)).clamp(0.06, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  sublabel,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${valueK.toStringAsFixed(1)}k',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: frac),
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            builder: (context, animFrac, _) {
              return Stack(
                children: [
                  Container(
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.subtleFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animFrac.clamp(0.04, 1.0),
                    child: Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 02. Correlation Heatmap (Diverging Crimson - Paper - Navy, filterable by Cohort + Var Set)
class CorrelationHeatmapSection extends ConsumerWidget {
  const CorrelationHeatmapSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  Color _cellColor(double v) {
    if (v >= 0) {
      return Color.lerp(AppColors.paper, AppColors.navy, v.clamp(0.0, 1.0))!;
    }
    return Color.lerp(
      AppColors.paper,
      AppColors.crimson,
      (-v).clamp(0.0, 1.0),
    )!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohort = ref.watch(heatmapCohortFilterProvider);
    final varFilter = ref.watch(heatmapFilterProvider);

    final cohortMap = bundle.heatmap[cohort] ?? bundle.heatmap.values.first;
    final options = cohortMap.keys.toList();
    final data = cohortMap[varFilter] ?? cohortMap.values.first;
    final n = data.labels.length;

    // Extract Income vs Schooling correlation dynamically when both exist in All 6 Vars
    final allVars = cohortMap['All 6 Vars'] ?? data;
    final schIdx = allVars.labels.indexOf('Schooling');
    final incIdx = allVars.labels.indexOf('Income');
    final schIncCorr = (schIdx >= 0 && incIdx >= 0)
        ? allVars.matrix[schIdx][incIdx]
        : null;

    return SectionCard(
      stepNumber: '02',
      title: 'Correlation Heatmap',
      subtitle:
          'Pearson correlations inside $cohort (Crimson = -1, Paper = 0, Navy = +1)',
      icon: Icons.grid_on_rounded,
      accentColor: AppColors.navy,
      filterWidget: SearchableCohortButton(
        buttonKey: const Key('heatmap_cohort_filter'),
        selectedKey: cohort,
        bundle: bundle,
        onSelected: (v) =>
            ref.read(heatmapCohortFilterProvider.notifier).setFilter(v),
      ),
      controlsRow: _SegmentedChips(
        options: options,
        selected: options.contains(varFilter) ? varFilter : options.first,
        onSelected: (v) =>
            ref.read(heatmapFilterProvider.notifier).setFilter(v),
      ),
      footerNote: schIncCorr != null
          ? 'Within $cohort, years of schooling correlates at r = ${schIncCorr >= 0 ? '+' : ''}${schIncCorr.toStringAsFixed(2)} with monthly income, while age and experience move together.'
          : 'Blue cells indicate positive linear correlation toward +1.0; white indicates near zero; crimson indicates negative correlation.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rowLabelW = 60.0;
          const colorBarW = 34.0;
          final gridW = math.max(
            120.0,
            constraints.maxWidth - rowLabelW - colorBarW,
          );
          final cellSize = gridW / n;
          final rowH = cellSize.clamp(30.0, 44.0);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            layoutBuilder: _topAlignedLayout,
            child: Row(
              key: ValueKey('$cohort|$varFilter'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var r = 0; r < n; r++)
                      Row(
                        children: [
                          SizedBox(
                            width: rowLabelW,
                            height: rowH,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                data.labels[r],
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          for (var c = 0; c < n; c++)
                            Container(
                              width: cellSize,
                              height: rowH,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _cellColor(data.matrix[r][c]),
                                border: Border.all(
                                  color: AppColors.hairline,
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                data.matrix[r][c].toStringAsFixed(2),
                                style: TextStyle(
                                  color: data.matrix[r][c].abs() >= 0.45
                                      ? AppColors.paper
                                      : AppColors.ink,
                                  fontSize: n > 4 ? 9.5 : 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: rowLabelW),
                        for (var c = 0; c < n; c++)
                          SizedBox(
                            width: cellSize,
                            child: Text(
                              data.labels[c],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: colorBarW - 8,
                  height: n * rowH,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '+1',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 10,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.hairline),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.navy,
                                AppColors.paper,
                                AppColors.crimson,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '-1',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 03. Earnings vs. Schooling Scatter + Linear Trendline (All 30 Searchable Cohorts)
class ScatterTrendSection extends ConsumerWidget {
  const ScatterTrendSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(scatterFilterProvider);
    final ds = bundle.scatter[filter] ?? bundle.scatter.values.first;

    return SectionCard(
      stepNumber: '03',
      title: 'Earnings vs. Schooling',
      subtitle:
          '$filter (n = ${ds.count}) • OLS correlation r = ${ds.r.toStringAsFixed(2)}',
      icon: Icons.scatter_plot_rounded,
      accentColor: AppColors.teal,
      filterWidget: SearchableCohortButton(
        buttonKey: const Key('scatter_cohort_filter'),
        selectedKey: filter,
        bundle: bundle,
        onSelected: (v) =>
            ref.read(scatterFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Slope: ${ds.slope >= 0 ? '+' : ''}${ds.slope.toStringAsFixed(1)}k RWF per extra year of schooling in $filter. Vertical spread shows why multi-feature modeling (sector, contract, occupation) is essential.',
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(color: AppColors.navy, label: 'Sampled Workers'),
                _LegendDot(color: AppColors.teal, label: 'OLS Linear Fit'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              layoutBuilder: _topAlignedLayout,
              child: SizedBox(
                key: ValueKey(filter),
                height: 205,
                width: double.infinity,
                child: CustomPaint(painter: _ScatterPainter(ds)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter(this.ds);
  final ScatterDataset ds;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 42.0;
    const padB = 26.0;
    const padT = 8.0;
    const padR = 10.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    final gridPaint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;

    const maxY = 500.0;
    for (final tickY in [0.0, 125.0, 250.0, 375.0, 500.0]) {
      final py = padT + chartH * (1 - tickY / maxY);
      canvas.drawLine(Offset(padL, py), Offset(padL + chartW, py), gridPaint);
      _drawText(canvas, '${tickY.toInt()}k', Offset(2, py - 6), 10);
    }

    for (final tickX in [0, 5, 10, 15, 20]) {
      final px = padL + chartW * (tickX / 20.0);
      _drawText(canvas, '$tickX yr', Offset(px - 10, padT + chartH + 6), 9.5);
    }

    final dotPaint = Paint()..color = AppColors.navy.withValues(alpha: 0.36);
    for (final pt in ds.points) {
      final px = padL + chartW * (pt.x.clamp(0.0, 20.0) / 20.0);
      final py = padT + chartH * (1 - pt.y.clamp(0.0, maxY) / maxY);
      canvas.drawCircle(Offset(px, py), 2.7, dotPaint);
    }

    final x1 = ds.xMin.clamp(0.0, 20.0);
    final x2 = ds.xMax.clamp(0.0, 20.0);
    final y1 = (ds.slope * x1 + ds.intercept).clamp(0.0, maxY);
    final y2 = (ds.slope * x2 + ds.intercept).clamp(0.0, maxY);

    final linePaint = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(padL + chartW * (x1 / 20.0), padT + chartH * (1 - y1 / maxY)),
      Offset(padL + chartW * (x2 / 20.0), padT + chartH * (1 - y2 / maxY)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter old) => old.ds != ds;
}

/// 04. SGDRegressor Loss Curve (Train vs Test MSE)
class SgdLossSection extends ConsumerWidget {
  const SgdLossSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(sgdFilterProvider);
    final options = bundle.sgdCurves.keys.toList();
    final curve = bundle.sgdCurves[filter] ?? bundle.sgdCurves.values.first;

    return SectionCard(
      stepNumber: '04',
      title: 'SGDRegressor Training Loss',
      subtitle:
          'Per-epoch MSE via partial_fit across ${curve.epochs.length} epochs',
      icon: Icons.show_chart_rounded,
      accentColor: AppColors.navy,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(sgdFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Final Train MSE: ${curve.trainMse.last.toStringAsFixed(1)} | Final Test MSE: ${curve.testMse.last.toStringAsFixed(1)}. Both curves converge cleanly with no overfitting divergence.',
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(color: AppColors.navy, label: 'Train MSE'),
                _LegendDot(color: AppColors.teal, label: 'Test MSE'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              layoutBuilder: _topAlignedLayout,
              child: SizedBox(
                key: ValueKey(filter),
                height: 190,
                width: double.infinity,
                child: CustomPaint(painter: _LossCurvePainter(curve)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LossCurvePainter extends CustomPainter {
  _LossCurvePainter(this.curve);
  final SgdCurveData curve;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 44.0;
    const padB = 24.0;
    const padT = 10.0;
    const padR = 12.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    final allVals = [...curve.trainMse, ...curve.testMse];
    final minY = (allVals.reduce(math.min) - 30).floorToDouble();
    final maxY = (allVals.reduce(math.max) + 30).ceilToDouble();
    final spanY = math.max(1.0, maxY - minY);
    final totalEp = curve.epochs.length.toDouble();

    final gridPaint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final frac = i / 3.0;
      final val = minY + spanY * frac;
      final py = padT + chartH * (1 - frac);
      canvas.drawLine(Offset(padL, py), Offset(padL + chartW, py), gridPaint);
      _drawText(canvas, val.toStringAsFixed(0), Offset(2, py - 6), 10);
    }

    for (final ep in [1, (totalEp / 2).round(), totalEp.toInt()]) {
      final px = padL + chartW * ((ep - 1) / math.max(1.0, totalEp - 1));
      _drawText(canvas, 'Ep $ep', Offset(px - 10, padT + chartH + 6), 10);
    }

    Path buildPath(List<double> ys) {
      final path = Path();
      for (var i = 0; i < ys.length; i++) {
        final px = padL + chartW * (i / math.max(1, ys.length - 1));
        final py = padT + chartH * (1 - (ys[i] - minY) / spanY);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      return path;
    }

    canvas.drawPath(
      buildPath(curve.trainMse),
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3,
    );
    canvas.drawPath(
      buildPath(curve.testMse),
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3,
    );
  }

  @override
  bool shouldRepaint(covariant _LossCurvePainter old) => old.curve != curve;
}

/// 05. Four-Model Comparison (Winner highlighted in Navy; others muted Slate)
class ModelComparisonSection extends ConsumerWidget {
  const ModelComparisonSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricFilter = ref.watch(modelMetricFilterProvider);
    const options = ['Test MSE', 'Train MSE', 'Test R2 (%)'];
    final models = bundle.modelComparison;

    double metricValue(ModelMetric m) => switch (metricFilter) {
      'Train MSE' => m.trainMse,
      'Test R2 (%)' => m.testR2 * 100,
      _ => m.testMse,
    };

    final maxVal = models.map(metricValue).reduce(math.max);

    return SectionCard(
      stepNumber: '05',
      title: 'Model Comparison',
      subtitle: 'All four scikit-learn regression models on identical LFS 2022 splits',
      icon: Icons.emoji_events_outlined,
      accentColor: AppColors.teal,
      filterWidget: SectionFilterPill(
        value: metricFilter,
        options: options,
        onChanged: (v) =>
            ref.read(modelMetricFilterProvider.notifier).setFilter(v),
      ),
      footerNote: 'RandomForestRegressor achieves the lowest Test MSE (1336.0, R² = 0.65) by capturing non-linear schooling, occupation, and contract interactions.',
      child: SizedBox(
        height: 195,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(models.length, (i) {
            final m = models[i];
            final val = metricValue(m);
            final barFrac = (val / math.max(1.0, maxVal)).clamp(0.15, 1.0);
            final label = metricFilter == 'Test R2 (%)'
                ? '${val.toStringAsFixed(1)}%'
                : val.toStringAsFixed(1);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (m.isBest)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(
                            color: AppColors.paper,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Text(
                      label,
                      style: TextStyle(
                        color: m.isBest ? AppColors.navy : AppColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      height: 110 * barFrac,
                      decoration: BoxDecoration(
                        color: m.isBest
                            ? AppColors.navy
                            : AppColors.ink.withValues(alpha: 0.16),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: m.isBest
                            ? AppColors.navy
                            : AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: m.isBest
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 06. Feature Importance (Clean solid Navy bars on light track)
class FeatureImportanceSection extends ConsumerWidget {
  const FeatureImportanceSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(featureTopNFilterProvider);
    final options = bundle.featureImportance.keys.toList();
    final items =
        bundle.featureImportance[filter] ??
        bundle.featureImportance.values.first;
    final maxImp = items.map((e) => e.importance).reduce(math.max);

    return SectionCard(
      stepNumber: '06',
      title: 'Feature Importance',
      subtitle: 'Top predictors driving the winning RandomForestRegressor',
      icon: Icons.bar_chart_rounded,
      accentColor: AppColors.navy,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) =>
            ref.read(featureTopNFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          '${items.first.name} (${items.first.importance.toStringAsFixed(3)}) leads monthly earnings predictions, followed by occupation group, experience, sector, age, and weekly hours.',
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final frac = (item.importance / math.max(0.01, maxImp)).clamp(
            0.05,
            1.0,
          );
          final barColor = i < 2
              ? AppColors.navy
              : AppColors.navy.withValues(alpha: 0.62);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i < 2 ? AppColors.ink : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: i < 2 ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: frac),
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutCubic,
                    builder: (context, animFrac, _) {
                      return Stack(
                        children: [
                          Container(
                            height: 15,
                            decoration: BoxDecoration(
                              color: AppColors.subtleFill,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: animFrac.clamp(0.04, 1.0),
                            child: Container(
                              height: 15,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    item.importance.toStringAsFixed(3),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

Widget _topAlignedLayout(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.topCenter,
    children: <Widget>[...previousChildren, ?currentChild],
  );
}

void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: AppColors.textSecondary, fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, offset);
}
