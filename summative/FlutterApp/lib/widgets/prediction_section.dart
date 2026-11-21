import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/prediction_models.dart';
import '../providers/prediction_provider.dart';
import 'section_card.dart';

/// Grouped 13-input prediction form (1 control per backend variable) + unified
/// result/validation panel and LFS 2022 peer benchmark comparison plot.
class PredictionSection extends ConsumerStatefulWidget {
  const PredictionSection({super.key, required this.bundle});

  final AnalyticsBundle? bundle;

  @override
  ConsumerState<PredictionSection> createState() => _PredictionSectionState();
}

class _PredictionSectionState extends ConsumerState<PredictionSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _numControllers;
  late final Map<String, FocusNode> _focusNodes;
  late final Map<String, GlobalKey> _fieldAnchorKeys;
  late final Map<String, GlobalKey<FormFieldState<String>>> _catFieldKeys;
  late final Map<String, String?> _catValues;

  bool _appliedInitialDraft = false;
  bool _suppressClearOnSync = false;

  @override
  void initState() {
    super.initState();
    _numControllers = {
      for (final spec in kModelInputSpecs.where((s) => s.isNumeric))
        spec.key: TextEditingController(text: spec.sampleValue),
    };
    _focusNodes = {
      for (final spec in kModelInputSpecs.where((s) => s.isNumeric))
        spec.key: FocusNode(),
    };
    _fieldAnchorKeys = {
      for (final spec in kModelInputSpecs) spec.key: GlobalKey(),
    };
    _catFieldKeys = {
      for (final spec in kModelInputSpecs.where((s) => !s.isNumeric))
        spec.key: GlobalKey<FormFieldState<String>>(),
    };
    _catValues = {
      for (final spec in kModelInputSpecs.where((s) => !s.isNumeric))
        spec.key: spec.sampleValue,
    };
  }

  @override
  void dispose() {
    for (final ctrl in _numControllers.values) {
      ctrl.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectRawInputs() {
    return {
      for (final spec in kModelInputSpecs)
        spec.key: spec.isNumeric
            ? _numControllers[spec.key]!.text
            : (_catValues[spec.key] ?? ''),
    };
  }

  void _applyValues(Map<String, String?> values) {
    _appliedInitialDraft = true;
    _suppressClearOnSync = true;
    try {
      setState(() {
        for (final spec in kModelInputSpecs) {
          final next = values[spec.key];
          if (spec.isNumeric) {
            _numControllers[spec.key]!.text = next ?? '';
          } else {
            final allowed = spec.allowedValues ?? const [];
            final validNext = (next != null && allowed.contains(next))
                ? next
                : null;
            _catValues[spec.key] = validNext;
            _catFieldKeys[spec.key]!.currentState?.didChange(validNext);
          }
        }
      });
    } finally {
      _suppressClearOnSync = false;
    }
    _formKey.currentState?.validate();
    ref.read(predictionProvider.notifier).clearOutput();
  }

  void _fillDefaultSample() {
    _applyValues({
      for (final spec in kModelInputSpecs) spec.key: spec.sampleValue,
    });
  }

  void _clearAll() {
    _appliedInitialDraft = true;
    _suppressClearOnSync = true;
    try {
      setState(() {
        for (final spec in kModelInputSpecs) {
          if (spec.isNumeric) {
            _numControllers[spec.key]!.clear();
          } else {
            _catValues[spec.key] = null;
            _catFieldKeys[spec.key]!.currentState?.didChange(null);
          }
        }
      });
    } finally {
      _suppressClearOnSync = false;
    }
    ref.read(predictionProvider.notifier).clearOutput();
  }

  void _clearStaleOutputOnEdit() {
    if (_suppressClearOnSync) return;
    _appliedInitialDraft = true;
    final current = ref.read(predictionProvider);
    if (current.result != null || current.errorMessage != null) {
      ref.read(predictionProvider.notifier).clearOutput();
    }
  }

  void _submit() {
    if (ref.read(predictionProvider).isLoading) return;
    _appliedInitialDraft = true;
    FocusManager.instance.primaryFocus?.unfocus();

    final rawInputs = _collectRawInputs();
    _formKey.currentState?.validate();

    final validated = YouthEarningsRequest.validateAndBuild(rawInputs);
    if (validated.error != null || validated.request == null) {
      final invalidKey = validated.firstInvalidKey;
      if (invalidKey != null) {
        final ctx = _fieldAnchorKeys[invalidKey]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: 0.25,
          );
        }
        _focusNodes[invalidKey]?.requestFocus();
      }
      ref.read(predictionProvider.notifier).predict(rawInputs);
      return;
    }

    ref.read(predictionProvider.notifier).predict(rawInputs);
  }

  Widget _buildSingleField(InputFieldSpec spec) {
    final anchorKey = _fieldAnchorKeys[spec.key]!;
    return KeyedSubtree(
      key: anchorKey,
      child: switch (spec.kind) {
        InputKind.integer || InputKind.decimal => TextFormField(
          controller: _numControllers[spec.key]!,
          focusNode: _focusNodes[spec.key]!,
          keyboardType: spec.keyboardType,
          textInputAction: TextInputAction.next,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onChanged: (_) => _clearStaleOutputOnEdit(),
          validator: (val) => validateInputField(spec, val).error,
          style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
          decoration: InputDecoration(
            labelText: spec.label,
            hintText: spec.sampleValue,
            helperText: spec.helperText,
            helperMaxLines: 2,
          ),
        ),
        InputKind.dropdown => DropdownButtonFormField<String>(
          key: _catFieldKeys[spec.key]!,
          initialValue: _catValues[spec.key],
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.teal,
          style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
          hint: Text(
            'Select ${spec.label.toLowerCase()}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          decoration: InputDecoration(
            labelText: spec.label,
            helperText: spec.helperText,
            helperMaxLines: 2,
          ),
          items: (spec.allowedValues ?? const [])
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (next) {
            setState(() => _catValues[spec.key] = next);
            _clearStaleOutputOnEdit();
          },
          validator: (val) => validateInputField(spec, val).error,
        ),
        InputKind.yesNo => FormField<String>(
          key: _catFieldKeys[spec.key]!,
          initialValue: _catValues[spec.key],
          validator: (val) => validateInputField(spec, val).error,
          builder: (fieldState) {
            final current = fieldState.value;
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                helperText: spec.helperText,
                errorText: fieldState.errorText,
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              ),
              child: Row(
                children: (spec.allowedValues ?? const ['Yes', 'No']).map((
                  opt,
                ) {
                  final selected = current == opt;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: opt == 'Yes' ? 8 : 0),
                      child: InkWell(
                        onTap: () {
                          fieldState.didChange(opt);
                          setState(() => _catValues[spec.key] = opt);
                          _clearStaleOutputOnEdit();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.teal
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.teal
                                  : AppColors.borderStrong,
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.paper
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        InputKind.picker => FormField<String>(
          key: _catFieldKeys[spec.key]!,
          initialValue: _catValues[spec.key],
          validator: (val) => validateInputField(spec, val).error,
          builder: (fieldState) {
            final selected = fieldState.value;
            return InkWell(
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final picked = await _openOptionPickerSheet(
                  context: context,
                  title: 'Select ${spec.label} (ISCO)',
                  options: spec.allowedValues ?? const [],
                  currentValue: selected,
                );
                if (picked != null && context.mounted) {
                  fieldState.didChange(picked);
                  setState(() => _catValues[spec.key] = picked);
                  _clearStaleOutputOnEdit();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                isEmpty: selected == null || selected.isEmpty,
                decoration: InputDecoration(
                  labelText: spec.label,
                  helperText: spec.helperText,
                  helperMaxLines: 2,
                  errorText: fieldState.errorText,
                  suffixIcon: const Icon(
                    Icons.list_alt_rounded,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                child: Text(
                  (selected != null && selected.isNotEmpty)
                      ? selected
                      : 'Tap to choose occupation group',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (selected != null && selected.isNotEmpty)
                        ? AppColors.ink
                        : AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                ),
              ),
            );
          },
        ),
      },
    );
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
            child: _buildSingleField(current),
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
                Expanded(child: _buildSingleField(current)),
                const SizedBox(width: 10),
                Expanded(child: _buildSingleField(next)),
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

    // Restore saved draft from SharedPreferences once after initialization.
    if (!_appliedInitialDraft &&
        predState.savedDraft.isNotEmpty &&
        predState.result == null &&
        !predState.isLoading &&
        predState.errorMessage == null) {
      _appliedInitialDraft = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _suppressClearOnSync = true;
        try {
          setState(() {
            for (final spec in kModelInputSpecs) {
              final saved = predState.savedDraft[spec.key];
              if (saved == null || saved.isEmpty) continue;
              if (spec.isNumeric) {
                _numControllers[spec.key]!.text = saved;
              } else if ((spec.allowedValues ?? const []).contains(saved)) {
                _catValues[spec.key] = saved;
                _catFieldKeys[spec.key]!.currentState?.didChange(saved);
              }
            }
          });
        } finally {
          _suppressClearOnSync = false;
        }
      });
    }

    final liveInputs = predState.submittedInputs.isNotEmpty
        ? predState.submittedInputs
        : _collectRawInputs();

    return SectionCard(
      stepNumber: 'PREDICT',
      title: 'Monthly Earnings Predictor',
      subtitle:
          'Complete all 13 required worker, education, and employment inputs',
      icon: Icons.bolt_rounded,
      accentColor: AppColors.teal,
      child: Form(
        key: _formKey,
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
                  onPressed: () => _applyValues(kFemaleRuralAgriPreset),
                  icon: const Icon(Icons.person_outline, size: 15),
                  label: const Text('Female Rural'),
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
              const SizedBox(height: 10),
              ..._buildGroupFields(
                kModelInputSpecs.where((s) => s.group == group).toList(),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: predState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  disabledBackgroundColor: AppColors.teal.withValues(
                    alpha: 0.55,
                  ),
                  foregroundColor: AppColors.paper,
                  elevation: 0,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.navyTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.35)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

Future<String?> _openOptionPickerSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String? currentValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _SearchableOptionSheet(
      title: title,
      options: options,
      currentValue: currentValue,
    ),
  );
}

class _SearchableOptionSheet extends StatefulWidget {
  const _SearchableOptionSheet({
    required this.title,
    required this.options,
    required this.currentValue,
  });

  final String title;
  final List<String> options;
  final String? currentValue;

  @override
  State<_SearchableOptionSheet> createState() => _SearchableOptionSheetState();
}

class _SearchableOptionSheetState extends State<_SearchableOptionSheet> {
  final TextEditingController _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterCtrl.text.trim().toLowerCase();
    final filtered = widget.options
        .where((o) => query.isEmpty || o.toLowerCase().contains(query))
        .toList();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availH = MediaQuery.of(context).size.height - bottomInset;
    final sheetH = (availH * 0.65).clamp(240.0, 480.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetH,
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
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _filterCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Search option...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.teal,
                    size: 19,
                  ),
                ),
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
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.hairline),
                itemBuilder: (context, i) {
                  final opt = filtered[i];
                  final selected = widget.currentValue == opt;
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
                        color: selected ? AppColors.teal : AppColors.ink,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.teal,
                            size: 19,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(opt),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
  final AnalyticsBundle? bundle;
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
          border: Border.all(color: AppColors.navy.withValues(alpha: 0.45)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.teal,
              ),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Calculating prediction…',
                overflow: TextOverflow.ellipsis,
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
                  color: AppColors.crimsonText,
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
      final b = bundle;
      final percentile = b?.estimatePercentile(predK);
      final topShare = percentile != null
          ? (100 - percentile).clamp(1, 99)
          : null;
      final natStats = b == null
          ? null
          : (b.overview['All Youth (18-35)'] ?? b.overview.values.first);
      final medianDeltaPct = natStats == null
          ? null
          : ((predK - natStats.medianK) / math.max(1.0, natStats.medianK) * 100)
                .round();
      final deltaText = medianDeltaPct == null
          ? ''
          : medianDeltaPct >= 0
          ? ' • +$medianDeltaPct% vs national median'
          : ' • $medianDeltaPct% vs national median';

      content = Container(
        key: ValueKey('pred_result_${res.predictedMonthlyIncomeRwf}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderStrong.withValues(alpha: 0.85),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (percentile != null && topShare != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      percentile >= 50
                          ? 'Top $topShare% of Youth'
                          : '${percentile}th Percentile',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatWithCommas(res.predictedMonthlyIncomeRwf)} ${res.currency} / month',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${predK.toStringAsFixed(2)}k ${res.currency}$deltaText • Model ${res.modelVersion}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (b != null) ...[
              const SizedBox(height: 14),
              _PredictionBenchmarkPlot(
                predictedK: predK,
                bundle: b,
                profileInputs: profileInputs,
              ),
            ],
          ],
        ),
      );
    } else {
      content = Container(
        key: const ValueKey('pred_idle'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.subtleFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Text(
          'Your prediction will appear here.',
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
          color: AppColors.slateNavy,
          isPrimary: false,
        ),
      if (provStats != null)
        (
          label: '$provinceKey Avg',
          valueK: provStats.meanK,
          color: AppColors.ink,
          isPrimary: false,
        ),
      if (sexStats != null)
        (
          label: '$sexKey Youth Avg',
          valueK: sexStats.meanK,
          color: AppColors.textMuted,
          isPrimary: false,
        ),
      (
        label: 'National Youth Mean',
        valueK: natStats.meanK,
        color: const Color(0xFF94A3B8),
        isPrimary: false,
      ),
      (
        label: 'National Median (P50)',
        valueK: natStats.medianK,
        color: AppColors.borderStrong,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Benchmark Comparison vs. LFS 2022 Peers (k RWF / mo)',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final bar in bars)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                                : AppColors.ink,
                            fontSize: 12,
                            fontWeight: bar.isPrimary
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${bar.valueK.toStringAsFixed(1)}k RWF',
                        style: TextStyle(
                          color: bar.isPrimary ? AppColors.teal : AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
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
                                color: bar.color,
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
            ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.subtleFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.borderStrong.withValues(alpha: 0.75),
              ),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11.5,
                  height: 1.4,
                ),
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.info_rounded,
                        size: 14.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const TextSpan(
                    text: 'Insight: ',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text:
                        'This profile $provPhrase$sexPhrase. Formal written contracts, completed TVET skills, and schooling years drive the strongest upward wage shift.',
                  ),
                ],
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
        color: AppColors.subtleFill,
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
                      color: AppColors.teal,
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
