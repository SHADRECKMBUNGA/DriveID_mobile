// lib/services/activity_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logActivity({
    required String action,
    String? details, required String userId,
  }) async {
    try {
      // Omit user_id – the database will set it using DEFAULT auth.uid()
      await _supabase.from('user_activities').insert({
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserActivities(String userId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final response = await _supabase
        .from('user_activities')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return response;
  }
}