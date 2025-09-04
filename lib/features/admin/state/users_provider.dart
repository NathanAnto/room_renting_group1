// lib/features/admin/state/users_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';

final usersStreamProvider = StreamProvider<List<UserProfile>>((ref) {
  final col = FirebaseFirestore.instance.collection('Profile'); // ⚠️ P majuscule
  // includeMetadataChanges pour voir si on lit depuis le cache
  return col.snapshots(includeMetadataChanges: true).map((snap) {
    if (kDebugMode) {
      debugPrint(
          '[Profile] docs=${snap.docs.length} fromCache=${snap.metadata.isFromCache}');
      for (final d in snap.docs) {
        debugPrint(' - ${d.id} => ${d.data()}');
      }
    }
    return snap.docs
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList();
  });
});
