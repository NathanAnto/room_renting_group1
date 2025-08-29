import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String? id;
  final String? displayName;
  final String? email;
  final String? role;
  final String? school;
  final String? country;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;

  const UserProfile({
    this.id,
    this.displayName,
    this.email,
    this.role,
    this.school,
    this.country,
    this.phone,
    this.photoUrl,
    this.createdAt,
  });

  factory UserProfile.fromMap(String docId, Map<String, dynamic> data) {
    return UserProfile(
      id: (data['id'] as String?) ?? docId,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      role: data['role'] as String?,
      school: data['school'] as String?,
      country: data['country'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
