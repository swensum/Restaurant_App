import 'package:flutter/material.dart';
import 'package:flutter_application/common/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _authService.getCurrentUser();

    _fullNameController.text = user['username'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _bioController.text = user['bio'] ?? '';
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = {
        'username': _fullNameController.text.trim(),
        'email': _emailController.text.trim(), // won't update on Supabase since it's not editable
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      await _authService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    const int avatarCount = 5;

    int avatarIndex = 0;
    if (_fullNameController.text.isNotEmpty) {
      avatarIndex = _fullNameController.text.hashCode.abs() % avatarCount;
    }
    final avatarPath = 'assets/avatar/image${avatarIndex + 1}.jpg';

    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
    20,
    20,
    20,
    20 + MediaQuery.of(context).viewPadding.bottom, // 👈 This line!
  ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with border
              Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: AssetImage(avatarPath),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel('Full Name'),
              _buildInputField(_fullNameController),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              _buildInputField(
                _emailController,
                readOnly: true,
                fillColor: Colors.grey.shade200, // visually indicate it's disabled
              ),
              const SizedBox(height: 16),

              _buildLabel('Phone Number'),
              _buildInputField(
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildLabel('Bio'),
              _buildInputField(_bioController, maxLines: 3),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text('Save',style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: readOnly ? Colors.grey[700] : null,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No visible border
        ),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
