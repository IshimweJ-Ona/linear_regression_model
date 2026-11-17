import 'package:flutter/material.dart';

enum InputGroup {
  profile('1. Worker Profile'),
  skills('2. Education & Experience'),
  employment('3. Job & Contract Terms');

  const InputGroup(this.title);
  final String title;
}

class InputFieldSpec {
  const InputFieldSpec({
    required this.key,
    required this.label,
    required this.helperText,
    required this.sampleValue,
    required this.group,
    this.isNumeric = false,
    this.isInteger = false,
    this.minValue,
    this.maxValue,
    this.allowedValues,
    this.fullWidth = false,
    this.useSearchPicker = false,
  });

  final String key;
  final String label;
  final String helperText;
  final String sampleValue;
  final InputGroup group;
  final bool isNumeric;
  final bool isInteger;
  final double? minValue;
  final double? maxValue;
  final List<String>? allowedValues;
  final bool fullWidth;
  final bool useSearchPicker;

  TextInputType get keyboardType => isNumeric
      ? TextInputType.numberWithOptions(decimal: !isInteger)
      : TextInputType.text;
}

/// Contrasting realistic Rwanda LFS 2022 test presets for quick demonstration.
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
/// grouped intuitively for clarity while keeping every predictor as an editable TextField.
const List<InputFieldSpec> kModelInputSpecs = [
  // 1. Worker Profile
  InputFieldSpec(
    key: 'age',
    label: 'Age (18-35)',
    helperText: 'Whole number 18–35',
    sampleValue: '25',
    group: InputGroup.profile,
    isNumeric: true,
    isInteger: true,
    minValue: 18,
    maxValue: 35,
  ),
  InputFieldSpec(
    key: 'household_size',
    label: 'Household Size (1-25)',
    helperText: 'People in household (1–25)',
    sampleValue: '3',
    group: InputGroup.profile,
    isNumeric: true,
    isInteger: true,
    minValue: 1,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'sex',
    label: 'Sex',
    helperText: 'Tap chip or type Male / Female',
    sampleValue: 'Male',
    group: InputGroup.profile,
    allowedValues: ['Male', 'Female'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'province',
    label: 'Province',
    helperText: 'Tap any of Rwanda’s 5 provinces or type exact name',
    sampleValue: 'Kigali city',
    group: InputGroup.profile,
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
    helperText: 'Tap chip or type Urban / Rural',
    sampleValue: 'Urban',
    group: InputGroup.profile,
    allowedValues: ['Urban', 'Rural'],
    fullWidth: true,
  ),

  // 2. Education & Experience
  InputFieldSpec(
    key: 'years_schooling',
    label: 'Schooling Yrs (0-22)',
    helperText: 'Total completed years (0–22)',
    sampleValue: '16',
    group: InputGroup.skills,
    isNumeric: true,
    isInteger: true,
    minValue: 0,
    maxValue: 22,
  ),
  InputFieldSpec(
    key: 'experience_years',
    label: 'Experience Yrs (0-25)',
    helperText: 'Years in current work (0–25)',
    sampleValue: '3',
    group: InputGroup.skills,
    isNumeric: true,
    isInteger: true,
    minValue: 0,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'education_track',
    label: 'Education Track',
    helperText: 'Tap track or type exact option',
    sampleValue: 'Completed TVET',
    group: InputGroup.skills,
    allowedValues: ['Completed TVET', 'Completed general', 'No level completed'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'internet_use',
    label: 'Internet Use',
    helperText: 'Regularly uses internet?',
    sampleValue: 'Yes',
    group: InputGroup.skills,
    allowedValues: ['Yes', 'No'],
    fullWidth: true,
  ),

  // 3. Job & Contract Terms
  InputFieldSpec(
    key: 'weekly_hours',
    label: 'Weekly Hours (1-100)',
    helperText: 'Hours worked per week (1–100)',
    sampleValue: '45',
    group: InputGroup.employment,
    isNumeric: true,
    isInteger: false,
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
    allowedValues: ['Agriculture', 'Industry', 'Services'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'contract_basis',
    label: 'Contract Basis',
    helperText: 'Formal written contract or informal oral agreement',
    sampleValue: 'Written contract',
    group: InputGroup.employment,
    allowedValues: ['Written contract', 'Oral agreement'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'occupation_group',
    label: 'Occupation Group',
    helperText: 'Tap search icon to choose from all 9 ISCO groups, or type exact name',
    sampleValue: 'Technicians and associate professionals',
    group: InputGroup.employment,
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
    useSearchPicker: true,
  ),
];

class YouthEarningsRequest {
  const YouthEarningsRequest(this.payload);

  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => payload;

  /// Validates all 13 text inputs and returns either a valid request or a readable error.
  static ({YouthEarningsRequest? request, String? error}) validateAndBuild(
    Map<String, String> rawInputs,
  ) {
    final parsed = <String, dynamic>{};

    for (final spec in kModelInputSpecs) {
      final raw = (rawInputs[spec.key] ?? '').trim();
      if (raw.isEmpty) {
        return (request: null, error: '${spec.label}: This field is required.');
      }

      if (spec.isNumeric) {
        if (spec.isInteger) {
          final intVal = int.tryParse(raw);
          if (intVal == null) {
            return (
              request: null,
              error: '${spec.label}: Wrong type—enter a whole number.',
            );
          }
          if (intVal < spec.minValue! || intVal > spec.maxValue!) {
            return (
              request: null,
              error:
                  '${spec.label}: Out of range—must be between ${spec.minValue!.toInt()} and ${spec.maxValue!.toInt()}.',
            );
          }
          parsed[spec.key] = intVal;
        } else {
          final doubleVal = double.tryParse(raw);
          if (doubleVal == null || doubleVal.isNaN || doubleVal.isInfinite) {
            return (
              request: null,
              error: '${spec.label}: Wrong type—enter a valid number.',
            );
          }
          if (doubleVal < spec.minValue! || doubleVal > spec.maxValue!) {
            return (
              request: null,
              error:
                  '${spec.label}: Out of range—must be between ${spec.minValue!.toInt()} and ${spec.maxValue!.toInt()}.',
            );
          }
          parsed[spec.key] = doubleVal;
        }
      } else {
        final allowed = spec.allowedValues ?? const [];
        if (allowed.isNotEmpty && !allowed.contains(raw)) {
          return (
            request: null,
            error: '${spec.label}: Invalid option "$raw". Allowed: ${allowed.join(", ")}.',
          );
        }
        parsed[spec.key] = raw;
      }
    }

    return (request: YouthEarningsRequest(parsed), error: null);
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
      predictedMonthlyIncomeRwf:
          (json['predicted_monthly_income_rwf'] as num).toInt(),
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
