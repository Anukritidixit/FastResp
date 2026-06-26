import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _profileFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();

  // Active Session
  Map<String, dynamic>? _session;
  String _userId = '';
  String _role = 'User';

  // Load States
  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _loadingContacts = false;
  String? _errorMessage;

  // Personal/Medical profile controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _specialNotesController = TextEditingController();

  // Volunteer specific controllers
  final _skillsController = TextEditingController();
  final _qualificationController = TextEditingController();

  // Volunteer Read-only fields
  String _category = 'community';
  String _verificationStatus = 'Pending';
  int _savesCount = 0;

  // Blood Group
  String _selectedBloodGroup = 'O+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Emergency Contacts state
  List<Map<String, dynamic>> _contacts = [];
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactRelationController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _tabController = TabController(length: _role == 'User' ? 3 : 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _specialNotesController.dispose();
    _skillsController.dispose();
    _qualificationController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactRelationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadSession() {
    // 1. Get current session
    if (UserSession.current != null) {
      _session = UserSession.current;
    } else {
      // Fallback for direct page debug launches
      _session = {
        "id": "643287b9-d3cf-41cf-8f10-2c6ce554e3b9", // Arjun Mehta (User)
        "role": "User"
      };
    }
    _userId = _session!['id'];
    _role = _session!['role'] ?? 'User';
    
    _fetchProfileData();
    if (_role == 'User') {
      _fetchEmergencyContacts();
    }
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _loadingProfile = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch from public.users
      final user = await _supabase
          .from('users')
          .select('*')
          .eq('id', _userId)
          .single();

      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _selectedBloodGroup = user['blood_group'] ?? 'O+';
      _ageController.text = user['age'] != null ? user['age'].toString() : '';
      _genderController.text = user['gender'] ?? '';
      _addressController.text = user['address'] ?? '';
      _allergiesController.text = user['allergies'] ?? '';
      _conditionsController.text = user['medical_conditions'] ?? '';
      _specialNotesController.text = user['special_notes'] ?? '';

      // 2. Fetch volunteer details if responder
      if (_role == 'Volunteer') {
        final vol = await _supabase
            .from('volunteers')
            .select('*')
            .eq('id', _userId)
            .single();

        _skillsController.text = vol['skills'] ?? '';
        _qualificationController.text = vol['qualification'] ?? '';
        _category = vol['category'] ?? 'community';
        _verificationStatus = vol['is_verified'] ?? 'Pending';
        _savesCount = vol['successful_cases'] ?? 0;
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load profile details: $e";
      });
    } finally {
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  Future<void> _fetchEmergencyContacts() async {
    setState(() {
      _loadingContacts = true;
    });

    try {
      final data = await _supabase
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', _userId)
          .order('name', ascending: true);

      setState(() {
        _contacts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    } finally {
      setState(() {
        _loadingContacts = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _savingProfile = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final ageText = _ageController.text.trim();
      final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;
      final gender = _genderController.text.trim();
      final address = _addressController.text.trim();
      final allergies = _allergiesController.text.trim();
      final conditions = _conditionsController.text.trim();
      final specialNotes = _specialNotesController.text.trim();

      // 1. Update public.users
      final updatedUser = await _supabase.from('users').update({
        'name': name,
        'phone': phone,
        'blood_group': _selectedBloodGroup,
        'age': age,
        'gender': gender,
        'address': address,
        'allergies': allergies,
        'medical_conditions': conditions,
        'special_notes': specialNotes,
      }).eq('id', _userId).select().single();

      // Update current session cache
      UserSession.current = updatedUser;

      // 2. Update volunteers if Volunteer
      if (_role == 'Volunteer') {
        final skills = _skillsController.text.trim();
        final qualification = _qualificationController.text.trim();

        await _supabase.from('volunteers').update({
          'skills': skills,
          'qualification': qualification,
        }).eq('id', _userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Color(0xFF10B981), // Emerald
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to save profile changes: $e";
      });
    } finally {
      setState(() {
        _savingProfile = false;
      });
    }
  }

  Future<void> _addEmergencyContact() async {
    if (!_contactFormKey.currentState!.validate()) {
      return;
    }

    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final contactRelation = _contactRelationController.text.trim();

    try {
      await _supabase.from('emergency_contacts').insert({
        'user_id': _userId,
        'name': contactName,
        'phone': contactPhone,
        'relation': contactRelation,
      });

      _contactNameController.clear();
      _contactPhoneController.clear();
      _contactRelationController.clear();

      if (mounted) {
        Navigator.pop(context); // Close add contact popup
        _fetchEmergencyContacts(); // Reload contacts list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency contact added successfully."),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add contact: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteEmergencyContact(String contactId) async {
    try {
      await _supabase.from('emergency_contacts').delete().eq('id', contactId);
      _fetchEmergencyContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact removed.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete contact: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151518),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_moderator, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Add Contact",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _contactFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildFieldLabel("CONTACT NAME"),
                TextFormField(
                  controller: _contactNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildPopupInputDecoration("e.g. John Doe", Icons.person_outline),
                  validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("PHONE NUMBER"),
                TextFormField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildPopupInputDecoration("e.g. +91 73550 84190", Icons.phone_outlined),
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

                _buildFieldLabel("RELATIONSHIP"),
                TextFormField(
                  controller: _contactRelationController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildPopupInputDecoration("e.g. Mother, Father, Sister", Icons.family_restroom_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? "Relationship is required" : null,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text("CANCEL", style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: _addEmergencyContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text(
              "SAVE CONTACT",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backPath = _role == 'Volunteer' ? '/dashboard/volunteer' : '/dashboard/user';

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go(backPath),
        ),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Stack(
              children: [
                // Background glow orbs
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA855F7).withValues(alpha: 0.06),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tab selectors
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF71717A),
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35), width: 1),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                          tabs: [
                            const Tab(text: "Personal"),
                            if (_role == 'User') const Tab(text: "Medical"),
                            if (_role == 'User') const Tab(text: "Contacts"),
                            if (_role == 'Volunteer') const Tab(text: "Responder Details"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab View Panel
                      Expanded(
                        child: Form(
                          key: _profileFormKey,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: Personal profile Details
                              _buildPersonalTab(),

                              // Tab 2 (Conditional)
                              if (_role == 'User') _buildMedicalTab(),

                              // Tab 3 (Conditional)
                              if (_role == 'User') _buildContactsTab(),

                              // Tab 2 (Volunteer Specific details)
                              if (_role == 'Volunteer') _buildVolunteerTab(),
                            ],
                          ),
                        ),
                      ),

                      // Save Changes floating button at bottom
                      if (_tabController.index != 2 || _role != 'User')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _savingProfile ? null : _saveProfileChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _savingProfile
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
                                        Text("Save Profile Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 8),
                                        Icon(Icons.save_outlined, size: 16),
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
    );
  }

  // Personal Info Form Tab
  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("FULL NAME"),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("Full Name", Icons.person_outline),
              validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
            ),
            const SizedBox(height: 16),

            _buildFieldLabel("PHONE NUMBER"),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("+91 99999 99999", Icons.phone_outlined),
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

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("AGE"),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration("Age", Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("GENDER"),
                      TextFormField(
                        controller: _genderController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration("Gender", Icons.transgender_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFieldLabel("BLOOD GROUP"),
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
                    return DropdownMenuItem(value: bg, child: Text("Blood Group: $bg"));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBloodGroup = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel("PERMANENT ADDRESS"),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("Enter your address", Icons.home_outlined),
            ),
          ],
        ),
      ),
    );
  }

  // Medical Info Tab (User/Victim only)
  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("KNOWN ALLERGIES (E.G. PEANUTS, PENICILLIN)"),
            TextFormField(
              controller: _allergiesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("None or specify details", Icons.warning_amber_outlined),
            ),
            const SizedBox(height: 20),

            _buildFieldLabel("CHRONIC MEDICAL CONDITIONS (E.G. ASTHMA, DIABETES)"),
            TextFormField(
              controller: _conditionsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("None or specify details", Icons.medical_services_outlined),
            ),
            const SizedBox(height: 20),

            _buildFieldLabel("SPECIAL INSTRUCTIONS FOR RESPONDERS"),
            TextFormField(
              controller: _specialNotesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _buildInputDecoration("Notes / medication details", Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }

  // Emergency Contacts Tab (User/Victim only)
  Widget _buildContactsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Contacts",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Trusted people notified on SOS triggers",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.2), width: 1),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                "Add New",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1)),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: _loadingContacts
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : _contacts.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.01),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.people_outline_rounded, color: const Color(0xFF6366F1).withValues(alpha: 0.7), size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No Emergency Contacts Registered",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Family and guardians will not receive automated live alerts unless registered here.",
                              style: TextStyle(color: Color(0xFF52525B), fontSize: 11, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final name = contact['name'] ?? 'No Name';
                        final relation = contact['relation'] ?? 'Contact';
                        final phone = contact['phone'] ?? '';
                        
                        // Pick tag colors based on relationship
                        Color tagBgColor;
                        Color tagTextColor;
                        
                        final relLower = relation.toLowerCase();
                        if (relLower.contains('mother') || relLower.contains('father') || relLower.contains('parent')) {
                          tagBgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
                          tagTextColor = const Color(0xFFFCA5A5);
                        } else if (relLower.contains('spouse') || relLower.contains('wife') || relLower.contains('husband')) {
                          tagBgColor = const Color(0xFFA855F7).withValues(alpha: 0.12);
                          tagTextColor = const Color(0xFFD8B4FE);
                        } else if (relLower.contains('sister') || relLower.contains('brother') || relLower.contains('sibling')) {
                          tagBgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
                          tagTextColor = const Color(0xFF93C5FD);
                        } else {
                          tagBgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                          tagTextColor = const Color(0xFF6EE7B7);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.15)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: tagBgColor,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            relation.toUpperCase(),
                                            style: TextStyle(color: tagTextColor, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                                ),
                                onPressed: () => _deleteEmergencyContact(contact['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // Volunteer Details Info Tab (Volunteer only)
  Widget _buildVolunteerTab() {
    String capCategory = _category[0].toUpperCase() + _category.substring(1);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification & Statistics Section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Verification Status:", style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _verificationStatus == 'Verified'
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _verificationStatus,
                        style: TextStyle(
                          color: _verificationStatus == 'Verified' ? const Color(0xFF10B981) : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Category:", style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                    Text(capCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Successful Rescues:", style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                    Text("$_savesCount saves", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Editable credentials form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("SPECIALIZED RESCUE SKILLS"),
                TextFormField(
                  controller: _skillsController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration("e.g. CPR, Trauma support, Emergency driving", Icons.healing_outlined),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel("QUALIFICATIONS & CERTIFICATES"),
                TextFormField(
                  controller: _qualificationController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration("e.g. Red Cross Certified Lifesaver, Paramedic WB", Icons.workspace_premium_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
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
      fillColor: Colors.black.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }

  InputDecoration _buildPopupInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF52525B)), // zinc600
      prefixIcon: Icon(icon, color: const Color(0xFF71717A)), // zinc500
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
      ),
    );
  }
}
