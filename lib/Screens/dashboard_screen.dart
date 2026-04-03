import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_stats.dart';
import 'verify_screen.dart';
import 'offenses_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int index = 0;
  final DashboardService _dashboardService = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dashboardService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
    }
  }

  Widget statCard(
    String title,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.gold : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.black26,
            child: Icon(icon, color: highlight ? Colors.black : AppTheme.gold),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.black : Colors.white,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: highlight ? Colors.black87 : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: index,
        onTap: (i) {
          if (i == index) return;
          if (i == 0) {
            return;
          } else if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VerifyScreen()),
            );
          } else if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OffensesScreen()),
            );
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Traffic Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Verify licenses & manage offenses",
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: statCard(
                    "Verifications Today",
                    _isLoading
                        ? "..."
                        : _stats?.verificationsToday.toString() ?? "0",
                    Icons.check_circle,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    "Offenses Recorded",
                    _isLoading
                        ? "..."
                        : _stats?.offensesRecorded.toString() ?? "0",
                    Icons.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: statCard(
                    "Fines Pending",
                    _isLoading
                        ? "..."
                        : _stats?.pendingOffenses.toString() ?? "0",
                    Icons.car_rental,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    "Total Checks",
                    _isLoading
                        ? "..."
                        : _stats?.totalVerifications.toString() ?? "0",
                    Icons.search,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerifyScreen()),
          );
        },
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.search, color: Colors.black),
      ),
    );
  }
}
