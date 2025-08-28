// lib/core/services/profile_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('Profile');

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print("Erreur lors de la récupération du profil utilisateur: $e");
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
      // Utilisation de .set avec merge pour plus de robustesse
      await _usersCollection.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      print("Erreur lors de la mise à jour du profil: $e");
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

      // ✅ AJOUT D'UN PRINT POUR DÉBOGUER
      // Cette ligne nous confirmera dans la console que l'URL est bien récupérée.
      print('Mise à jour de Firestore avec l\'URL : $downloadUrl');

      // ✅ MODIFICATION : Remplacement de .update par .set avec merge
      // C'est une méthode plus sûre qui crée le champ s'il n'existe pas.
      await _usersCollection.doc(userId).set(
        {'photoUrl': downloadUrl},
        SetOptions(merge: true),
      );

      return downloadUrl;
    } catch (e) {
      print("Erreur lors de l'upload de la photo de profil: $e");
      rethrow;
    }
  }
}