import 'package:app_scan/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DatabaseService.instance.init();
  runApp(const AppScan());
}

class AppScan extends StatefulWidget {
  const AppScan({super.key});

  @override
  State<AppScan> createState() => _AppScanState();
}

class _AppScanState extends State<AppScan>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused) {

      AuthService.logout();

    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
          brightness: Brightness.dark,
          primary: const Color(0xFF00D4AA),
          secondary: const Color(0xFF7B61FF),
          surface: const Color(0xFF0F1923),
          background: const Color(0xFF0A1118),
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1118),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F1923),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2535),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2535),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF00D4AA),
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: const Color(0xFF0A1118),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}