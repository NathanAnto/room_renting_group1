// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  homeowner,
  admin,
}

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

  // --- AJOUTS POUR LES NOTES ---
  /// Note moyenne de l'étudiant, calculée à partir des notes des propriétaires.
  final double averageRating;
  /// Nombre total de notes reçues par l'étudiant.
  final int ratingCount;
  // -----------------------------

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
    // Initialisation des nouveaux champs.
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

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
    double? averageRating,
    int? ratingCount,
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
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'school': school,
      'country': country,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      // Écriture des nouveaux champs dans Firestore.
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

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
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.student,
      ),
      school: data['school'] as String?,
      country: data['country'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // Lecture des nouveaux champs depuis Firestore.
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
    );
  }
}
