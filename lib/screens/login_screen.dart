import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              subtitle: 'Sign in with your @nith.ac.in email',
            ),

            const SizedBox(height: 48),

            // ── Google Sign In Button ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      children: [
                        if (auth.status == AuthStatus.loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: CircularProgressIndicator(),
                          ),
                        SocialButton(
                          label: 'Continue with Google',
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 32),
                          ),
                          onPressed: auth.status == AuthStatus.loading
                              ? null
                              : () async {
                                  // Navigating to home is handled entirely
                                  // by the AuthWrapper in main.dart when
                                  // isAuthenticated flips to true.
                                  await auth.signInWithGoogle();
                                },
                        ),
                        if (auth.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                auth.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
