import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'pages/skillbridge_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SkillBridgeApp()));
}

/// Root SkillBridge application configured with Riverpod state management
/// and the institutional light theme.
class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillBridge Earnings Predictor',
      debugShowCheckedModeBanner: false,
      theme: buildSkillBridgeTheme(),
      home: const SkillBridgeHomePage(),
    );
  }
}
