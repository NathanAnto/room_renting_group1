import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
    'École de Design et Haute Ecole d\'Art (EDHEA)',
    'Haute Ecole de Gestion (HEG)',
    'Haute Ecole d\'Ingénierie (HEI)',
    'Haute Ecole de Santé (HES)',
    'Haute Ecole et Ecole Supérieure de Travail Social (HESTS)',
  ];

  late final TextEditingController _countryController;
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _countryController = TextEditingController(text: widget.user.country);
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone);

    if (widget.user.school != null && _schools.contains(widget.user.school)) {
      _selectedSchool = widget.user.school;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
        throw Exception("Utilisateur non trouvé, impossible de sauvegarder.");
      }

      // On applique les modifications sur cette version fraîche des données
      final updatedUser = currentUserState.copyWith(
        displayName: _displayNameController.text,
        phone: _phoneController.text,
        school: _selectedSchool,
        email: _emailController.text,
        country: _countryController.text,
      );
      
      await profileService.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

   Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final imageData = await pickedFile.readAsBytes();
      
      final profileService = ref.read(profileServiceProvider);
      await profileService.uploadProfilePicture(widget.user.id, imageData);
      
      // ✅ SOLUTION : Invalidez le provider ici !
      // Cela force Riverpod à recharger les données du profil depuis Firestore.
      // La prochaine lecture de `userProfileProvider` aura la nouvelle `photoUrl`.
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour !')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'upload : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        backgroundColor: ShadTheme.of(context).colorScheme.background,
        textStyle: TextStyle(color: ShadTheme.of(context).colorScheme.foreground),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Rechercher',
          hintText: 'Commencez à taper...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8D99AE).withOpacity(0.2),
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _countryController.text = country.name;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadImage,
                  child: userAsyncValue.when(
                    data: (user) => CircleAvatar(
                      radius: 64,
                      backgroundColor: ShadTheme.of(context).colorScheme.muted,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                    loading: () => const CircleAvatar(radius: 64, child: CircularProgressIndicator()),
                    error: (e, s) => const CircleAvatar(radius: 64, child: Icon(Icons.error)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text("Nom d'affichage", style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 8),
              FormField<String>(
                validator: (value) {
                  if (_displayNameController.text.isEmpty) {
                    return 'Le nom ne peut pas être vide';
                  }
                  return null;
                },
                builder: (FormFieldState<String> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadInput(controller: _displayNameController),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(field.errorText!, style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              
              Text("Adresse e-mail", style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 8),
              FormField<String>(
                validator: (value) {
                  final email = _emailController.text;
                  if (email.isEmpty) return 'L\'adresse e-mail ne peut pas être vide';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(email)) return 'Format d\'e-mail invalide';
                  return null;
                },
                builder: (FormFieldState<String> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadInput(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(field.errorText!, style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Text('Numéro de téléphone', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 8),
              FormField<String>(
                validator: (value) {
                  final phone = _phoneController.text;
                  if (phone.isNotEmpty) {
                    final phoneRegex = RegExp(r'^\+41\s\d{2}\s\d{3}\s\d{2}\s\d{2}$');
                    if (!phoneRegex.hasMatch(phone)) return 'Format invalide (+41 XX XXX XX XX)';
                  }
                  return null;
                },
                builder: (FormFieldState<String> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadInput(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        placeholder: const Text('+41 79 123 45 67'),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(field.errorText!, style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Text('École / Université', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 8),
              ShadSelect<String>(
                initialValue: _selectedSchool,
                placeholder: const Text('Sélectionnez une école'),
                options: _schools.map((school) => ShadOption(value: school, child: Text(school))).toList(),
                selectedOptionBuilder: (context, value) => Text(value),
                onChanged: (value) {
                  setState(() {
                    _selectedSchool = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              Text("Pays", style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openCountryPicker,
                child: AbsorbPointer(
                  child: ShadInput(
                    controller: _countryController,
                    placeholder: const Text('Sélectionnez un pays'),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ShadButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}