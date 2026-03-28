import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/profile_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// OTP screen shown after signup registration.
/// On verify, calls loginAfterOtp() to get the JWT token, then navigates home.
/// NOTE: The backend does not yet email a real OTP — this screen serves as a
/// confirmation step. The user can tap Verify to proceed.
class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  // countdown timer
  int _secondsLeft = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpInput(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  bool get _otpComplete => _otpControllers.every((c) => c.text.length == 1);

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final profileModel = context.read<ProfileModel>();

    final otpStr = _otpControllers.map((c) => c.text).join();

    // Verify OTP and Login using signup credentials
    final ok = await auth.loginAfterOtp(otpStr);

    if (!mounted) return;

    if (ok) {
      // Sync real user name from auth into the profile model
      auth.syncProfile(profileModel);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ?? 'Verification failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero ────────────────────────────────────────
              AuthHero(
                title: 'Verify your email 📬',
                subtitle: 'Account created! Tap Verify to continue.\n${widget.email}',
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Center(
                      child: Text(
                        'Enter the 4-digit code below',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 68,
                          height: 72,
                          margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                          child: TextField(
                            controller: _otpControllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            onChanged: (v) {
                              _onOtpInput(v, i);
                              setState(() {});
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: AppColors.dark,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _otpControllers[i].text.isNotEmpty
                                  ? Colors.white
                                  : AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _otpControllers[i].text.isNotEmpty
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Resend
                    Center(
                      child: GestureDetector(
                        onTap: _secondsLeft == 0 && !_isLoading
                            ? () async {
                                final auth = context.read<AuthProvider>();
                                final success = await auth.resendOtp();
                                if (success) {
                                  _startTimer();
                                  for (final c in _otpControllers) c.clear();
                                  _focusNodes[0].requestFocus();
                                } else {
                                  setState(() {
                                    _errorMessage = auth.errorMessage ?? 'Failed to resend code';
                                  });
                                }
                              }
                            : null,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.subtle,
                            ),
                            children: [
                              const TextSpan(text: "Didn't receive code?  "),
                              TextSpan(
                                text: _secondsLeft > 0
                                    ? 'Resend (0:${_secondsLeft.toString().padLeft(2, '0')})'
                                    : 'Resend',
                                style: TextStyle(
                                  color: _secondsLeft > 0
                                      ? AppColors.subtle
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error
                    if (_errorMessage != null) ...[
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
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Verify button
                    PrimaryButton(
                      label: 'Verify & Continue',
                      loading: _isLoading,
                      onPressed: _otpComplete ? _verify : null,
                    ),
                    const SizedBox(height: 20),

                    // Change email link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.subtle,
                            ),
                            children: [
                              TextSpan(text: 'Wrong email?  '),
                              TextSpan(
                                text: 'Change it',
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
