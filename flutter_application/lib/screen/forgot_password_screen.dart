import 'package:flutter/material.dart';
import 'package:flutter_application/common/auth_service.dart';
import 'package:flutter_application/screen/password_reset_screen.dart';
import 'package:flutter_application/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await _authService.sendPasswordResetOtp(
        context: context,
        email: _emailController.text.trim(),
      );
      if (success && mounted) {
        setState(() => _otpSent = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final verified = await _authService.verifyResetOtp(
        context: context,
        otp: _otpController.text.trim(),
      );
      
      if (verified && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
         titleTextStyle: (AppTheme.appBarTitleStyle),
        backgroundColor: AppTheme.darkTheme().primaryColor,
      ),
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
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.7).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                     Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                    Text(
                        'Enter your email to receive a verification code',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                 
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'OTP Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_clock),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading 
                              ? null 
                              : _otpSent ? _verifyOtp : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 246, 141, 141),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(_otpSent ? 'Verify OTP' : 'Send Verification Code',style:const TextStyle(color: Colors.white),),
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