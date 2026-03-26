import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final AuthProvider _auth;
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // countdown timer
  int _secondsLeft = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    // Clear OTP controllers for new input
    for (final c in _auth.otpControllers) {
      c.clear();
    }
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
    for (final f in _focusNodes) {
      f.dispose();
    }
    // Don't dispose _auth as it's a shared provider
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

  bool get _otpComplete =>
      _auth.otpControllers.every((c) => c.text.length == 1);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.status == AuthStatus.loading;

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
                    subtitle: 'We sent a 4-digit code to\n${widget.email}',
                  ),

                  // ── Back pill + form ─────────────────────────────
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

                        // Instruction
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
                                controller: auth.otpControllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                onChanged: (v) {
                                  _onOtpInput(v, i);
                                  setState(() {}); // rebuild for button state
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
                                  fillColor:
                                      auth.otpControllers[i].text.isNotEmpty
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
                                      color:
                                          auth.otpControllers[i].text.isNotEmpty
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
                            onTap: _secondsLeft == 0
                                ? () {
                                    _startTimer();
                                    for (final c in auth.otpControllers) {
                                      c.clear();
                                    }
                                    _focusNodes[0].requestFocus();
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
                                  const TextSpan(
                                    text: "Didn't receive code?  ",
                                  ),
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

                        // Verify button
                        PrimaryButton(
                          label: 'Verify & Continue',
                          loading: isLoading,
                          onPressed: _otpComplete
                              ? () async {
                                  final ok = await auth.verifyOtp();
                                  if (ok && context.mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                    );
                                  }
                                }
                              : null,
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
      },
    );
  }
}
