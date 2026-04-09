import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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

  await _initializeFirebase();

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

Future<void> _initializeFirebase() async {
  // Check if Firebase is already initialized to prevent duplicate-app errors on hot restart
  if (Firebase.apps.isEmpty) {
    if (!kIsWeb) {
      // Android/iOS native Firebase initialization
      await Firebase.initializeApp();
    } else {
      // Web Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
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

        // Mafia game screens
        '/mafia/role': (_) => ActionReportListener(
              child: ReporterBroadcastListener(child: const RoleScreen()),
            ),
        '/mafia/reveal': (_) => ActionReportListener(
              child: ReporterBroadcastListener(child: const RevealScreen()),
            ),
        '/mafia/game-over': (_) => const GameOverScreen(),
        '/mafia/night': (_) => ActionReportListener(
              child: ReporterBroadcastListener(child: const NightScreen()),
            ),
        '/mafia/discussion': (_) => ActionReportListener(
              child: ReporterBroadcastListener(
                  child: const DiscussionScreen()),
            ),
        '/mafia/voting': (_) => ActionReportListener(
              child: ReporterBroadcastListener(child: const VotingScreen()),
            ),
        '/mafia/lobby': (_) => const LobbyScreen(),
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
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 🔄 Update Check
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
        const currentVersionCode = 7;

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
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    // 🔁 Reconnect logic
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      final gc = context.read<GameController>();
      final userId = authProvider.user?.uid ?? '';

      if (userId.isNotEmpty) {
        final reconnected = await gc.tryReconnect(userId);
        if (reconnected) return;
      }
    }

    if (!mounted) return;

    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? const AuthWrapper() : const AppInitScreen();
  }
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
                      image:
                          AssetImage('assets/images/nimbus_logo.webp'),
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
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
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
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
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
        child: BottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}