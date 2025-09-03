import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/review_model.dart';
import 'package:room_renting_group1/core/services/auth_service.dart';
import 'package:room_renting_group1/core/services/review_service.dart';
import 'package:room_renting_group1/features/review/widgets/review_form.dart';

class RateStudentScreen extends StatefulWidget {
  final String studentId;
  final String propertyId;
  // Optionnel: passer le nom de l'étudiant pour l'afficher
  final String studentName;

  const RateStudentScreen({
    super.key,
    required this.studentId,
    required this.propertyId,
    required this.studentName,
  });

  @override
  State<RateStudentScreen> createState() => _RateStudentScreenState();
}

class _RateStudentScreenState extends State<RateStudentScreen> {
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSubmission(double rating, String comment) async {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : vous devez être connecté pour évaluer un étudiant.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerId = currentUser.uid; // On récupère l'ID de l'utilisateur connecté

      final newRating = Review(
        id: '', // Firestore générera l'ID
        propertyId: widget.propertyId,
        studentId: widget.studentId,
        ownerId: ownerId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        reviewerType: ReviewerType.owner,
      );

      await _reviewService.postReview(newRating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci d\'avoir évalué votre locataire ! Votre évaluation a bien été enregistrée.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Évaluer l\'étudiant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vous évaluez l'étudiant :",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.studentName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ReviewForm(
              onSubmit: _handleSubmission,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
