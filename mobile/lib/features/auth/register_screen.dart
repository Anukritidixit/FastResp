import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Volunteer specific controllers
  final _skillsController = TextEditingController();
  final _govIdController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String _selectedRole = 'User'; // User or Volunteer
  String _selectedVolunteerCategory = 'community'; // community, ambulance, hospital
  
  bool _showPassword = false;
  bool _loading = false;
  String? _errorMessage;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _roles = ['User', 'Volunteer'];
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _skillsController.dispose();
    _govIdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1. Insert user into public.users table
      final userResponse = await supabase.from('users').insert({
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone,
        'password': password,
        'blood_group': _selectedBloodGroup,
        'role': _selectedRole,
        'status': 'Active'
      }).select().single();

      final userId = userResponse['id'] as String;

      // 2. If Volunteer, update the automatically synced volunteer profile with extra fields
      if (_selectedRole == 'Volunteer') {
        final skills = _skillsController.text.trim();
        final govId = _govIdController.text.trim();

        // Briefly wait to ensure the DB trigger has completed execution
        await Future.delayed(const Duration(milliseconds: 500));

        await supabase.from('volunteers').update({
          'category': _selectedVolunteerCategory,
          'skills': skills.isNotEmpty ? skills : 'General Responder',
          'government_id': govId.isNotEmpty ? govId : 'Pending Verification',
        }).eq('id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created successfully for $name! Please Sign In."),
            backgroundColor: const Color(0xFF10B981), // Emerald/Green
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA855F7).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Register Form Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Emblem
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Ω",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Join the ResQLink Emergency Response Network",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA1A1AA), // zinc400
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Glassmorphic Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Full Name
                          _buildLabel("FULL NAME"),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration("Enter your full name", Icons.person_outline),
                            validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                          ),
                          const SizedBox(height: 16),

                          // Email Address
                          _buildLabel("EMAIL ADDRESS"),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration("name@example.com", Icons.mail_outline),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Email is required";
                              final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                              if (!emailRegex.hasMatch(val.trim())) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          _buildLabel("PHONE NUMBER"),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration("+91 XXXXX XXXXX", Icons.phone_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Phone number is required";
                              final digitsOnly = val.replaceAll(RegExp(r'[\s\-()+]'), '');
                              if (!RegExp(r'^\d{10,15}$').hasMatch(digitsOnly)) {
                                return "Enter a valid 10-15 digit phone number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildLabel("PASSWORD"),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration("••••••••", Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF52525B),
                                ),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            validator: (val) => val == null || val.length < 6 ? "Password must be at least 6 characters" : null,
                          ),
                          const SizedBox(height: 16),

                          // Blood Group & Role Row
                          Row(
                            children: [
                              // Blood Group Selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("BLOOD GROUP"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedBloodGroup,
                                          dropdownColor: const Color(0xFF18181B),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                          isExpanded: true,
                                          items: _bloodGroups.map((bg) {
                                            return DropdownMenuItem(value: bg, child: Text(bg));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedBloodGroup = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Role Selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("SIGN UP AS"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedRole,
                                          dropdownColor: const Color(0xFF18181B),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                          isExpanded: true,
                                          items: _roles.map((role) {
                                            return DropdownMenuItem(value: role, child: Text(role == 'User' ? 'Victim / User' : 'Volunteer'));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedRole = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Conditional Volunteer Fields
                          if (_selectedRole == 'Volunteer') ...[
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            const Text(
                              "Volunteer Credentials",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Category
                            _buildLabel("RESPONDER CATEGORY"),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedVolunteerCategory,
                                  dropdownColor: const Color(0xFF18181B),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'community', child: Text('Community Responder')),
                                    DropdownMenuItem(value: 'ambulance', child: Text('Ambulance Personnel')),
                                    DropdownMenuItem(value: 'hospital', child: Text('Hospital Representative')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedVolunteerCategory = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Gov ID
                            _buildLabel("GOVERNMENT ID (E.G. AADHAR, DRIVING LICENSE)"),
                            TextFormField(
                              controller: _govIdController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _buildInputDecoration("Enter Card Type and ID number", Icons.badge_outlined),
                              validator: (val) {
                                if (_selectedRole == 'Volunteer' && (val == null || val.trim().isEmpty)) {
                                  return "Government ID is required for Volunteers";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Skills
                            _buildLabel("SPECIAL SKILLS (E.G. CPR, FIRST AID)"),
                            TextFormField(
                              controller: _skillsController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _buildInputDecoration("First Aid, CPR, Basic Lifesaving", Icons.healing_outlined),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Register Account",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.person_add_alt_1_outlined, size: 16),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Link back to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF71717A), // zinc500
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3F3F46)), // zinc700
      prefixIcon: Icon(icon, color: const Color(0xFF52525B)), // zinc600
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }
}
