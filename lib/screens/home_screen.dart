import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'generate_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _totalScans = 0;
  int _uniqueQRs = 0;

  final List<Widget> _screens = const [
    ScanScreen(),
    HistoryScreen(),
    GenerateScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final total = await DatabaseService.instance.getTotalScans();
    final unique = await DatabaseService.instance.getUniqueQRCount();
    if (mounted) {
      setState(() {
        _totalScans = total;
        _uniqueQRs = unique;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/app_logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text('App Scan',
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
        actions: [
          // Stats chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF00D4AA).withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, color: Color(0xFF00D4AA), size: 14),
                const SizedBox(width: 4),
                Text('$_uniqueQRs',
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00D4AA),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1923),
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00D4AA).withOpacity(0.15),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            _loadStats();
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.qr_code_scanner_outlined,
                  color: Colors.white54),
              selectedIcon: const Icon(Icons.qr_code_scanner_rounded,
                  color: Color(0xFF00D4AA)),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined, color: Colors.white54),
              selectedIcon:
                  const Icon(Icons.history_rounded, color: Color(0xFF00D4AA)),
              label: 'History',
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_box_outlined, color: Colors.white54),
              selectedIcon:
                  const Icon(Icons.add_box_rounded, color: Color(0xFF00D4AA)),
              label: 'Generate',
            ),
          ],
        ),
      ),
    );
  }
}
