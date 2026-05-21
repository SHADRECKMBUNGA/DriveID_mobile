import 'package:driveid_app/features/driver/services/driver_offense_service.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<DriverOffensesResult> _offensesFuture;
  final DriverOffenseService _offenseService = DriverOffenseService();

  @override
  void initState() {
    super.initState();
    _loadOffenses();
  }

  void _loadOffenses() {
    _offensesFuture = _offenseService.fetchOffenses();
  }

  Future<void> _refresh() async {
    setState(_loadOffenses);
    await _offensesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFFFFC124),
      child: FutureBuilder<DriverOffensesResult>(
        future: _offensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator(color: Color(0xFFFFC124))),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC124),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            );
          }

          final result = snapshot.data!;
          final offenses = result.offenses;
          final totals = result.totals;

          if (offenses.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No offenses recorded',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: offenses.length + 1,
            separatorBuilder: (_, index) {
              if (index == 0) return const SizedBox(height: 8);
              return const Divider(color: Colors.white24);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FinesSummaryCard(totals: totals);
              }

              final off = offenses[index - 1];
              final status = off['status']?.toString() ?? 'Pending';
              final isPaidOrResolved =
                  status.toLowerCase() == 'paid' || status.toLowerCase() == 'resolved';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Icon(
                  isPaidOrResolved ? Icons.check_circle : Icons.warning_amber,
                  color: isPaidOrResolved ? Colors.green : Colors.orange,
                ),
                title: Text(
                  off['offense_type']?.toString() ?? 'Offense',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${off['location'] ?? 'Unknown location'} • ${_formatDateString(off['created_at']?.toString() ?? '')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      off['fine']?.toString() ?? '—',
                      style: const TextStyle(
                        color: Color(0xFFFFC124),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaidOrResolved
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: isPaidOrResolved ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateString(String iso) {
    if (iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _FinesSummaryCard extends StatelessWidget {
  final DriverOffenseTotals totals;

  const _FinesSummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL FINES',
            style: TextStyle(
              color: Color(0xFFFFC124),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DriverOffenseService.formatMwk(totals.totalAll),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totals.offenseCount} offense${totals.offenseCount == 1 ? '' : 's'} on record',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (totals.totalPending > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Outstanding: ${DriverOffenseService.formatMwk(totals.totalPending)}',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
