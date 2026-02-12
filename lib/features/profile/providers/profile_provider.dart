import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_client.dart';
import '../models/profile_model.dart';
import '../repository/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final ProfileRepository _repo;

  @override
  Future<UserProfile?> build() async {
    _repo = ref.read(profileRepositoryProvider);
    final userId = SupabaseClientProvider.client.auth.currentUser?.id;
    if (userId == null) return null;
    return _repo.getProfile(userId);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? username,
    bool? isPublic,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;

    final updated = current.copyWith(
      displayName: displayName ?? current.displayName,
      bio: bio ?? current.bio,
      username: username ?? current.username,
      isPublic: isPublic ?? current.isPublic,
      updatedAt: DateTime.now(),
    );

    state = AsyncData(updated);
    await _repo.updateProfile(updated);
  }

  Future<void> uploadAvatar(File imageFile) async {
    final current = state.asData?.value;
    if (current == null) return;

    final url = await _repo.uploadAvatar(current.id, imageFile);
    if (url == null) return;

    final updated = current.copyWith(avatarUrl: url, updatedAt: DateTime.now());
    state = AsyncData(updated);
    await _repo.updateProfile(updated);
  }
}
