import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/prediction_models.dart';
import '../providers/prediction_provider.dart';
import 'section_card.dart';

/// 07. Prediction Form (Grouped 13 TextFields + Quick-Fill Chips + Benchmark Plot Output)
class PredictionSection extends ConsumerStatefulWidget {
  const PredictionSection({super.key, required this.bundle});

  final AnalyticsBundle bundle;

  @override
  ConsumerState<PredictionSection> createState() => _PredictionSectionState();
}

class _PredictionSectionState extends ConsumerState<PredictionSection> {
  late final Map<String, TextEditingController> _controllers;
  bool _appliedInitialDraft = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final spec in kModelInputSpecs)
        spec.key: TextEditingController(text: spec.sampleValue),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _fillDefaultSample() {
    for (final spec in kModelInputSpecs) {
      _controllers[spec.key]!.text = spec.sampleValue;
    }
    ref.read(predictionProvider.notifier).clearOutput();
  }

  void _fillPreset(Map<String, String> values) {
    for (final spec in kModelInputSpecs) {
      _controllers[spec.key]!.text = values[spec.key] ?? spec.sampleValue;
    }
    ref.read(predictionProvider.notifier).clearOutput();
  }

  void _clearAll() {
    for (final ctrl in _controllers.values) {
      ctrl.clear();
    }
    ref.read(predictionProvider.notifier).clearOutput();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final rawInputs = {
      for (final spec in kModelInputSpecs)
        spec.key: _controllers[spec.key]!.text,
    };
    ref.read(predictionProvider.notifier).predict(rawInputs);
  }

  List<Widget> _buildGroupFields(List<InputFieldSpec> specs) {
    final widgets = <Widget>[];
    var i = 0;
    while (i < specs.length) {
      final current = specs[i];
      if (current.fullWidth ||
          i + 1 >= specs.length ||
          specs[i + 1].fullWidth) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InputBox(
              spec: current,
              controller: _controllers[current.key]!,
            ),
          ),
        );
        i += 1;
      } else {
        final next = specs[i + 1];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputBox(
                    spec: current,
                    controller: _controllers[current.key]!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputBox(
                    spec: next,
                    controller: _controllers[next.key]!,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final predState = ref.watch(predictionProvider);

    // Restore saved draft from SharedPreferences once if available.
    if (!_appliedInitialDraft && predState.savedDraft.isNotEmpty) {
      _appliedInitialDraft = true;
      for (final spec in kModelInputSpecs) {
        final saved = predState.savedDraft[spec.key];
        if (saved != null && saved.isNotEmpty) {
          _controllers[spec.key]!.text = saved;
        }
      }
    }

    final liveInputs = predState.submittedInputs.isNotEmpty
        ? predState.submittedInputs
        : {
            for (final spec in kModelInputSpecs)
              spec.key: _controllers[spec.key]!.text.trim(),
          };

    return SectionCard(
      stepNumber: '07',
      title: 'Make a Prediction',
      subtitle: 'Fill the 3 steps below (tap chips or type) to estimate monthly pay and benchmark it against Rwanda LFS 2022 peers',
      icon: Icons.analytics_outlined,
      accentColor: AppColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _fillDefaultSample,
                icon: const Icon(Icons.auto_fix_high, size: 15),
                label: const Text('TVET Kigali'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _fillPreset(kFemaleRuralAgriPreset),
                icon: const Icon(Icons.person_outline, size: 15),
                label: const Text('Female Rural'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('clear_form_button'),
                onPressed: _clearAll,
                icon: const Icon(Icons.clear_all, size: 15),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final group in InputGroup.values) ...[
            _SubgroupHeader(title: group.title),
            const SizedBox(height: 8),
            ..._buildGroupFields(
              kModelInputSpecs.where((s) => s.group == group).toList(),
            ),
            const SizedBox(height: 6),
          ],
          ElevatedButton(
            onPressed: predState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.6),
              foregroundColor: AppColors.paper,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: predState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.paper,
                    ),
                  )
                : const Text(
                    'Predict',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          _ResultDisplayCard(
            key: const Key('prediction_output_area'),
            state: predState,
            bundle: widget.bundle,
            profileInputs: liveInputs,
          ),
          if (predState.recentEstimates.isNotEmpty) ...[
            const SizedBox(height: 14),
            _RecentEstimatesCard(
              estimates: predState.recentEstimates,
              onClear: () =>
                  ref.read(predictionProvider.notifier).clearHistory(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubgroupHeader extends StatelessWidget {
  const _SubgroupHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.subtleFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.spec, required this.controller});

  final InputFieldSpec spec;
  final TextEditingController controller;

  Future<void> _openOccupationSheet(BuildContext context) async {
    final options = spec.allowedValues ?? const [];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.56,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Occupation Group (ISCO)',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.hairline),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.hairline),
                  itemBuilder: (context, i) {
                    final opt = options[i];
                    final selected = controller.text.trim() == opt;
                    return ListTile(
                      dense: true,
                      tileColor: selected
                          ? AppColors.navyTint
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        opt,
                        style: TextStyle(
                          color: selected ? AppColors.navy : AppColors.ink,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.navy,
                              size: 19,
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(opt),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      controller.text = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showQuickChips =
        !spec.useSearchPicker && (spec.allowedValues?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: spec.keyboardType,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
          decoration: InputDecoration(
            labelText: spec.label,
            hintText: spec.sampleValue,
            helperText: spec.helperText,
            helperMaxLines: 2,
            suffixIcon: spec.useSearchPicker
                ? IconButton(
                    tooltip: 'Browse all occupation options',
                    onPressed: () => _openOccupationSheet(context),
                    icon: const Icon(
                      Icons.list_alt_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        if (showQuickChips) ...[
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, val, _) {
              final currentText = val.text.trim();
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: spec.allowedValues!.map((opt) {
                  final active = currentText == opt;
                  return InkWell(
                    onTap: () => controller.text = opt,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.navy : AppColors.paper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active
                              ? AppColors.navy
                              : AppColors.borderStrong,
                        ),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: active
                              ? AppColors.paper
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ResultDisplayCard extends StatelessWidget {
  const _ResultDisplayCard({
    super.key,
    required this.state,
    required this.bundle,
    required this.profileInputs,
  });

  final PredictionState state;
  final AnalyticsBundle bundle;
  final Map<String, String> profileInputs;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (state.isLoading) {
      content = Container(
        key: const ValueKey('pred_loading'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navyTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navy.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 15,
              width: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.navy,
              ),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Estimating earnings via SkillBridge API...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state.errorMessage != null) {
      content = Container(
        key: ValueKey('pred_error_${state.errorMessage}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.crimsonTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.crimson, width: 1.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.crimson, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: AppColors.crimson,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state.result != null) {
      final res = state.result!;
      final predK = res.predictedMonthlyIncomeKRwf;
      final percentile = bundle.estimatePercentile(predK);
      final topShare = (100 - percentile).clamp(1, 99);
      final natStats =
          bundle.overview['All Youth (18-35)'] ?? bundle.overview.values.first;
      final medianDeltaPct =
          ((predK - natStats.medianK) / math.max(1.0, natStats.medianK) * 100)
              .round();
      final deltaText = medianDeltaPct >= 0
          ? '+$medianDeltaPct% vs national median'
          : '$medianDeltaPct% vs national median';

      content = Container(
        key: ValueKey('pred_result_${res.predictedMonthlyIncomeRwf}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tealTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.teal, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'PREDICTED MONTHLY EARNINGS',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    percentile >= 50
                        ? 'Top $topShare% of Youth'
                        : '${percentile}th Percentile',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatWithCommas(res.predictedMonthlyIncomeRwf)} RWF / month',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${predK.toStringAsFixed(2)}k RWF • $deltaText • Model ${res.modelVersion}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _PredictionBenchmarkPlot(
              predictedK: predK,
              bundle: bundle,
              profileInputs: profileInputs,
            ),
          ],
        ),
      );
    } else {
      content = Container(
        key: const ValueKey('pred_idle'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Text(
          'Tap Predict to see your estimated monthly cash pay alongside a real LFS 2022 peer benchmark chart.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previousChildren, ?currentChild],
      ),
      child: content,
    );
  }
}

class _PredictionBenchmarkPlot extends StatelessWidget {
  const _PredictionBenchmarkPlot({
    required this.predictedK,
    required this.bundle,
    required this.profileInputs,
  });

  final double predictedK;
  final AnalyticsBundle bundle;
  final Map<String, String> profileInputs;

  @override
  Widget build(BuildContext context) {
    final provinceKey = profileInputs['province'] ?? 'Kigali city';
    final sexKey = profileInputs['sex'] ?? 'Male';
    final trackKey = profileInputs['education_track'] ?? 'Completed TVET';
    final contractKey = profileInputs['contract_basis'] ?? 'Written contract';

    final provStats = bundle.overview[provinceKey];
    final sexStats = bundle.overview[sexKey];
    final trackStats = bundle.overview[trackKey];
    final contractStats = bundle.overview[contractKey];
    final natStats =
        bundle.overview['All Youth (18-35)'] ?? bundle.overview.values.first;

    final bars = <({String label, double valueK, Color color, bool isPrimary})>[
      (
        label: 'Your Prediction',
        valueK: predictedK,
        color: AppColors.teal,
        isPrimary: true,
      ),
      if (contractStats != null)
        (
          label: '$contractKey Avg',
          valueK: contractStats.meanK,
          color: AppColors.navy,
          isPrimary: false,
        ),
      if (trackStats != null)
        (
          label: '$trackKey Avg',
          valueK: trackStats.meanK,
          color: AppColors.navy.withValues(alpha: 0.72),
          isPrimary: false,
        ),
      if (provStats != null)
        (
          label: '$provinceKey Avg',
          valueK: provStats.meanK,
          color: AppColors.ink.withValues(alpha: 0.48),
          isPrimary: false,
        ),
      if (sexStats != null)
        (
          label: '$sexKey Youth Avg',
          valueK: sexStats.meanK,
          color: AppColors.ink.withValues(alpha: 0.36),
          isPrimary: false,
        ),
      (
        label: 'National Youth Mean',
        valueK: natStats.meanK,
        color: AppColors.ink.withValues(alpha: 0.24),
        isPrimary: false,
      ),
      (
        label: 'National Median (P50)',
        valueK: natStats.medianK,
        color: AppColors.ink.withValues(alpha: 0.16),
        isPrimary: false,
      ),
    ];

    final maxVal = bars.map((b) => b.valueK).fold<double>(1.0, math.max);

    final provPhrase = provStats == null
        ? ''
        : predictedK >= provStats.meanK
        ? 'outperforms the $provinceKey youth average (${provStats.meanK.toStringAsFixed(1)}k)'
        : 'sits below the $provinceKey youth average (${provStats.meanK.toStringAsFixed(1)}k)';

    final sexPhrase = sexStats == null
        ? ''
        : ' vs. ${sexStats.meanK.toStringAsFixed(1)}k for $sexKey workers nationwide';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Benchmark Comparison vs. LFS 2022 Peers (k RWF / mo)',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final bar in bars)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bar.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: bar.isPrimary
                                ? AppColors.teal
                                : AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: bar.isPrimary
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${bar.valueK.toStringAsFixed(1)}k RWF',
                        style: TextStyle(
                          color: bar.isPrimary ? AppColors.teal : AppColors.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: (bar.valueK / math.max(1.0, maxVal)).clamp(
                        0.05,
                        1.0,
                      ),
                    ),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    builder: (context, animFrac, _) {
                      return Stack(
                        children: [
                          Container(
                            height: bar.isPrimary ? 13 : 9,
                            decoration: BoxDecoration(
                              color: AppColors.subtleFill,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: animFrac.clamp(0.04, 1.0),
                            child: Container(
                              height: bar.isPrimary ? 13 : 9,
                              decoration: BoxDecoration(
                                color: bar.color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Text(
              'Insight: This profile $provPhrase$sexPhrase. Formal written contracts, completed TVET skills, and schooling years drive the strongest upward wage shift.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEstimatesCard extends StatelessWidget {
  const _RecentEstimatesCard({required this.estimates, required this.onClear});

  final List<SavedEstimate> estimates;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Recent Saved Estimates (Local)',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  foregroundColor: AppColors.textMuted,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in estimates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.summary,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatWithCommas(item.incomeRwf)} RWF',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
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

String _formatWithCommas(int number) {
  final str = number.toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    final posFromRight = str.length - i;
    buf.write(str[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buf.write(',');
    }
  }
  return buf.toString();
}
