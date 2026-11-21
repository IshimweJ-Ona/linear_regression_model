import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction_models.dart';


const String kApiBaseUrl = 'https://skillbridge-earnings-api.onrender.com';

class ApiPredictionException implements Exception {
  const ApiPredictionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EarningsApiService {
  EarningsApiService({http.Client? client, this.baseUrl = kApiBaseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<PredictionResult> predict(YouthEarningsRequest request) async {
    final uri = Uri.parse('$baseUrl/predict');
    late final http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const ApiPredictionException(
        'Server timed out waking up on Render. Please try again in a few seconds.',
      );
    } catch (_) {
      throw const ApiPredictionException(
        'Unable to reach the SkillBridge prediction server. Please check your internet connection and try again.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictionResult.fromJson(decoded);
    }

    // Parse structured FastAPI validation/HTTP error JSON.
    try {
      final errJson = jsonDecode(response.body) as Map<String, dynamic>;
      final msg =
          errJson['message'] ?? errJson['detail'] ?? 'Request rejected.';
      throw ApiPredictionException('API Error (${response.statusCode}): $msg');
    } on ApiPredictionException {
      rethrow;
    } catch (_) {
      throw ApiPredictionException(
        'API Error (${response.statusCode}): ${response.reasonPhrase ?? 'Unknown error'}',
      );
    }
  }
}
