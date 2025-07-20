import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/Registration/login.dart';
import 'package:flutter_application/common/auth_service.dart';
import 'package:flutter_application/screen/password_reset_screen.dart';

class VerifyEmailOtpPage extends StatefulWidget {
  final String email;
  final bool isPasswordReset;
  final bool otpVerified;

  const VerifyEmailOtpPage({
    super.key,
    required this.email,
    this.isPasswordReset = false,
    this.otpVerified = false,
  });

  @override
  State<VerifyEmailOtpPage> createState() => _VerifyEmailOtpPageState();
}

class _VerifyEmailOtpPageState extends State<VerifyEmailOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final int _resendCooldown = 30; 
  int _remainingCooldown = 0;
  DateTime? _lastResendTime;
  Timer? _cooldownTimer;


  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (index) => TextEditingController());
    _otpFocusNodes = List.generate(6, (index) => FocusNode());
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    if (_lastResendTime == null) {
      setState(() => _remainingCooldown = 0);
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastResendTime!).inSeconds;
    _remainingCooldown = _resendCooldown - diff;

    if (_remainingCooldown <= 0) {
      setState(() => _remainingCooldown = 0);
      return;
    }

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingCooldown <= 1) {
        timer.cancel();
        setState(() => _remainingCooldown = 0);
      } else {
        setState(() => _remainingCooldown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_remainingCooldown > 0) return;

    setState(() {
      _lastResendTime = DateTime.now();
      _remainingCooldown = _resendCooldown;
    });

    try {
      
      final success = widget.isPasswordReset
      
          ? await _authService.sendPasswordResetOtp(
            
              context: context,
              email: widget.email,
            )
          : await _authService.resendOtp(
              context: context,
              email: widget.email,
            );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        _startCooldown();
      }
    }
  }

  Future<void> _verifyOtp() async {
    String otp = '';
    for (var controller in _otpControllers) {
      otp += controller.text;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isPasswordReset) {
        // For password reset, verify OTP and navigate to PasswordResetScreen
        final verified = await _authService.verifyResetOtp(
          context: context,
          otp: otp,
        );

        if (verified && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordResetScreen(email: widget.email),
            ),
          );
        }
      } else {
        // For email verification during signup
        final verified = await _authService.verifyEmailAndSignup(
          context: context,
          email: widget.email,
          token: otp,
        );

        if (verified && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Created Successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().toLowerCase().contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP has expired. Please request a new one.')),
          );
        } else if (e.toString().toLowerCase().contains('invalid')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResendNow = _remainingCooldown <= 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/food.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.7).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/email.png', height: 150),
                      const SizedBox(height: 20),
                      Text(
                        widget.isPasswordReset 
                            ? 'Reset Password' 
                            : 'OTP Verification',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isPasswordReset
                            ? 'Enter the OTP sent to ${widget.email}'
                            : 'Enter the OTP sent to ${widget.email}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 131, 134, 135),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 35,
                            height: 45,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                                } else if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: "Don't receive the OTP? ",
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          children: [
                            TextSpan(
                              text: canResendNow 
                                  ? 'RESEND OTP' 
                                  : 'Resend OTP in $_remainingCooldown seconds',
                              style: TextStyle(
                                color: canResendNow 
                                    ? const Color.fromARGB(255, 246, 141, 141)
                                    : Colors.grey,
                                fontSize: canResendNow ? 18 : 14,
                                fontWeight: canResendNow ? FontWeight.bold : FontWeight.normal,
                              ),
                              recognizer: canResendNow 
                                  ? (TapGestureRecognizer()..onTap = _resendOtp)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 246, 141, 141),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.isPasswordReset 
                                        ? 'Verify OTP' 
                                        : 'Verify Email',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}