// lib/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch profile for a given user ID from the 'profiles' table.
  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Profile not found for user $userId');
      }

      return response;
    } catch (e) {
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Update a user's profile (only used internally – drivers have read‑only access).
  /// This method is kept for future administrative use.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();

    try {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}