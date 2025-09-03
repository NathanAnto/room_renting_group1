// lib/features/booking/widgets/review_form.dart

import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/widgets/star_rating_input.dart';

/// A reusable form for submitting a review, including a star rating and a comment.
///
/// This widget encapsulates the form logic, validation, and submission callback.
class ReviewForm extends StatefulWidget {
  /// The function to call when the form is submitted with valid data.
  final Future<void> Function(double rating, String comment) onSubmit;

  /// A flag to indicate if the form is currently in a loading/submitting state.
  final bool isLoading;

  const ReviewForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _currentRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // First, validate the form.
    if (_formKey.currentState!.validate()) {
      // If the rating is 0, it means the user hasn't selected any stars.
      if (_currentRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une note.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Call the provided onSubmit function with the collected data.
      widget.onSubmit(_currentRating, _commentController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre note :',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // 1. The star rating input widget.
          Center(
            child: StarRatingInput(
              onRatingChanged: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // 2. The comment text field.
          // This would be a shadcn_ui styled TextFormField.
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Votre commentaire',
              hintText: 'Décrivez votre expérience...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez laisser un commentaire.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 3. The submission button.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: widget.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Envoyer l\'avis'),
            ),
          ),
        ],
      ),
    );
  }
}
