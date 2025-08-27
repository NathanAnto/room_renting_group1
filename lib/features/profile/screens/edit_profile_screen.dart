// lib/features/profile/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/user_model.dart';
import '../state/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _schoolController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialise les contrôleurs avec les données de l'utilisateur actuel
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _schoolController = TextEditingController(text: widget.user.school);
  }

  @override
  void dispose() {
    // Libère la mémoire des contrôleurs
    _displayNameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Valide le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Récupère le service via Riverpod
      final profileService = ref.read(profileServiceProvider);

      // Crée une nouvelle instance de UserModel avec les données mises à jour
      final updatedUser = widget.user.copyWith(
        displayName: _displayNameController.text,
        phone: _phoneController.text,
        school: _schoolController.text,
      );

      // Appelle la méthode de mise à jour du service
      await profileService.updateUserProfile(updatedUser);

      // Rafraîchit les données du profil dans l'application
      ref.invalidate(userProfileProvider);

      if (mounted) {
        // Affiche un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
        // Retourne à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Affiche un message d'erreur
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Champ pour le nom d'affichage
              const Text("Nom d'affichage", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ShadInput(
                controller: _displayNameController,
                placeholder: const Text('Entrez votre nom complet'),
              ),
              const SizedBox(height: 16),

              // Champ pour le téléphone
              const Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ShadInput(
                controller: _phoneController,
                placeholder: const Text('Entrez votre numéro de téléphone'),
              ),
              const SizedBox(height: 16),

              // Champ pour l'école/université
              const Text('École / Université', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ShadInput(
                controller: _schoolController,
                placeholder: const Text('Entrez le nom de votre établissement'),
              ),
              const SizedBox(height: 32),

              // Bouton de sauvegarde
              ShadButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}