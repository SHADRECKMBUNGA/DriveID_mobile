import 'package:driveid_app/features/driver/services/activity_service.dart';
import 'package:driveid_app/features/driver/services/user_session.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    final userId = UserSession().userId;
    if (userId == null) {
      _activitiesFuture = Future.error('User not authenticated');
    } else {
      _activitiesFuture = ActivityService().fetchUserActivities(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC124)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _loadActivities()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC124),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return const Center(
            child: Text('No activities recorded', style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white24),
          itemBuilder: (context, index) {
            final item = activities[index];
            final action = item['action'];
            final details = item['details'];
            final createdAt = DateTime.parse(item['created_at']);
            return ListTile(
              leading: _actionIcon(action),
              title: Text(
                _formatActionTitle(action),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: details != null && details.isNotEmpty
                  ? Text(details, style: const TextStyle(color: Colors.white54, fontSize: 12))
                  : null,
              trailing: Text(
                _formatTime(createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionIcon(String action) {
    switch (action) {
      case 'view_license':
        return const Icon(Icons.credit_card, color: Color(0xFFFFC124));
      case 'change_password':
        return const Icon(Icons.lock, color: Color(0xFFFFC124));
      case 'logout':
        return const Icon(Icons.logout, color: Color(0xFFFFC124));
      default:
        return const Icon(Icons.info, color: Color(0xFFFFC124));
    }
  }

  String _formatActionTitle(String action) {
    switch (action) {
      case 'view_license':
        return 'License viewed';
      case 'change_password':
        return 'Password changed';
      case 'logout':
        return 'Logged out';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}