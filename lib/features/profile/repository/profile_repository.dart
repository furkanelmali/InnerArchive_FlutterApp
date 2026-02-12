import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_client.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile?> getByUsername(String username) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .eq('is_public', true)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  Future<String?> uploadAvatar(String userId, File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last;
      final path = '$userId/avatar.$ext';

      await _client.storage
          .from('avatars')
          .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));

      final url = _client.storage.from('avatars').getPublicUrl(path);
      return url;
    } catch (_) {
      return null;
    }
  }
}
