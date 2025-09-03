// lib/features/review/screens/review_test_page.dart

import 'package:flutter/material.dart';
import 'package:room_renting_group1/features/review/screens/rate_student_screen.dart';
import 'package:room_renting_group1/features/review/screens/rate_listing_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ReviewTestPage extends StatelessWidget {
  const ReviewTestPage({super.key});

  // --- Données de test ---
  // IMPORTANT: Remplacez ces valeurs par de vrais IDs de votre base de données
  static const String testPropertyId = "2f8KPu3AjiUemRr6GJ5J"; // ID d'un logement
  static const String testOwnerId = "8qlsMBOcvkXXzsG93kqK8fDeoKH2"; // ID du propriétaire du logement
  static const String testStudentId = "2PY2rgy6N1XFuPiFvFn5lIdtzdx2"; // ID d'un étudiant à noter
  static const String testStudentName = "Dija Chandrata"; // Mettez un nom de test ici

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page de Test pour les Avis'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- BOUTON 1: L'étudiant note un logement ---
              Text(
                'Scénario 1: Étudiant',
                style: ShadTheme.of(context).textTheme.large,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ShadButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // CORRECTION: Utilisation du nouveau nom de classe
                      builder: (context) => RateListingScreen(
                        propertyId: testPropertyId,
                        ownerId: testOwnerId,
                      ),
                    ),
                  );
                },
                child: const Text('Noter un logement'),
              ),
              const SizedBox(height: 40),

              // --- BOUTON 2: Le propriétaire note un étudiant ---
              Text(
                'Scénario 2: Propriétaire',
                style: ShadTheme.of(context).textTheme.large,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ShadButton(
                onPressed: () {
                  if (testStudentId == "VOTRE_ID_ETUDIANT_ICI") {
                    ShadToaster.of(context).show(
                      const ShadToast.destructive(
                        title: Text('ID de test manquant'),
                        description: Text('Veuillez renseigner un ID d\'étudiant dans le code de la page de test.'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RateStudentScreen(
                        studentId: testStudentId,
                        propertyId: testPropertyId,
                        studentName: testStudentName,
                      ),
                    ),
                  );
                },
                child: const Text('Noter un étudiant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
