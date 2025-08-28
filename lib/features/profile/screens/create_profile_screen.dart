// lib/features/profile/screens/create_profile_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importez go_router
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
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
  String? _errorMessage;
  UserRole? _selectedRole;
  String? _selectedCountry;
  String? _selectedSchool;

  final List<String> hesSchools = [
    'École de Design et Haute Ecole d\'Art (EDHEA)',
    'Haute Ecole de Gestion (HEG)',
    'Haute Ecole d\'Ingénierie (HEI)',
    'Haute Ecole de Santé (HES)',
    'Haute Ecole et Ecole Supérieure de Travail Social (HESTS)',
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
      });
    }
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
      },
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une photo de profil.')));
      return;
    }
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un pays.')));
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un rôle.')));
      return;
    }
    if (_selectedRole == UserRole.student && _selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner votre école.')));
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await _profileService.createUserProfile(
        displayName: _nameController.text.trim(),
        imageData: _profileImageData!,
        role: _selectedRole == UserRole.student ? 'student' : 'homeowner',
        country: _selectedCountry!,
        phone: _phoneController.text.trim(),
        school: _selectedRole == UserRole.student ? _selectedSchool : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // CORRECTION : Utilisation de la commande go_router
        context.go('/');
      }
    } catch (e) {
      setState(() { _errorMessage = "Une erreur est survenue: ${e.toString()}"; });
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser votre profil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: _profileImageData != null ? MemoryImage(_profileImageData!) : null,
                      child: _profileImageData == null
                          ? const Icon(Icons.camera_alt, size: 50, color: Colors.white70)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom complet',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre nom.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: _selectedCountry ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    hintText: 'Sélectionnez votre pays',
                    border: OutlineInputBorder(),
                  ),
                  onTap: _openCountryPicker,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone (optionnel)',
                    hintText: '+41 79 123 45 67',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final phoneRegex = RegExp(r'^\+41\s\d{2}\s\d{3}\s\d{2}\s\d{2}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Format invalide (+41 XX XXX XX XX)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Vous êtes :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                RadioListTile<UserRole>(
                  title: const Text('Étudiant'),
                  value: UserRole.student,
                  groupValue: _selectedRole,
                  onChanged: (UserRole? value) { setState(() { _selectedRole = value; }); },
                ),
                RadioListTile<UserRole>(
                  title: const Text('Propriétaire'),
                  value: UserRole.homeowner,
                  groupValue: _selectedRole,
                  onChanged: (UserRole? value) { setState(() { _selectedRole = value; }); },
                ),
                if (_selectedRole == UserRole.student)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSchool,
                      hint: const Text('Sélectionnez votre HES'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: hesSchools.map((String school) {
                        return DropdownMenuItem<String>(value: school, child: Text(school));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { _selectedSchool = newValue; });
                      },
                      validator: (value) {
                        if (_selectedRole == UserRole.student && value == null) {
                          return 'Veuillez sélectionner une école.';
                        }
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _submitProfile,
                      child: const Text('Sauvegarder et continuer'),
                    ),
                  ),
                if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}