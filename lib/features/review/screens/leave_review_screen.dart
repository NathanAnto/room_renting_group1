import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/review_model.dart';
import 'package:room_renting_group1/core/services/auth_service.dart';
import 'package:room_renting_group1/core/services/review_service.dart';
import 'package:room_renting_group1/features/booking/widgets/review_form.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String propertyId;
  final String ownerId;
  // Optionnel: passer le nom du logement pour l'afficher
  final String propertyTitle;

  const LeaveReviewScreen({
    super.key,
    required this.propertyId,
    required this.ownerId,
    required this.propertyTitle,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  // Dans une vraie application, ces services seraient injectés via un Service Locator.
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSubmission(double rating, String comment) async {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : vous devez être connecté pour laisser un avis.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final studentId = currentUser.uid; // On récupère l'ID de l'utilisateur connecté

      final newReview = Review(
        id: '', // Firestore générera l'ID
        propertyId: widget.propertyId,
        studentId: studentId,
        ownerId: widget.ownerId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        reviewerType: ReviewerType.student,
      );

      await _reviewService.postReview(newReview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis envoyé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Revenir à l'écran précédent
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
        title: const Text('Laisser un avis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vous évaluez le logement :",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.propertyTitle,
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
