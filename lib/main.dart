// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/topic_list_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/revision_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ChangeNotifierProvider(create: (_) => AppProvider(), child: const CMAApp()));
}

const kBlue   = Color(0xFF2563EB);
const kBlueLt = Color(0xFFEFF6FF);
const kGreen  = Color(0xFF16A34A);
const kRed    = Color(0xFFDC2626);
const kAmber  = Color(0xFFD97706);
const kPurple = Color(0xFF7C3AED);
const kBg      = Color(0xFFF8FAFC);
const kSurface = Color(0xFFFFFFFF);
const kBorder  = Color(0xFFE2E8F0);
const kText    = Color(0xFF0F172A);
const kText2   = Color(0xFF475569);
const kText3   = Color(0xFF94A3B8);
const kDarkBg      = Color(0xFF0F172A);
const kDarkSurface = Color(0xFF1E293B);
const kDarkBorder  = Color(0xFF334155);

class CMAApp extends StatelessWidget {
  const CMAApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, p, __) => MaterialApp(
        title: 'CMA Study Tracker',
        debugShowCheckedModeBanner: false,
        theme: _light(),
        darkTheme: _dark(),
        themeMode: p.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const MainScreen(),
      ),
    );
  }

  ThemeData _light() => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: kBlue, onPrimary: Colors.white,
      surface: kSurface, onSurface: kText,
      background: kBg,
    ),
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      elevation: 0, scrolledUnderElevation: 0,
      backgroundColor: kBg, foregroundColor: kText,
      titleTextStyle: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardTheme(
      elevation: 0, color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kBorder)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kSurface, elevation: 0,
      indicatorColor: kBlue.withOpacity(.12),
      labelTextStyle: MaterialStateProperty.resolveWith((s) =>
        TextStyle(fontSize: 11,
          fontWeight: s.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(MaterialState.selected) ? kBlue : kText3)),
      iconTheme: MaterialStateProperty.resolveWith((s) =>
        IconThemeData(color: s.contains(MaterialState.selected) ? kBlue : kText3, size: 22)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: kBlue, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    )),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBlue, width: 1.5)),
      filled: true, fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  ThemeData _dark() => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: kBlue, onPrimary: Colors.white,
      surface: kDarkSurface, onSurface: Colors.white,
      background: kDarkBg,
    ),
    scaffoldBackgroundColor: kDarkBg,
    appBarTheme: const AppBarTheme(
      elevation: 0, scrolledUnderElevation: 0,
      backgroundColor: kDarkBg, foregroundColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardTheme(
      elevation: 0, color: kDarkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: kDarkBorder)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kDarkSurface, elevation: 0,
      indicatorColor: kBlue.withOpacity(.2),
      labelTextStyle: MaterialStateProperty.resolveWith((s) =>
        TextStyle(fontSize: 11,
          fontWeight: s.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(MaterialState.selected) ? kBlue : Colors.white38)),
      iconTheme: MaterialStateProperty.resolveWith((s) =>
        IconThemeData(color: s.contains(MaterialState.selected) ? kBlue : Colors.white38, size: 22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDarkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDarkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBlue, width: 1.5)),
      filled: true, fillColor: kDarkSurface,
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  final _screens = const [
    DashboardScreen(), TopicListScreen(), SchedulerScreen(),
    RevisionScreen(), AnalyticsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (_, p, __) => Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5))),
          child: NavigationBar(
            selectedIndex: _idx,
            onDestinationSelected: (i) => setState(() => _idx = i),
            height: 64,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              const NavigationDestination(icon: Icon(Icons.format_list_bulleted_rounded), selectedIcon: Icon(Icons.format_list_bulleted_rounded), label: 'Topics'),
              const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
              NavigationDestination(
                icon: Badge(isLabelVisible: p.pendingRevisionCount > 0, label: Text('${p.pendingRevisionCount}'), child: const Icon(Icons.replay_rounded)),
                selectedIcon: Badge(isLabelVisible: p.pendingRevisionCount > 0, label: Text('${p.pendingRevisionCount}'), child: const Icon(Icons.replay_rounded)),
                label: 'Revision',
              ),
              const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
            ],
          ),
        ),
      ),
    );
  }
}
