import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1: Enter Email, 2: Verify OTP, 3: New Password
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  
  String? _generatedOtp;
  String? _userId; // To store which user is resetting

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = "Please enter your email.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('users')
          .select('id, name')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (response == null) {
        throw Exception("No account found with this email address.");
      }

      _userId = response['id'].toString();
      
      // Generate a mock 6-digit OTP
      _generatedOtp = (Random().nextInt(900000) + 100000).toString();

      setState(() {
        _step = 2;
      });

      if (mounted) {
        // MOCK EMAIL SENDING: We just show it in a snackbar so you can test it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Mock Email Sent! Your OTP is: $_generatedOtp"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = "Please enter the OTP.");
      return;
    }

    if (otp != _generatedOtp) {
      setState(() => _errorMessage = "Invalid OTP. Please try again.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _step = 3;
    });
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      setState(() => _errorMessage = "Password must be at least 6 characters.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('users')
          .update({'password': password})
          .eq('id', _userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset successful! You can now log in."),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to reset password: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset, size: 64, color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? "Enter your email to receive a reset code."
                    : _step == 2
                        ? "Enter the 6-digit code we sent you."
                        : "Create a new strong password.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFA1A1AA)),
              ),
              const SizedBox(height: 36),

              // Glassmorphic Input Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_step == 1) ...[
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("Email Address", Icons.mail_outline),
                      ),
                      const SizedBox(height: 24),
                      _buildButton("Send Code", _handleSendOtp),
                    ],

                    if (_step == 2) ...[
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        decoration: _inputDeco("OTP Code", Icons.numbers).copyWith(counterText: ""),
                      ),
                      const SizedBox(height: 24),
                      _buildButton("Verify Code", _handleVerifyOtp),
                    ],

                    if (_step == 3) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("New Password", Icons.lock_outline),
                      ),
                      const SizedBox(height: 24),
                      _buildButton("Save Password", _handleResetPassword),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3F3F46)),
      prefixIcon: Icon(icon, color: const Color(0xFF52525B)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
