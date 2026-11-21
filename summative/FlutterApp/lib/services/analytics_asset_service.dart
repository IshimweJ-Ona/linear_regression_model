import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/analytics_models.dart';

class AnalyticsAssetService {
  const AnalyticsAssetService();

  Future<AnalyticsBundle> loadAnalytics() async {
    // Load raw bytes and decode synchronously to avoid Isolate.run (>50 KB)
    // stalls under flutter_test FakeAsync while keeping startup fast.
    final byteData = await rootBundle.load('assets/analytics_data.json');
    final raw = utf8.decode(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AnalyticsBundle.fromJson(decoded);
  }
}
