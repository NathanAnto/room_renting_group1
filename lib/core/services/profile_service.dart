// lib/core/services/profile_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:room_renting_group1/core/models/user_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('Profile');

  Future<void> createUserProfile({
    required String displayName,
    required Uint8List imageData,
    required String role,
    required String country,
    required String? phone,
    String? school,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilisateur non authentifié.");

    final storageRef = _storage.ref().child('profile_pictures').child('${user.uid}.jpg');
    final uploadTask = await storageRef.putData(imageData);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final newUser = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: imageUrl,
      role: role == 'student' ? UserRole.student : UserRole.homeowner,
      school: school ?? '',
      country: country,
      phone: phone ?? '',
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(user.uid).set(newUser.toJson());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        // The UserModel.fromFirestore factory will handle the data conversion
        return UserModel.fromFirestore(docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }
    return await getUserProfile(currentUser.uid);
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  Future<String> uploadProfilePicture(String userId, Uint8List imageData) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          _storage.ref().child('profile_pictures').child(userId).child(fileName);

      final uploadTask = storageRef.putData(imageData);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _usersCollection.doc(userId).set(
        {'photoUrl': downloadUrl},
        SetOptions(merge: true),
      );

      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      rethrow;
    }
  }
}