import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_models.dart';

/// Replace this URL with your deployed Render web service base URL (no trailing slash).
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
    } catch (e) {
      throw ApiPredictionException('Network error contacting API: $e');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictionResult.fromJson(decoded);
    }

    // Parse structured FastAPI validation/HTTP error JSON.
    try {
      final errJson = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = errJson['message'] ?? errJson['detail'] ?? 'Request rejected.';
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
