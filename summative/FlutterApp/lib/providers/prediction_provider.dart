import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prediction_models.dart';
import '../services/earnings_api_service.dart';

const _kDraftStorageKey = 'skillbridge_last_inputs_v1';
const _kHistoryStorageKey = 'skillbridge_recent_estimates_v1';
const _kMaxSavedEstimates = 5;

final earningsApiServiceProvider = Provider<EarningsApiService>((ref) {
  return EarningsApiService();
});

class PredictionState {
  const PredictionState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
    this.savedDraft = const {},
    this.submittedInputs = const {},
    this.recentEstimates = const [],
  });

  final bool isLoading;
  final PredictionResult? result;
  final String? errorMessage;
  final Map<String, String> savedDraft;
  final Map<String, String> submittedInputs;
  final List<SavedEstimate> recentEstimates;

  PredictionState copyWith({
    bool? isLoading,
    PredictionResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    Map<String, String>? savedDraft,
    Map<String, String>? submittedInputs,
    List<SavedEstimate>? recentEstimates,
  }) {
    return PredictionState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedDraft: savedDraft ?? this.savedDraft,
      submittedInputs: submittedInputs ?? this.submittedInputs,
      recentEstimates: recentEstimates ?? this.recentEstimates,
    );
  }
}

class PredictionNotifier extends Notifier<PredictionState> {
  @override
  PredictionState build() {
    Future.microtask(_loadFromPrefs);
    return const PredictionState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftRaw = prefs.getString(_kDraftStorageKey);
      final historyRaw = prefs.getString(_kHistoryStorageKey);

      final draft = draftRaw != null
          ? (jsonDecode(draftRaw) as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            )
          : <String, String>{};

      final history = historyRaw != null
          ? (jsonDecode(historyRaw) as List)
                .map((e) => SavedEstimate.fromJson(e as Map<String, dynamic>))
                .toList()
          : <SavedEstimate>[];

      state = state.copyWith(savedDraft: draft, recentEstimates: history);
    } catch (_) {
      // Ignore storage initialization failures in headless test environments.
    }
  }

  Future<void> _saveDraft(Map<String, String> inputs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDraftStorageKey, jsonEncode(inputs));
    } catch (_) {}
  }

  Future<void> _saveHistory(List<SavedEstimate> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kHistoryStorageKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> predict(Map<String, String> rawInputs) async {
    if (state.isLoading) return;
    await _saveDraft(rawInputs);

    final validated = YouthEarningsRequest.validateAndBuild(rawInputs);
    if (validated.error != null || validated.request == null) {
      state = state.copyWith(
        isLoading: false,
        clearResult: true,
        errorMessage: validated.error,
        savedDraft: rawInputs,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      savedDraft: rawInputs,
    );

    try {
      final res = await ref
          .read(earningsApiServiceProvider)
          .predict(validated.request!);
      final summary =
          '${rawInputs['age']}y ${rawInputs['sex']} • ${rawInputs['province']} • ${rawInputs['education_track']}';
      final newEntry = SavedEstimate(
        summary: summary,
        incomeKRwf: res.predictedMonthlyIncomeKRwf,
        incomeRwf: res.predictedMonthlyIncomeRwf,
      );
      final updatedHistory = [
        newEntry,
        ...state.recentEstimates,
      ].take(_kMaxSavedEstimates).toList();
      await _saveHistory(updatedHistory);

      state = state.copyWith(
        isLoading: false,
        result: res,
        clearError: true,
        submittedInputs: Map<String, String>.from(rawInputs),
        recentEstimates: updatedHistory,
      );
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        clearResult: true,
        errorMessage: err.toString(),
      );
    }
  }

  void clearOutput() {
    state = state.copyWith(clearResult: true, clearError: true);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(recentEstimates: const []);
    await _saveHistory(const []);
  }
}

final predictionProvider =
    NotifierProvider<PredictionNotifier, PredictionState>(
      PredictionNotifier.new,
    );
