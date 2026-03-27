import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SignupView();
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView();

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
                title: 'Create an account 🚀',
                subtitle: 'Join your campus event hub today',
              ),

              // ── Tab bar ───────────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -20),
                child: AuthTabBar(
                  activeIndex: 1,
                  onTap: (i) {
                    if (i == 0) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First name / Last name row
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            label: 'First Name',
                            placeholder: 'Ayush',
                            controller: auth.firstNameController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            label: 'Last Name',
                            placeholder: 'Sharma',
                            controller: auth.lastNameController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // College email
                    AuthTextField(
                      label: 'College Email',
                      placeholder: 'ayush@college.edu',
                      controller: auth.signupEmailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Roll number
                    AuthTextField(
                      label: 'Roll Number',
                      placeholder: 'CS21B1234',
                      controller: auth.rollNoController,
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    AuthTextField(
                      label: 'Password',
                      placeholder: 'Create a strong password',
                      controller: auth.signupPassController,
                      obscureText: auth.obscurePassword,
                      onToggleObscure: auth.toggleObscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                      onChanged: auth.onPasswordChanged,
                    ),
                    const SizedBox(height: 8),

                    // Strength bar
                    PasswordStrengthBar(strength: auth.strength),
                    const SizedBox(height: 16),

                    // Terms checkbox
                    AuthCheckboxRow(
                      value: auth.agreedToTerms,
                      onChanged: auth.setAgreedToTerms,
                      label: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

                    // Create account button
                    PrimaryButton(
                      label: 'Create Account',
                      loading: isLoading,
                      onPressed: () async {
                        if (!auth.agreedToTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please agree to the Terms & Conditions'),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        auth.clearError();
                        final ok = await auth.signUp();
                        if (!context.mounted) return;
                        
                        if (ok) {
                          // Navigate to OTP screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtpScreen(
                                email: auth.signupEmailController.text,
                              ),
                            ),
                          );
                        } else {
                          // Show error from backend (e.g. Email already exists)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ??
                                    'Registration failed. Please try again.',
                              ),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    const OrDivider(),
                    const SizedBox(height: 16),

                    // Social row — Google only
                    SocialButton(
                      label: 'Continue with Google',
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final ok = await auth.googleSignIn();
                              if (ok && context.mounted) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                    ),
                    const SizedBox(height: 24),

                    // Log in link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
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
                              TextSpan(text: 'Already have an account?  '),
                              TextSpan(
                                text: 'Log in',
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
}
