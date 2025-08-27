// lib/features/profile/state/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final userProfileProvider = FutureProvider<UserModel?>((ref) {
  final profileService = ref.watch(profileServiceProvider);

  // ✅ MODIFICATION POUR LE TEST :
  // On ignore la connexion et on charge directement un profil par son ID.
  return profileService.getUserProfile("FmxIVtvr930fjtjcuIWA");
});