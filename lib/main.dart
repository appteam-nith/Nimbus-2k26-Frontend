import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import 'clerk_config.dart';
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
    final app = MaterialApp(
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

    // Only wrap with ClerkAuth when a valid publishable key was injected via
    // --dart-define-from-file=dart_defines.json.
    // Without the flag, clerkEnabled == false and the app uses the legacy
    // JWT flow — no Clerk overlay, no error messages.
    if (clerkEnabled) {
      return ClerkAuth(
        config: ClerkAuthConfig(publishableKey: kClerkPublishableKey),
        child: app,
      );
    }

    return app;
  }
}

/// Routes to the correct screen based on auth state.
///
/// Supports two modes:
///   • Clerk mode (clerkEnabled == true): uses [ClerkAuthBuilder] to detect
///     Clerk sessions and sync them to the backend.
///   • Legacy mode (clerkEnabled == false): reads only from [AuthProvider]
///     (custom JWT flow). Normal login / register still works.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _clerkHandled = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // ── Legacy-only mode (no dart-define key passed) ─────────────────
    if (!clerkEnabled) {
      if (authProvider.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          authProvider.syncProfile(context.read<ProfileModel>());
        });
        return const MainNavigationScreen();
      }
      return const LoginScreen();
    }

    // ── Clerk mode ───────────────────────────────────────────────────
    return ClerkAuthBuilder(
      signedInBuilder: (context, clerkAuthState) {
        if (!_clerkHandled && !authProvider.isAuthenticated) {
          _clerkHandled = true;
          final ap = context.read<AuthProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final sessionToken = await clerkAuthState.sessionToken();
            if (mounted) {
              await ap.handleClerkSignIn(sessionToken.toString());
            }
          });
        }

        if (authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            authProvider.syncProfile(context.read<ProfileModel>());
          });
          return const MainNavigationScreen();
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },

      signedOutBuilder: (context, clerkAuthState) {
        _clerkHandled = false;
        if (authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            authProvider.syncProfile(context.read<ProfileModel>());
          });
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
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
