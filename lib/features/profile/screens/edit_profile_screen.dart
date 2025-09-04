// lib/features/profile/screens/edit_profile_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import '../../../core/models/user_model.dart';
import '../state/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  String? _selectedSchool;
  final List<String> _schools = [
    'School of Design and Art (EDHEA)',
    'School of Management (HEG)',
    'School of Engineering (HEI)',
    'School of Health Sciences (HES)',
    'School of Social Work (HESTS)',
  ];

  bool get _isStudent => widget.user.role == UserRole.student;

  late final TextEditingController _countryController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Uint8List? _newProfileImageData;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.user.country);
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone);

    if (_isStudent && widget.user.school != null && _schools.contains(widget.user.school)) {
      _selectedSchool = widget.user.school;
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final profileService = ref.read(profileServiceProvider);

      final currentUserState = ref.read(userProfileProvider).value;
      if (currentUserState == null) {
        throw Exception("User not found, cannot save.");
      }

      if (_newProfileImageData != null) {
        await profileService.uploadProfilePicture(widget.user.id, _newProfileImageData!);
      }

      final schoolToSave = _isStudent ? _selectedSchool : null;

      final updatedUser = currentUserState.copyWith(
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
        school: schoolToSave,
        country: _countryController.text.trim(),
      );
      
      await profileService.updateUserProfile(updatedUser);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    final imageData = await pickedFile.readAsBytes();
    setState(() {
      _newProfileImageData = imageData;
    });
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        // MODIFICATION: Set text color for list items.
        textStyle: TextStyle(color: Colors.grey[800]), 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        // MODIFICATION: Constrain the height of the bottom sheet.
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing...',
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        searchTextStyle: TextStyle(
          color: Colors.grey[900],
          fontWeight: FontWeight.w500,
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _countryController.text = country.name;
        });
      },
    );
  }
  
  void _openSchoolPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _schools.length,
                  itemBuilder: (context, index) {
                    final school = _schools[index];
                    return ListTile(
                      title: Text(school, style: TextStyle(color: Colors.grey[800])),
                      onTap: () {
                        setState(() {
                          _selectedSchool = school;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0D47A1);
    final lightGreyBackground = Colors.grey[200];
    
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.grey[800],
        ),
      ),
      child: Scaffold(
        backgroundColor: lightGreyBackground,
        appBar: AppBar(
          title: null,
          backgroundColor: lightGreyBackground,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatar(),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _displayNameController,
                  labelText: 'Display Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => (value == null || value.trim().isEmpty) 
                      ? 'Display name cannot be empty.' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Invalid phone format (e.g., +41791234567)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPickerField(
                  value: _countryController.text,
                  labelText: 'Country',
                  prefixIcon: Icons.flag_outlined,
                  onTap: _openCountryPicker,
                ),
                if (_isStudent) ...[
                  const SizedBox(height: 16),
                  _buildPickerField(
                    value: _selectedSchool,
                    labelText: 'School',
                    prefixIcon: Icons.school_outlined,
                    onTap: _openSchoolPicker,
                    validator: (value) => _selectedSchool == null ? 'Please select a school.' : null,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: primaryBlue,
                  ),
                  child: _isLoading
                      ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: _newProfileImageData != null
                ? MemoryImage(_newProfileImageData!)
                : (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                    ? NetworkImage(widget.user.photoUrl!)
                    : null) as ImageProvider?,
            child: (_newProfileImageData == null && (widget.user.photoUrl == null || widget.user.photoUrl!.isEmpty))
                ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0D47A1),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: Colors.grey[800],
      style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPickerField({
    required String? value,
    required String labelText,
    required IconData prefixIcon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      readOnly: true,
      key: ValueKey(value),
      controller: TextEditingController(text: value),
      style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[500]),
        suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
      ),
      onTap: onTap,
      validator: validator,
    );
  }
}

