// lib/features/profile/state/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final userProfileProvider = FutureProvider<UserModel?>((ref) {
  final profileService = ref.watch(profileServiceProvider);

  // ✅ On revient à la logique normale qui dépend de la connexion
  return profileService.getCurrentUserProfile();
});