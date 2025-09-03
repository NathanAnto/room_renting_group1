// lib/features/review/widgets/review_form.dart

import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/widgets/star_rating_input.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ReviewForm extends StatefulWidget {
  const ReviewForm({
    super.key,
    required this.isLoading,
    // Callback pour notifier le parent de la soumission
    required this.onSubmit,
  });

  final bool isLoading;
  final void Function({
    required double rating,
    required String comment,
  }) onSubmit;

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  // Clé pour identifier et valider notre formulaire
  final _formKey = GlobalKey<ShadFormState>();

  double _currentRating = 0;
  final _commentController = TextEditingController();

  void _submitForm() {
    // On vérifie que le formulaire est valide (commentaire non vide, etc.)
    if (_formKey.currentState!.saveAndValidate()) {
      // On vérifie qu'une note a été sélectionnée
      if (_currentRating == 0) {
        // CORRECTION: Utilisation de la syntaxe correcte pour ShadToast
        // trouvée dans le code source de la librairie.
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Note manquante'),
            description: const Text('Veuillez sélectionner une note de 1 à 5.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // On appelle la fonction parent avec les données
      widget.onSubmit(
        rating: _currentRating,
        comment: _commentController.text,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre note globale',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Le widget de sélection d'étoiles
          StarRatingInput(
            onRatingChanged: (rating) {
              setState(() {
                _currentRating = rating;
              });
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Votre commentaire',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ShadInputFormField(
            id: 'comment',
            controller: _commentController,
            maxLines: 5,
            placeholder: const Text('Décrivez votre expérience...'),
            validator: (value) {
              if (value.trim().isEmpty) {
                return 'Veuillez laisser un commentaire.';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Le bouton de soumission
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: widget.isLoading ? null : _submitForm,
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Envoyer mon avis'),
            ),
          ),
        ],
      ),
    );
  }
}

