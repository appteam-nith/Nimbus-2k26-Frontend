import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../app_colors.dart';
import '../widgets/auth_widgets.dart';

/// Single unified auth screen — shown when no Clerk session is active.
///
/// ClerkAuthentication handles:
///   • Email + password sign-in / sign-up
///   • Google OAuth
///   • OTP verification (if enabled in Clerk dashboard)
///
/// After sign-in, ClerkAuthBuilder in AuthWrapper detects the new session
/// and calls handleClerkSignIn → navigates to home automatically.
///
/// [initialMode] is unused by ClerkAuthentication directly but kept so
/// that the old LoginScreen / SignupScreen routes still compile.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthView();
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Nimbus branding hero ──────────────────────────────────
            const AuthHero(
              title: 'Welcome to Nimbus 👋',
              subtitle: 'Sign in or create an account to continue',
            ),

            const SizedBox(height: 16),

            // ── Clerk pre-built auth UI ───────────────────────────────
            // Handles email/password AND Google in one widget.
            // After success, AuthWrapper detects the Clerk session and
            // navigates home — no manual navigation needed here.
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: ClerkAuthentication(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
