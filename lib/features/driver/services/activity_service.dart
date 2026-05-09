// lib/services/activity_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logActivity({
    required String action,
    String? details, required String userId,
  }) async {
    try {
      if (userId.trim().isEmpty) return;
      await _supabase.from('user_activities').insert({
        'user_id': userId,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserActivities(String userId) async {
    final response = await _supabase
        .from('user_activities')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }
}