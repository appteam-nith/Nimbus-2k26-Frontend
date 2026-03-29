import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'signup_screen.dart';
import 'clerk_sign_in_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginView();
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero ──────────────────────────────────────────────
              const AuthHero(
                title: 'Welcome back! 👋',
                subtitle: 'Sign in to your campus event hub',
              ),

              // ── Tab bar (overlaps hero by 20 px) ──────────────────
              Transform.translate(
                offset: const Offset(0, -20),
                child: AuthTabBar(
                  activeIndex: 0,
                  onTap: (i) {
                    if (i == 1) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SignupScreen(),
                          transitionDuration: const Duration(milliseconds: 250),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    }
                  },
                ),
              ),

              // ── Form ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    AuthTextField(
                      label: 'Email / College ID',
                      placeholder: 'ayush@nimbus.edu',
                      controller: auth.emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    AuthTextField(
                      label: 'Password',
                      placeholder: '••••••••',
                      controller: auth.passwordController,
                      obscureText: auth.obscurePassword,
                      onToggleObscure: auth.toggleObscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                      trailingWidget: GestureDetector(
                        onTap: () {
                          // TODO: navigate to forgot password
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Remember me
                    AuthCheckboxRow(
                      value: auth.rememberMe,
                      onChanged: auth.setRememberMe,
                      label: const Text(
                        'Remember me for 30 days',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error message
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Login button
                    PrimaryButton(
                      label: 'Log In',
                      loading: isLoading,
                      onPressed: () async {
                        final ok = await auth.login();
                        if (ok && context.mounted) {
                          // TODO: navigate to home
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    const OrDivider(),
                    const SizedBox(height: 16),

                    // Social row — Google (powered by Clerk)
                    SocialButton(
                      label: 'Continue with Google',
                      icon: _googleIcon(),
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClerkSignInScreen(),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 24),

                    // Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const SignupScreen(),
                            transitionDuration: const Duration(
                              milliseconds: 250,
                            ),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                          ),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.subtle,
                            ),
                            children: [
                              TextSpan(text: "Don't have an account?  "),
                              TextSpan(
                                text: 'Sign up free',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() => const Text(
    'G',
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Color(0xFF4285F4),
    ),
  );
}
