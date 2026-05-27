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

class AppScan extends StatelessWidget {
  const AppScan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF51424),       // Flame Red
          brightness: Brightness.dark,
          primary: const Color(0xFFF51424),         // Flame Red → main accent
          secondary: const Color(0xFFF8C700),       // Bright Gold → secondary accent
          surface: const Color(0xFF0D0000),         // Near-black with red undertone
          background: const Color(0xFF000000),      // Deep Black
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),   // Deep Black
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0D0000),         // Deep surface
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A0005),                   // Dark red-tinted card
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF9B0D17).withOpacity(0.4)), // Dark Red border
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A0005),               // Dark red-tinted fill
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF9B0D17).withOpacity(0.4)), // Dark Red
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF9B0D17).withOpacity(0.4)), // Dark Red
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF51424), width: 2), // Flame Red
          ),
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF51424),       // Flame Red
            foregroundColor: const Color(0xFF000000),       // Deep Black text on button
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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