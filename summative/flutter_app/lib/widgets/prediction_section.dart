import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/prediction_models.dart';
import '../providers/prediction_provider.dart';
import 'section_card.dart';

/// 07. Prediction Form (13 labelled text boxes + "Predict" button + unified Output/Error box)
class PredictionSection extends ConsumerStatefulWidget {
  const PredictionSection({super.key});

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

  void _fillSample() {
    for (final spec in kModelInputSpecs) {
      _controllers[spec.key]!.text = spec.sampleValue;
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

  List<Widget> _buildInputRows() {
    final rows = <Widget>[];
    var i = 0;
    while (i < kModelInputSpecs.length) {
      final current = kModelInputSpecs[i];
      if (current.fullWidth || i + 1 >= kModelInputSpecs.length || kModelInputSpecs[i + 1].fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InputBox(spec: current, controller: _controllers[current.key]!),
          ),
        );
        i += 1;
      } else {
        final next = kModelInputSpecs[i + 1];
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputBox(spec: current, controller: _controllers[current.key]!),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputBox(spec: next, controller: _controllers[next.key]!),
                ),
              ],
            ),
          ),
        );
        i += 2;
      }
    }
    return rows;
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

    return SectionCard(
      stepNumber: '07',
      title: 'Make a Prediction',
      subtitle: 'Enter all 13 profile attributes to estimate monthly cash earnings',
      icon: Icons.bolt_rounded,
      accentColor: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSample,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Fill Sample'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._buildInputRows(),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: predState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: AppColors.bgTop,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: predState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.bgTop,
                      ),
                    )
                  : const Text(
                      'Predict',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _ResultDisplayCard(state: predState),
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

class _InputBox extends StatelessWidget {
  const _InputBox({required this.spec, required this.controller});

  final InputFieldSpec spec;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: spec.keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: spec.label,
        hintText: spec.sampleValue,
        helperText: spec.helperText,
        helperMaxLines: 2,
      ),
    );
  }
}

class _ResultDisplayCard extends StatelessWidget {
  const _ResultDisplayCard({required this.state});
  final PredictionState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45)),
        ),
        child: const Text(
          'Contacting SkillBridge API on Render...',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.cyan, fontSize: 13),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Container(
        key: const Key('prediction_output_area'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.coralTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.coral, width: 1.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFFECDD3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.result != null) {
      final res = state.result!;
      return Container(
        key: const Key('prediction_output_area'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.emeraldTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.emerald, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Predicted Monthly Earnings',
              style: TextStyle(
                color: AppColors.emerald,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatWithCommas(res.predictedMonthlyIncomeRwf)} RWF / month',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${res.predictedMonthlyIncomeKRwf.toStringAsFixed(2)}k RWF • Model ${res.modelVersion}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('prediction_output_area'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'Predicted monthly cash earnings will appear here after tapping Predict.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
    );
  }
}

class _RecentEstimatesCard extends StatelessWidget {
  const _RecentEstimatesCard({
    required this.estimates,
    required this.onClear,
  });

  final List<SavedEstimate> estimates;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Recent Saved Estimates (Local)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                      color: AppColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
