import 'package:flutter/material.dart';

enum InputGroup {
  profile('1. Worker Profile'),
  skills('2. Education & Experience'),
  employment('3. Employment Details');

  const InputGroup(this.title);
  final String title;
}

enum InputKind { integer, decimal, dropdown, yesNo, picker }

class InputFieldSpec {
  const InputFieldSpec({
    required this.key,
    required this.label,
    required this.helperText,
    required this.sampleValue,
    required this.group,
    required this.kind,
    this.minValue,
    this.maxValue,
    this.allowedValues,
    this.fullWidth = false,
  });

  final String key;
  final String label;
  final String helperText;
  final String sampleValue;
  final InputGroup group;
  final InputKind kind;
  final double? minValue;
  final double? maxValue;
  final List<String>? allowedValues;
  final bool fullWidth;

  bool get isNumeric => kind == InputKind.integer || kind == InputKind.decimal;
  bool get isInteger => kind == InputKind.integer;

  TextInputType get keyboardType => switch (kind) {
    InputKind.integer => TextInputType.number,
    InputKind.decimal => const TextInputType.numberWithOptions(decimal: true),
    _ => TextInputType.text,
  };
}

/// Contrasting realistic Rwanda LFS 2022 preset for quick comparison.
const Map<String, String> kFemaleRuralAgriPreset = {
  'age': '23',
  'sex': 'Female',
  'province': 'Southern Province',
  'urban_rural': 'Rural',
  'household_size': '5',
  'years_schooling': '6',
  'education_track': 'No level completed',
  'experience_years': '3',
  'internet_use': 'No',
  'sector': 'Agriculture',
  'occupation_group': 'Elementary occupations',
  'contract_basis': 'Oral agreement',
  'weekly_hours': '40',
};

/// Exact 13 input features expected by FastAPI's YouthEarningsInput schema,
/// driven directly by backend bounds and approved categories.
const List<InputFieldSpec> kModelInputSpecs = [
  // 1. Worker Profile
  InputFieldSpec(
    key: 'age',
    label: 'Age (18-35)',
    helperText: 'Whole number 18–35',
    sampleValue: '25',
    group: InputGroup.profile,
    kind: InputKind.integer,
    minValue: 18,
    maxValue: 35,
  ),
  InputFieldSpec(
    key: 'household_size',
    label: 'Household Size (1-25)',
    helperText: 'Whole number 1–25',
    sampleValue: '3',
    group: InputGroup.profile,
    kind: InputKind.integer,
    minValue: 1,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'sex',
    label: 'Sex',
    helperText: 'Select Male or Female',
    sampleValue: 'Male',
    group: InputGroup.profile,
    kind: InputKind.dropdown,
    allowedValues: ['Male', 'Female'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'province',
    label: 'Province',
    helperText: 'Select province of residence',
    sampleValue: 'Kigali city',
    group: InputGroup.profile,
    kind: InputKind.dropdown,
    allowedValues: [
      'Kigali city',
      'Southern Province',
      'Western Province',
      'Northern Province',
      'Eastern Province',
    ],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'urban_rural',
    label: 'Urban / Rural',
    helperText: 'Select Urban or Rural',
    sampleValue: 'Urban',
    group: InputGroup.profile,
    kind: InputKind.dropdown,
    allowedValues: ['Urban', 'Rural'],
    fullWidth: true,
  ),

  // 2. Education & Experience
  InputFieldSpec(
    key: 'years_schooling',
    label: 'Schooling Yrs (0-22)',
    helperText: 'Whole number 0–22',
    sampleValue: '16',
    group: InputGroup.skills,
    kind: InputKind.integer,
    minValue: 0,
    maxValue: 22,
  ),
  InputFieldSpec(
    key: 'experience_years',
    label: 'Experience Yrs (0-25)',
    helperText: 'Whole number 0–25',
    sampleValue: '3',
    group: InputGroup.skills,
    kind: InputKind.integer,
    minValue: 0,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'education_track',
    label: 'Education Track',
    helperText: 'Select highest track completed',
    sampleValue: 'Completed TVET',
    group: InputGroup.skills,
    kind: InputKind.dropdown,
    allowedValues: [
      'Completed TVET',
      'Completed general',
      'No level completed',
    ],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'internet_use',
    label: 'Internet Use',
    helperText: 'Regularly uses internet (Yes / No)',
    sampleValue: 'Yes',
    group: InputGroup.skills,
    kind: InputKind.yesNo,
    allowedValues: ['Yes', 'No'],
    fullWidth: true,
  ),

  // 3. Employment Details
  InputFieldSpec(
    key: 'weekly_hours',
    label: 'Weekly Hours (1-100)',
    helperText: 'Number 1–100 (decimals allowed, e.g. 42.5)',
    sampleValue: '45',
    group: InputGroup.employment,
    kind: InputKind.decimal,
    minValue: 1,
    maxValue: 100,
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'sector',
    label: 'Sector',
    helperText: 'Economic sector of main job',
    sampleValue: 'Services',
    group: InputGroup.employment,
    kind: InputKind.dropdown,
    allowedValues: ['Agriculture', 'Industry', 'Services'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'contract_basis',
    label: 'Contract Basis',
    helperText: 'Formal written contract or oral agreement',
    sampleValue: 'Written contract',
    group: InputGroup.employment,
    kind: InputKind.dropdown,
    allowedValues: ['Written contract', 'Oral agreement'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'occupation_group',
    label: 'Occupation Group',
    helperText: 'Choose from all 9 ISCO occupation groups',
    sampleValue: 'Technicians and associate professionals',
    group: InputGroup.employment,
    kind: InputKind.picker,
    allowedValues: [
      'Managers',
      'Professionals',
      'Technicians and associate professionals',
      'Clerical support workers',
      'Service and sales workers',
      'Skilled agricultural, forestry and fishery workers',
      'Craft and related trades workers',
      'Plant and machine operators and assemblers',
      'Elementary occupations',
    ],
    fullWidth: true,
  ),
];

/// Validates a single field against the authoritative backend schema.
/// Returns `null` when valid, or a concise field-specific message when invalid.
({dynamic parsedValue, String? error}) validateInputField(
  InputFieldSpec spec,
  String? rawValue,
) {
  final raw = (rawValue ?? '').trim();
  if (raw.isEmpty) {
    return (parsedValue: null, error: '${spec.label}: This field is required.');
  }

  switch (spec.kind) {
    case InputKind.integer:
      if (!RegExp(r'^\d+$').hasMatch(raw)) {
        if (raw.contains('.')) {
          return (
            parsedValue: null,
            error:
                '${spec.label}: Wrong type—enter a whole number without decimals.',
          );
        }
        return (
          parsedValue: null,
          error:
              '${spec.label}: Wrong type—enter digits only (${spec.minValue!.toInt()}–${spec.maxValue!.toInt()}).',
        );
      }
      final intVal = int.tryParse(raw);
      if (intVal == null) {
        return (
          parsedValue: null,
          error: '${spec.label}: Wrong type—enter a valid whole number.',
        );
      }
      if (intVal < spec.minValue! || intVal > spec.maxValue!) {
        return (
          parsedValue: null,
          error:
              '${spec.label}: Out of range—must be between ${spec.minValue!.toInt()} and ${spec.maxValue!.toInt()}.',
        );
      }
      return (parsedValue: intVal, error: null);

    case InputKind.decimal:
      if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(raw)) {
        return (
          parsedValue: null,
          error:
              '${spec.label}: Wrong type—enter a valid number (${spec.minValue!.toInt()}–${spec.maxValue!.toInt()}).',
        );
      }
      final doubleVal = double.tryParse(raw);
      if (doubleVal == null || !doubleVal.isFinite) {
        return (
          parsedValue: null,
          error: '${spec.label}: Wrong type—enter a valid finite number.',
        );
      }
      if (doubleVal < spec.minValue! || doubleVal > spec.maxValue!) {
        return (
          parsedValue: null,
          error:
              '${spec.label}: Out of range—must be between ${spec.minValue!.toInt()} and ${spec.maxValue!.toInt()}.',
        );
      }
      return (parsedValue: doubleVal, error: null);

    case InputKind.dropdown:
    case InputKind.yesNo:
    case InputKind.picker:
      final allowed = spec.allowedValues ?? const [];
      if (allowed.isNotEmpty && !allowed.contains(raw)) {
        return (
          parsedValue: null,
          error:
              '${spec.label}: Invalid option "$raw". Select one of the approved choices.',
        );
      }
      return (parsedValue: raw, error: null);
  }
}

class YouthEarningsRequest {
  const YouthEarningsRequest(this.payload);

  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => payload;

  /// Validates all 13 model inputs and returns either a valid API payload or
  /// the first validation error and field key so the UI can focus/scroll to it.
  static ({
    YouthEarningsRequest? request,
    String? error,
    String? firstInvalidKey,
  })
  validateAndBuild(Map<String, String> rawInputs) {
    final parsed = <String, dynamic>{};

    for (final spec in kModelInputSpecs) {
      final check = validateInputField(spec, rawInputs[spec.key]);
      if (check.error != null) {
        return (request: null, error: check.error, firstInvalidKey: spec.key);
      }
      parsed[spec.key] = check.parsedValue;
    }

    return (
      request: YouthEarningsRequest(parsed),
      error: null,
      firstInvalidKey: null,
    );
  }
}

class PredictionResult {
  const PredictionResult({
    required this.predictedMonthlyIncomeKRwf,
    required this.predictedMonthlyIncomeRwf,
    required this.currency,
    required this.modelVersion,
  });

  final double predictedMonthlyIncomeKRwf;
  final int predictedMonthlyIncomeRwf;
  final String currency;
  final String modelVersion;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedMonthlyIncomeKRwf:
          (json['predicted_monthly_income_k_rwf'] as num).toDouble(),
      predictedMonthlyIncomeRwf: (json['predicted_monthly_income_rwf'] as num)
          .toInt(),
      currency: json['currency'] as String,
      modelVersion: json['model_version'] as String,
    );
  }
}

class SavedEstimate {
  const SavedEstimate({
    required this.summary,
    required this.incomeKRwf,
    required this.incomeRwf,
  });

  final String summary;
  final double incomeKRwf;
  final int incomeRwf;

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'income_k_rwf': incomeKRwf,
    'income_rwf': incomeRwf,
  };

  factory SavedEstimate.fromJson(Map<String, dynamic> json) {
    return SavedEstimate(
      summary: json['summary'] as String,
      incomeKRwf: (json['income_k_rwf'] as num).toDouble(),
      incomeRwf: (json['income_rwf'] as num).toInt(),
    );
  }
}
