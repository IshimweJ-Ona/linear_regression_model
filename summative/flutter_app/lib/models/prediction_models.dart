import 'package:flutter/material.dart';

class InputFieldSpec {
  const InputFieldSpec({
    required this.key,
    required this.label,
    required this.helperText,
    required this.sampleValue,
    this.isNumeric = false,
    this.isInteger = false,
    this.minValue,
    this.maxValue,
    this.allowedValues,
    this.fullWidth = false,
  });

  final String key;
  final String label;
  final String helperText;
  final String sampleValue;
  final bool isNumeric;
  final bool isInteger;
  final double? minValue;
  final double? maxValue;
  final List<String>? allowedValues;
  final bool fullWidth;

  TextInputType get keyboardType => isNumeric
      ? TextInputType.numberWithOptions(decimal: !isInteger)
      : TextInputType.text;
}

/// Exact 13 input features expected by FastAPI's YouthEarningsInput schema.
const List<InputFieldSpec> kModelInputSpecs = [
  InputFieldSpec(
    key: 'age',
    label: 'Age (18-35)',
    helperText: 'Whole number 18-35',
    sampleValue: '25',
    isNumeric: true,
    isInteger: true,
    minValue: 18,
    maxValue: 35,
  ),
  InputFieldSpec(
    key: 'years_schooling',
    label: 'Schooling Yrs (0-22)',
    helperText: 'Whole number 0-22',
    sampleValue: '16',
    isNumeric: true,
    isInteger: true,
    minValue: 0,
    maxValue: 22,
  ),
  InputFieldSpec(
    key: 'experience_years',
    label: 'Experience Yrs (0-25)',
    helperText: 'Whole number 0-25',
    sampleValue: '3',
    isNumeric: true,
    isInteger: true,
    minValue: 0,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'weekly_hours',
    label: 'Weekly Hours (1-100)',
    helperText: 'Number 1-100',
    sampleValue: '45',
    isNumeric: true,
    isInteger: false,
    minValue: 1,
    maxValue: 100,
  ),
  InputFieldSpec(
    key: 'household_size',
    label: 'Household Size (1-25)',
    helperText: 'Whole number 1-25',
    sampleValue: '3',
    isNumeric: true,
    isInteger: true,
    minValue: 1,
    maxValue: 25,
  ),
  InputFieldSpec(
    key: 'sex',
    label: 'Sex',
    helperText: 'Male or Female',
    sampleValue: 'Male',
    allowedValues: ['Male', 'Female'],
  ),
  InputFieldSpec(
    key: 'province',
    label: 'Province',
    helperText: 'Kigali city, Northern/Southern/Eastern/Western Province',
    sampleValue: 'Kigali city',
    allowedValues: [
      'Kigali city',
      'Northern Province',
      'Southern Province',
      'Eastern Province',
      'Western Province',
    ],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'urban_rural',
    label: 'Urban / Rural',
    helperText: 'Urban or Rural',
    sampleValue: 'Urban',
    allowedValues: ['Urban', 'Rural'],
  ),
  InputFieldSpec(
    key: 'internet_use',
    label: 'Internet Use',
    helperText: 'Yes or No',
    sampleValue: 'Yes',
    allowedValues: ['Yes', 'No'],
  ),
  InputFieldSpec(
    key: 'education_track',
    label: 'Education Track',
    helperText: 'No level completed, Completed general, Completed TVET',
    sampleValue: 'Completed TVET',
    allowedValues: ['No level completed', 'Completed general', 'Completed TVET'],
    fullWidth: true,
  ),
  InputFieldSpec(
    key: 'sector',
    label: 'Sector',
    helperText: 'Agriculture, Industry, Services',
    sampleValue: 'Services',
    allowedValues: ['Agriculture', 'Industry', 'Services'],
  ),
  InputFieldSpec(
    key: 'contract_basis',
    label: 'Contract Basis',
    helperText: 'Written contract or Oral agreement',
    sampleValue: 'Written contract',
    allowedValues: ['Written contract', 'Oral agreement'],
  ),
  InputFieldSpec(
    key: 'occupation_group',
    label: 'Occupation Group',
    helperText:
        'e.g. Technicians and associate professionals, Professionals, Service and sales workers, Elementary occupations...',
    sampleValue: 'Technicians and associate professionals',
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
