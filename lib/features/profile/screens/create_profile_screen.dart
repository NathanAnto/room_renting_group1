// lib/features/profile/screens/create_profile_screen.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
// Remplacez ces importations par les vôtres si nécessaire
import 'package:room_renting_group1/core/models/user_model.dart';
import 'package:room_renting_group1/core/services/profile_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _profileService = ProfileService();

  Uint8List? _profileImageData;
  bool _isLoading = false;
  String? _globalErrorMessage; // Renommé pour éviter la confusion avec les erreurs de validation
  UserRole _selectedRole = UserRole.student;
  String? _selectedCountry;
  String? _selectedSchool;

  bool _imageError = false; // Pour la validation de l'image de profil
  bool _formSubmitted = false; // Pour savoir si le formulaire a été soumis au moins une fois

  final List<String> hesSchools = [
    'School of Design and Art (EDHEA)',
    'School of Management (HEG)',
    'School of Engineering (HEI)',
    'School of Health Sciences (HES)',
    'School of Social Work (HESTS)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _profileImageData = imageData;
        _imageError = false; // Réinitialise l'erreur si une image est sélectionnée
        if (_formSubmitted) {
          _formKey.currentState?.validate(); // Revalide si le formulaire a déjà été soumis
        }
      });
    }
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: TextStyle(color: Colors.grey[800]),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing...',
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0D47A1)),
          ),
        ),
        searchTextStyle: TextStyle(
          color: Colors.grey[900],
          fontWeight: FontWeight.w500,
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
          if (_formSubmitted) {
            _formKey.currentState?.validate(); // Revalide si le formulaire a déjà été soumis
          }
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
                  itemCount: hesSchools.length,
                  itemBuilder: (context, index) {
                    final school = hesSchools[index];
                    return ListTile(
                      title: Text(school, style: TextStyle(color: Colors.grey[800])),
                      onTap: () {
                        setState(() {
                          _selectedSchool = school;
                          if (_formSubmitted) {
                            _formKey.currentState?.validate(); // Revalide si le formulaire a déjà été soumis
                          }
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

  Future<void> _submitProfile() async {
    setState(() {
      _formSubmitted = true; // Indique que le formulaire a été soumis au moins une fois
      _imageError = _profileImageData == null; // Met à jour l'état de l'erreur d'image
    });

    // Déclenche la validation de tous les champs du formulaire
    final formIsValid = _formKey.currentState!.validate();
    
    // Si le formulaire n'est pas valide ou l'image manque, on arrête
    if (!formIsValid || _imageError) {
      return;
    }

    setState(() { _isLoading = true; _globalErrorMessage = null; });

    try {
      await _profileService.createUserProfile(
        displayName: _nameController.text.trim(),
        imageData: _profileImageData!,
        role: _selectedRole == UserRole.student ? 'student' : 'homeowner',
        country: _selectedCountry!,
        phone: _phoneController.text.trim(),
        school: _selectedRole == UserRole.student ? _selectedSchool : null,
      );
      
      if (!mounted) return;

      // Masque toute bannière existante avant d'en afficher une nouvelle
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      
      // Affiche la bannière de succès (sans bouton OK)
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: const Text(
            'Profile created successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          // Pas d'actions, la bannière disparaîtra automatiquement
          actions: const [
            SizedBox.shrink(), // Nécessaire car 'actions' ne peut pas être vide
          ],
        ),
      );

      // Masquer la bannière après 1 secondes, PUIS naviguer
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          context.go('/');
        }
      });

    } catch (e) {
      if(mounted) {
        setState(() => _globalErrorMessage = "An error occurred: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              // MODIFICATION : Les validations se déclenchent après la première interaction.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(Theme.of(context).textTheme),
                  const SizedBox(height: 32),
                  _buildImagePicker(),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) => (value == null || value.trim().isEmpty) 
                        ? 'Please enter your name.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildPickerField(
                    value: _selectedCountry,
                    labelText: 'Country',
                    prefixIcon: Icons.flag_outlined,
                    onTap: _openCountryPicker,
                    validator: (value) => (_selectedCountry == null) ? 'Please select your country.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number (Optional)',
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
                  const SizedBox(height: 32),
                  _buildRoleSelector(Theme.of(context), primaryBlue),
                  if (_selectedRole == UserRole.student) ...[
                    const SizedBox(height: 16),
                    _buildPickerField(
                      value: _selectedSchool,
                      labelText: 'School',
                      prefixIcon: Icons.account_balance_outlined,
                      onTap: _openSchoolPicker,
                      // Validation pour l'école si l'utilisateur est un étudiant
                      validator: (value) {
                        if (_selectedRole == UserRole.student && _selectedSchool == null) {
                          return 'Please select your school.';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Affiche le message d'erreur global (ex: erreur réseau)
                  if (_globalErrorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _globalErrorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  _buildSubmitButton(primaryBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      children: [
        Text(
          'Complete Your Profile',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A few more details to get you started.',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: _profileImageData != null ? MemoryImage(_profileImageData!) : null,
              child: _profileImageData == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 4),
                        Text('Add Photo', style: TextStyle(color: Colors.grey[700]))
                      ],
                    )
                  : null,
            ),
          ),
        ),
        // Affiche l'erreur d'image si elle est définie
        if (_imageError && _formSubmitted) // N'affiche l'erreur que si le formulaire a été soumis
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select a profile picture.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
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
    final isPlaceholder = value == null;
    final textStyle = TextStyle(
      color: isPlaceholder ? Colors.grey[700] : Colors.grey[900],
      fontWeight: FontWeight.w500,
    );

    return TextFormField(
      key: ValueKey(labelText), 
      readOnly: true,
      controller: TextEditingController(text: isPlaceholder ? labelText : value),
      style: textStyle,
      decoration: InputDecoration(
        labelText: labelText, // Le labelText fonctionne comme un hint/placeholder si aucune valeur
        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[500]),
        suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _buildRoleSelector(ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You are a:', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[800])),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<UserRole>(
            style: SegmentedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              selectedBackgroundColor: primaryColor, 
              
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(value: UserRole.student, label: Text('Student'), icon: Icon(Icons.school_outlined)),
              ButtonSegment(value: UserRole.homeowner, label: Text('Homeowner'), icon: Icon(Icons.home_outlined)),
            ],
            selected: {_selectedRole},
            onSelectionChanged: (Set<UserRole> newSelection) {
              setState(() {
                _selectedRole = newSelection.first;
                if (_formSubmitted && _selectedRole == UserRole.student) {
                   _formKey.currentState?.validate(); // Revalide si le formulaire a déjà été soumis
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: primaryColor,
      ),
      onPressed: _isLoading ? null : _submitProfile,
      child: _isLoading
          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
          : Text(
              'Save and Continue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }
}