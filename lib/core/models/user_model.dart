// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Énumération pour définir les rôles des utilisateurs dans l'application.
/// Un utilisateur peut être un étudiant, un propriétaire ou un administrateur.
enum UserRole {
  student,
  homeowner,
  admin,
}

/// Représente le modèle de données pour un utilisateur de l'application.
///
/// Cette classe est immuable, ce qui est une bonne pratique en Flutter.
/// Pour modifier un utilisateur, on utilise la méthode `copyWith` pour créer une nouvelle instance.
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final UserRole role;
  final String? school;
  final String? country;
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    required this.role,
    this.school,
    this.country,
    this.photoUrl,
    required this.createdAt,
  });

  /// Crée une copie de l'instance `UserModel` en remplaçant les champs fournis.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    UserRole? role,
    String? school,
    String? country,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      school: school ?? this.school,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convertit l'objet `UserModel` en une `Map` pour le stockage dans Firestore.
  /// L'énumération `UserRole` est convertie en `String` et `DateTime` en `Timestamp`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name, // Convertit l'enum en String (ex: 'student')
      'school': school,
      'country': country,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt), // Type de date de Firestore
    };
  }

  /// Crée une instance de `UserModel` à partir d'une `Map` (document) venant de Firestore.
  /// Gère la conversion inverse de `Timestamp` vers `DateTime` et `String` vers `UserRole`.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for UserModel from document: ${doc.id}');
    }
    
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      phone: data['phone'] as String?,
      // Convertit la String stockée en Firestore vers l'enum UserRole.
      // Par défaut, assigne 'student' si le rôle est inconnu ou manquant.
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.student,
      ),
      school: data['school'] as String?,
      country: data['country'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}