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
    // ClerkAuth wraps MaterialApp so every widget in the tree can access
    // Clerk's auth state via ClerkAuthBuilder / ClerkAuth.of(context).
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: kClerkPublishableKey),
      child: MaterialApp(
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
      ),
    );
  }
}

/// AuthWrapper handles three auth states:
///   1. Clerk session active  → sync with backend → show home
///   2. Legacy JWT stored     → show home directly
///   3. No auth              → show login screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Guard to prevent calling handleClerkSignIn more than once per session.
  bool _clerkHandled = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ClerkAuthBuilder(
      // ── Clerk has an active session ──────────────────────────────
      signedInBuilder: (context, clerkAuthState) {
        if (!_clerkHandled && !authProvider.isAuthenticated) {
          _clerkHandled = true;
          // Capture provider ref before the async gap to satisfy the
          // use_build_context_synchronously lint.
          final ap = context.read<AuthProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final sessionToken = await clerkAuthState.sessionToken();
            // SessionToken is a Clerk type — extract raw JWT string via toString().
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

        // Clerk session exists but sync is still in progress.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },

      // ── No Clerk session ─────────────────────────────────────────
      signedOutBuilder: (context, clerkAuthState) {
        // Reset flag so next Clerk sign-in triggers a fresh sync.
        _clerkHandled = false;

        if (authProvider.isAuthenticated) {
          // User authenticated via legacy JWT — no Clerk session needed.
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
