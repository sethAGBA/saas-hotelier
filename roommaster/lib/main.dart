// main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/local_database.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await LocalDatabase.instance.init();
  await LocalDatabase.instance.ensureDefaultAdmin();

  final initialScreen = await AuthService.instance.isLoggedIn()
      ? const MainScreen()
      : const LoginScreen();

  runApp(HotelFlowApp(initialScreen: initialScreen));
}

class HotelFlowApp extends StatelessWidget {
  const HotelFlowApp({Key? key, Widget? initialScreen})
    : initialScreen = initialScreen ?? const MainScreen(),
      super(key: key);

  final Widget initialScreen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotelFlow - Gestion Hôtelière',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
            ).copyWith(
              surface: const Color(0xFF1A1A2E),
              background: const Color(0xFF0F0F1E),
            ),
        fontFamily: 'SF Pro Display',
      ),
      themeMode: ThemeMode.dark,
      home: initialScreen,
    );
  }
}
