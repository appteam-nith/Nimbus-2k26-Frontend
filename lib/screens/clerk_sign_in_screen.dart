import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';

/// Full-screen page that renders Clerk's pre-built authentication UI.
///
/// Used when the user taps "Continue with Google" from the custom login/signup
/// screens. Clerk handles the entire Google OAuth flow inside this screen.
///
/// Navigation strategy:
///   - Watches [AuthProvider]. When [AuthProvider.isAuthenticated] becomes true
///     (set by [AuthProvider.handleClerkSignIn] in [AuthWrapper]), this screen
///     removes itself and all routes below, then pushes '/home'.
class ClerkSignInScreen extends StatelessWidget {
  const ClerkSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Auth established (by AuthWrapper's ClerkAuthBuilder) — navigate home.
    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (_) => false);
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.dark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Continue with Google',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: ClerkAuthentication(),
      ),
    );
  }
}
