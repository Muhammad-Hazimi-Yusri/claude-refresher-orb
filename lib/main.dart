import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone for notifications
  tz.initializeTimeZones();
  
  // Initialize services
  final settingsService = SettingsService();
  await settingsService.init();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsService),
        Provider(create: (_) => notificationService),
        Provider(create: (_) => ApiService()),
      ],
      child: const ClaudeUsageAlarmApp(),
    ),
  );
}

class ClaudeUsageAlarmApp extends StatelessWidget {
  const ClaudeUsageAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Claude Usage Alarm',
          debugShowCheckedModeBanner: false,
          
          // Use iOS-style theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFDA7756), // Claude orange
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFDA7756),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          
          themeMode: ThemeMode.system,
          
          home: settings.hasCompletedSetup
              ? const HomeScreen()
              : const SetupScreen(),
        );
      },
    );
  }
}
