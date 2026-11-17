import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/analytics_models.dart';
import '../providers/analytics_providers.dart';
import 'section_card.dart';

/// 01. Dataset Overview
class DatasetOverviewSection extends ConsumerWidget {
  const DatasetOverviewSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(overviewFilterProvider);
    final options = bundle.overview.keys.toList();
    final stats = bundle.overview[filter] ?? bundle.overview.values.first;

    return SectionCard(
      stepNumber: '01',
      title: 'Dataset Overview',
      subtitle: 'Rwanda LFS 2022 employed youth cash earners (<= 500k RWF)',
      icon: Icons.dataset_outlined,
      accentColor: AppColors.cyan,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(overviewFilterProvider.notifier).setFilter(v),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '${stats.count}',
                  label: 'Youth Workers',
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: '${stats.meanK.toStringAsFixed(1)}k',
                  label: 'Avg Monthly Pay',
                  color: AppColors.purple,
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
                  label: 'Median Pay (RWF)',
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value:
                      '${stats.minK.toStringAsFixed(1)}k–${stats.maxK.toStringAsFixed(0)}k',
                  label: 'Min–Max Range',
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.16), AppColors.inputFill],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 02. Correlation Heatmap
class CorrelationHeatmapSection extends ConsumerWidget {
  const CorrelationHeatmapSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  Color _cellColor(double v) {
    if (v >= 0) {
      return Color.lerp(AppColors.heatZero, AppColors.heatPos, v.clamp(0.0, 1.0))!;
    }
    return Color.lerp(AppColors.heatZero, AppColors.heatNeg, (-v).clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(heatmapFilterProvider);
    final options = bundle.heatmap.keys.toList();
    final data = bundle.heatmap[filter] ?? bundle.heatmap.values.first;
    final n = data.labels.length;

    return SectionCard(
      stepNumber: '02',
      title: 'Correlation Heatmap',
      subtitle: 'Pearson correlations across numeric features and monthly income',
      icon: Icons.grid_on_rounded,
      accentColor: AppColors.indigo,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(heatmapFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Years of schooling correlates most strongly with monthly income (r = +0.62), while age and experience show moderate collinearity (r = +0.60).',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rowLabelW = 58.0;
          const colorBarW = 34.0;
          final gridW = math.max(120.0, constraints.maxWidth - rowLabelW - colorBarW);
          final cellSize = gridW / n;

          return Row(
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
                          height: cellSize.clamp(30.0, 46.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              data.labels[r],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        for (var c = 0; c < n; c++)
                          Container(
                            width: cellSize,
                            height: cellSize.clamp(30.0, 46.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _cellColor(data.matrix[r][c]),
                              border: Border.all(
                                color: AppColors.bgTop.withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              data.matrix[r][c].toStringAsFixed(2),
                              style: TextStyle(
                                color: data.matrix[r][c].abs() > 0.35
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
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
                              fontWeight: FontWeight.w600,
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
                height: n * cellSize.clamp(30.0, 46.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('+1', style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                    Expanded(
                      child: Container(
                        width: 10,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.heatPos,
                              AppColors.heatZero,
                              AppColors.heatNeg,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Text('-1', style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 03. Earnings vs. Schooling Scatter + Linear Trendline
class ScatterTrendSection extends ConsumerWidget {
  const ScatterTrendSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(scatterFilterProvider);
    final options = bundle.scatter.keys.toList();
    final ds = bundle.scatter[filter] ?? bundle.scatter.values.first;

    return SectionCard(
      stepNumber: '03',
      title: 'Earnings vs. Schooling',
      subtitle: 'Sampled LFS workers (${ds.count} in filter) + 1-feature OLS fit (r = ${ds.r.toStringAsFixed(2)})',
      icon: Icons.scatter_plot_rounded,
      accentColor: AppColors.purple,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(scatterFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Each extra year of schooling lifts expected monthly pay (slope +${ds.slope.toStringAsFixed(1)}k RWF/yr), while wide vertical spread motivates adding job and contract features.',
      child: SizedBox(
        height: 205,
        width: double.infinity,
        child: CustomPaint(painter: _ScatterPainter(ds)),
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
    const padB = 24.0;
    const padT = 10.0;
    const padR = 10.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    const maxY = 500.0;
    for (final tickY in [0.0, 125.0, 250.0, 375.0, 500.0]) {
      final py = padT + chartH * (1 - tickY / maxY);
      canvas.drawLine(Offset(padL, py), Offset(padL + chartW, py), gridPaint);
      _drawText(canvas, '${tickY.toInt()}k', Offset(2, py - 6), 10);
    }

    for (final tickX in [0, 5, 10, 15, 20]) {
      final px = padL + chartW * (tickX / 20.0);
      _drawText(canvas, '$tickX', Offset(px - 6, padT + chartH + 6), 10);
    }

    final dotPaint = Paint()..color = AppColors.cyan.withValues(alpha: 0.65);
    for (final pt in ds.points) {
      final px = padL + chartW * (pt.x.clamp(0.0, 20.0) / 20.0);
      final py = padT + chartH * (1 - pt.y.clamp(0.0, maxY) / maxY);
      canvas.drawCircle(Offset(px, py), 2.5, dotPaint);
    }

    // Fitted 1-feature linear regression line
    final x1 = ds.xMin.clamp(0.0, 20.0);
    final x2 = ds.xMax.clamp(0.0, 20.0);
    final y1 = (ds.slope * x1 + ds.intercept).clamp(0.0, maxY);
    final y2 = (ds.slope * x2 + ds.intercept).clamp(0.0, maxY);

    final linePaint = Paint()
      ..color = AppColors.purple
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
      subtitle: 'Per-epoch MSE recorded via partial_fit across ${curve.epochs.length} epochs',
      icon: Icons.show_chart_rounded,
      accentColor: AppColors.cyan,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(sgdFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Final Train MSE: ${curve.trainMse.last.toStringAsFixed(1)} | Final Test MSE: ${curve.testMse.last.toStringAsFixed(1)}. Both curves flatten smoothly without overfitting.',
      child: Column(
        children: [
          Row(
            children: const [
              _LegendDot(color: AppColors.cyan, label: 'Train MSE'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.amber, label: 'Test MSE'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(painter: _LossCurvePainter(curve)),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
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
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
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
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawPath(
      buildPath(curve.testMse),
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _LossCurvePainter old) => old.curve != curve;
}

/// 05. Four-Model Comparison
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
    final colors = [
      AppColors.emerald,
      AppColors.purple,
      AppColors.cyan,
      AppColors.indigo,
    ];

    return SectionCard(
      stepNumber: '05',
      title: 'Model Comparison',
      subtitle: 'All four scikit-learn regression models evaluated on the same test split',
      icon: Icons.emoji_events_outlined,
      accentColor: AppColors.emerald,
      filterWidget: SectionFilterPill(
        value: metricFilter,
        options: options,
        onChanged: (v) => ref.read(modelMetricFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'RandomForestRegressor achieves the lowest Test MSE (1336.0, R² = 0.65) by capturing non-linear schooling, occupation, and contract interactions.',
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(
                            color: AppColors.bgTop,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 110 * barFrac,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colors[i], colors[i].withValues(alpha: 0.45)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: m.isBest
                            ? Border.all(color: AppColors.emerald, width: 1.5)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
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

/// 06. Feature Importance
class FeatureImportanceSection extends ConsumerWidget {
  const FeatureImportanceSection({super.key, required this.bundle});
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(featureTopNFilterProvider);
    final options = bundle.featureImportance.keys.toList();
    final items =
        bundle.featureImportance[filter] ?? bundle.featureImportance.values.first;
    final maxImp = items.map((e) => e.importance).reduce(math.max);

    return SectionCard(
      stepNumber: '06',
      title: 'Feature Importance',
      subtitle: 'Top predictors driving the winning RandomForestRegressor',
      icon: Icons.star_outline_rounded,
      accentColor: AppColors.purple,
      filterWidget: SectionFilterPill(
        value: filter,
        options: options,
        onChanged: (v) => ref.read(featureTopNFilterProvider.notifier).setFilter(v),
      ),
      footerNote:
          'Years of schooling (0.525) and occupation type dominate monthly pay predictions, alongside work experience, sector, age, and weekly hours.',
      child: Column(
        children: items.map((item) {
          final frac = (item.importance / math.max(0.01, maxImp)).clamp(0.05, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.cyan, AppColors.purple],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    item.importance.toStringAsFixed(3),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
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
