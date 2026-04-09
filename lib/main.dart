import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'timeline/controller/timeline_controller.dart';
import 'chat/providers/community_chat_provider.dart';
import 'models/profile_model.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'timeline/screens/timeline_screen.dart';
import 'chat/screens/chat_hub_screen.dart';

import 'departmental_clubs_page.dart';
import 'widgets/bottom_nav.dart';

import 'mafia/controller/game_controller.dart';
import 'mafia/screens/lobby_screen.dart';
import 'mafia/screens/role_screen.dart';
import 'mafia/screens/reveal_screen.dart';
import 'mafia/screens/game_over_screen.dart';
import 'mafia/screens/discussion_screen.dart';
import 'mafia/screens/night_screen.dart';
import 'mafia/screens/voting_screen.dart';
import 'mafia/screens/reporter_broadcast_screen.dart';
import 'mafia/screens/action_report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimelineController()),
        ChangeNotifierProvider(create: (_) => ProfileModel()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CommunityChatProvider()),
        ChangeNotifierProvider(create: (_) => GameController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF5F6FA),
        primaryColor: Colors.blue,
        useMaterial3: true,
      ),
      navigatorKey: mafiaNavKey,
      home: const AppBootstrapScreen(),
      routes: {
        '/home': (context) => const MainNavigationScreen(),
        '/login': (context) => const LoginScreen(),
        // ── Mafia game screens ───────────────────────────────────────────────
        '/mafia/role': (_) => ActionReportListener(
          child: ReporterBroadcastListener(child: const RoleScreen()),
        ),
        '/mafia/reveal': (_) => ActionReportListener(
          child: ReporterBroadcastListener(child: const RevealScreen()),
        ),
        '/mafia/game-over': (_) => const GameOverScreen(),
        // Real game screens wrapped with ReporterBroadcastListener
        '/mafia/night': (_) => ActionReportListener(
          child: ReporterBroadcastListener(child: const NightScreen()),
        ),
        '/mafia/discussion': (_) => ActionReportListener(
          child: ReporterBroadcastListener(child: const DiscussionScreen()),
        ),
        '/mafia/voting': (_) => ActionReportListener(
          child: ReporterBroadcastListener(child: const VotingScreen()),
        ),
        '/mafia/lobby': (_) => const LobbyScreen(), // Dev 2 ✅
      },
    );
  }
}

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});
  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  var _ready = false;
  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    // Splash delay so the logo has time to render
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // ── Update Check ──────────────────────────────────────────────────────────
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nimbus-2k26-backend-olhw.onrender.com/api/config/update',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requiredVersionCode = data['requiredVersionCode'] ?? 7;
        const currentVersionCode = 7; // Increment this when making new releases
        if (currentVersionCode < requiredVersionCode) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Update Required'),
                content: const Text(
                  'A mandatory update is available for Nimbus 2k26. Please update to continue.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final url = data['playStoreUrl'];
                      if (url != null && url.isNotEmpty) {
                        launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: const Text('Update Now'),
                  ),
                ],
              ),
            ),
          );
          return; // Do not proceed to load app
        }
      }
    } catch (_) {
      // Silently proceed if network fails, or could show network error.
    }

    if (!mounted) return;

    // ── Reconnect: check if there is an active game session ──────────────────
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      final gc = context.read<GameController>();
      final userId = authProvider.user?.uid ?? '';
      if (userId.isNotEmpty) {
        final reconnected = await gc.tryReconnect(userId);
        if (reconnected) {
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? const AuthWrapper() : const AppInitScreen();
}

class AppInitScreen extends StatelessWidget {
  const AppInitScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07142E), Color(0xFF0D235A), Color(0xFF153A9B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x14FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Image(
                      image: AssetImage('assets/images/nimbus_logo.webp'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28),
              Text(
                'Nimbus 2k26',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Initializing app...',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 22),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated
        ? const MainNavigationScreen()
        : const LoginScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const TimelineScreen(),
    const DepartmentalClubsPage(),
    const ChatHubScreen(),
  ];
  void _onNavItemTapped(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: BottomNav(currentIndex: _currentIndex, onTap: _onNavItemTapped),
      ),
    );
  }
}
