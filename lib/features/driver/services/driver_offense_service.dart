import 'package:supabase_flutter/supabase_flutter.dart';

import '../../traffic_officer/services/auth_service.dart';

class DriverOffenseTotals {
  final int totalAll;
  final int totalPending;
  final int offenseCount;

  const DriverOffenseTotals({
    required this.totalAll,
    required this.totalPending,
    required this.offenseCount,
  });

  factory DriverOffenseTotals.fromJson(Map<String, dynamic> json) {
    return DriverOffenseTotals(
      totalAll: _asInt(json['total_all']),
      totalPending: _asInt(json['total_pending']),
      offenseCount: _asInt(json['offense_count']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DriverOffensesResult {
  final List<Map<String, dynamic>> offenses;
  final DriverOffenseTotals totals;
  final String? licenseNumber;

  const DriverOffensesResult({
    required this.offenses,
    required this.totals,
    this.licenseNumber,
  });
}

class DriverOffenseService {
  static int parseFineAmount(dynamic fine) {
    final digits = RegExp(r'\d+')
        .allMatches(fine?.toString() ?? '')
        .map((match) => match.group(0))
        .join();
    return int.tryParse(digits) ?? 0;
  }

  static String formatMwk(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return 'MK ${buffer.toString()}';
  }

  static DriverOffenseTotals totalsFromOffenses(List<Map<String, dynamic>> offenses) {
    var totalAll = 0;
    var totalPending = 0;

    for (final offense in offenses) {
      final amount = parseFineAmount(offense['fine']);
      totalAll += amount;

      final status = offense['status']?.toString().toLowerCase() ?? '';
      if (status != 'paid' && status != 'resolved') {
        totalPending += amount;
      }
    }

    return DriverOffenseTotals(
      totalAll: totalAll,
      totalPending: totalPending,
      offenseCount: offenses.length,
    );
  }

  Future<DriverOffensesResult> fetchOffenses() async {
    final hasBackendSession = await AuthService.appToken != null;
    final backend = await AuthService.fetchDriverOffensesFromBackend();
    if (backend != null) {
      final offenses = (backend['offenses'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final totalsMap = backend['totals'] is Map
          ? Map<String, dynamic>.from(backend['totals'] as Map)
          : <String, dynamic>{};
      return DriverOffensesResult(
        offenses: offenses,
        totals: DriverOffenseTotals.fromJson(totalsMap),
        licenseNumber: backend['license_number']?.toString(),
      );
    }

    if (hasBackendSession) {
      throw Exception('Could not load fines from the server. Check that the backend is running, then try again.');
    }

    return _fetchOffensesFromSupabase();
  }

  Future<DriverOffensesResult> _fetchOffensesFromSupabase() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final driver = await supabase
        .from('drivers')
        .select('id')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    if (driver == null) {
      return const DriverOffensesResult(
        offenses: [],
        totals: DriverOffenseTotals(totalAll: 0, totalPending: 0, offenseCount: 0),
      );
    }

    final license = await supabase
        .from('licenses')
        .select('license_number')
        .eq('driver_id', driver['id'])
        .maybeSingle();
    if (license == null) {
      return const DriverOffensesResult(
        offenses: [],
        totals: DriverOffenseTotals(totalAll: 0, totalPending: 0, offenseCount: 0),
      );
    }

    final licenseNumber = license['license_number']?.toString().trim() ?? '';
    final columns = ['registration_number', 'license_number', 'register_number'];
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    for (final column in columns) {
      try {
        final rows = await supabase
            .from('offenses')
            .select()
            .eq(column, licenseNumber)
            .order('created_at', ascending: false);
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = map['id']?.toString() ?? map.toString();
          if (seen.add(id)) merged.add(map);
        }
      } catch (_) {
        continue;
      }
    }

    return DriverOffensesResult(
      offenses: merged,
      totals: totalsFromOffenses(merged),
      licenseNumber: licenseNumber,
    );
  }
}
