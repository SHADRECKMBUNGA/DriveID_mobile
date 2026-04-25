// lib/features/driver/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'package:driveid_app/features/traffic_officer/services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ProfileService().fetchProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
            );
          }
          final profile = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile['photo_url'] != null ? NetworkImage(profile['photo_url']!) : null,
                  child: profile['photo_url'] == null ? const Icon(Icons.person, size: 40, color: AppTheme.gold) : null,
                ),
                const SizedBox(height: 16),
                _readOnlyTile('Full Name', profile['full_name'] ?? 'Not set'),
                const Divider(color: Colors.white24, height: 32),
                _readOnlyTile('Email', profile['email'] ?? 'Not set'),
                const Divider(color: Colors.white24, height: 32),
                _readOnlyTile('Phone Number', profile['phone'] ?? 'Not set'),
                const SizedBox(height: 32),
                const Text(
                  'This information is managed by the government registry.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _readOnlyTile(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}