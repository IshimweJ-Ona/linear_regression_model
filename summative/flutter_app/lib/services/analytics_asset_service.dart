import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/analytics_models.dart';

class AnalyticsAssetService {
  const AnalyticsAssetService();

  Future<AnalyticsBundle> loadAnalytics() async {
    final raw = await rootBundle.loadString('assets/analytics_data.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AnalyticsBundle.fromJson(decoded);
  }
}
