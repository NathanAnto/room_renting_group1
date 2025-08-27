// lib/core/services/profile_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// Service pour gérer toutes les opérations CRUD (Create, Read, Update, Delete)
/// relatives aux profils utilisateurs sur Firebase.
/// Il gère à la fois les données sur Firestore et le stockage des images sur Firebase Storage.
class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Référence à la collection 'users' dans Firestore pour éviter les erreurs de frappe.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Récupère le profil d'un utilisateur spécifique à partir de son ID.
  ///
  /// Retourne un [UserModel] si l'utilisateur est trouvé, sinon `null`.
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        // Utilise le factory constructor 'fromFirestore' pour créer l'objet UserModel
        return UserModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print("Erreur lors de la récupération du profil utilisateur: $e");
    }
    return null;
  }

  /// Méthode pratique pour obtenir le profil de l'utilisateur actuellement connecté.
  Future<UserModel?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Si aucun utilisateur n'est connecté, il n'y a pas de profil à chercher.
      return null;
    }
    return await getUserProfile(currentUser.uid);
  }

  /// Met à jour les données du profil d'un utilisateur dans Firestore.
  ///
  /// Prend un objet [UserModel] complet en paramètre et met à jour le document
  /// correspondant avec les nouvelles données.
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      print("Erreur lors de la mise à jour du profil: $e");
      // Relance l'erreur pour que l'UI puisse la gérer (ex: afficher un message)
      rethrow;
    }
  }

  /// Téléverse une image de profil sur Firebase Storage et met à jour l'URL dans Firestore.
  ///
  /// [userId] L'ID de l'utilisateur pour qui l'image est téléversée.
  /// [imageFile] Le fichier image (`File`) sélectionné par l'utilisateur.
  ///
  /// Retourne l'[String] de l'URL de téléchargement de l'image.
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // 1. Créer une référence unique dans Firebase Storage
      // Le chemin est 'profile_pictures/[userId]/[nom_de_fichier.jpg]'
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          _storage.ref().child('profile_pictures').child(userId).child(fileName);

      // 2. Téléverser le fichier
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // 3. Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Mettre à jour le champ 'photoUrl' dans le document de l'utilisateur sur Firestore
      await _usersCollection.doc(userId).update({'photoUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print("Erreur lors de l'upload de la photo de profil: $e");
      rethrow;
    }
  }
}