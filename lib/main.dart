import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'timeline/controller/timeline_controller.dart';
import 'models/profile_model.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'timeline/screens/timeline_screen.dart';
import 'events_page.dart';
import 'departmental_clubs_page.dart';
import 'widgets/bottom_nav.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimelineController()),
        ChangeNotifierProvider(create: (_) => ProfileModel()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MainNavigationScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      // Push real user name into ProfileModel whenever auth state is confirmed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileModel = context.read<ProfileModel>();
        authProvider.syncProfile(profileModel);
      });
      return const MainNavigationScreen();
    }
    return const LoginScreen();
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
    const EventsScreen(),
    const DepartmentalClubsPage(),
  ];

  void _onNavItemTapped(int index) {
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
