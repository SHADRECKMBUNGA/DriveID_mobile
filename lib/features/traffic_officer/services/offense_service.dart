import 'dart:developer' show log;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../models/license.dart';
import '../models/offense.dart';
import 'dashboard_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';
import '../../../core/services/local_database_service.dart';

class OffenseService {
  final SupabaseClient _client = SupabaseConfig.client;
  final DashboardService _dashboardService = DashboardService();
  static const Duration _requestTimeout = Duration(seconds: 4);
  static const List<String> _identifierColumns = [
    'registration_number',
    'license_number',
    'register_number',
  ];

  bool _isMissingColumnError(Object error, String expectedColumn) {
    return error is PostgrestException &&
        (error.code == '42703' || error.code == 'PGRST204') &&
        error.message.toLowerCase().contains(expectedColumn.toLowerCase());
  }

  String _mapIdentifierKey(Map<String, dynamic> payload) {
    if (payload.containsKey('registration_number')) return 'registration_number';
    if (payload.containsKey('license_number')) return 'license_number';
    return 'register_number';
  }

  Future<Map<String, dynamic>> _insertPayloadWithCompatibility(
    Map<String, dynamic> payload,
  ) async {
    // Build clean payload with the new schema columns
    final registration_number = payload['registration_number'] ?? payload['license_number'] ?? payload['register_number'];
    
    if (registration_number == null || registration_number.toString().isEmpty) {
      throw Exception('Registration/license number is required');
    }

    // Normalize status to match DB check constraint values
    const allowedStatuses = ['Pending', 'Paid', 'Resolved', 'Cleared'];
    final incomingStatus = (payload['status'] ?? 'Pending').toString().trim();
    String normalizedStatus = 'Pending';
    for (final s in allowedStatuses) {
      if (incomingStatus.toLowerCase().contains(s.toLowerCase())) {
        normalizedStatus = s;
        break;
      }
    }

    final cleanPayload = {
      'name': payload['name'] ?? 'Unknown',
      'registration_number': registration_number.toString().trim(),
      'license_number': registration_number.toString().trim(),
      'offense_type': payload['offense_type'],
      'location': payload['location'],
      'status': normalizedStatus,
      'fine': (payload['fine'] ?? '0').toString(),
      'created_at': payload['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
    };

    // Add optional fields if provided
    if (payload.containsKey('offense_type_id') && 
        payload['offense_type_id'] != null && 
        (payload['offense_type_id'] as String).isNotEmpty) {
      cleanPayload['offense_type_id'] = payload['offense_type_id'];
    }

    if (payload.containsKey('recorded_by') && payload['recorded_by'] != null) {
      cleanPayload['recorded_by'] = payload['recorded_by'];
    }

    if (payload.containsKey('license_class') && payload['license_class'] != null) {
      cleanPayload['license_class'] = payload['license_class'];
    }

    try {
      final response = await _client
          .from('offenses')
          .insert(cleanPayload)
          .select()
          .single()
          .timeout(_requestTimeout);
      return Map<String, dynamic>.from(response);
    } catch (error) {
      final msg = error.toString().toLowerCase();
      // If the remote DB doesn't have `license_number`, retry without it
      if (msg.contains('license_number') && (msg.contains('column') || msg.contains('could not find') || msg.contains('pgrst204') || msg.contains('does not exist'))) {
        log('license_number column missing on remote DB — retrying without license_number');
        final fallback = Map<String, dynamic>.from(cleanPayload);
        fallback.remove('license_number');
        try {
          final retryRes = await _client
              .from('offenses')
              .insert(fallback)
              .select()
              .single()
              .timeout(_requestTimeout);
          return Map<String, dynamic>.from(retryRes);
        } catch (e2) {
          log('Retry insert failed: $e2');
          throw Exception('Failed to insert offense after retry: $e2');
        }
      }

      // Log the error and rethrow with more context
      log('Error inserting offense: $error');
      throw Exception('Failed to insert offense: $error');
    }
  }

  Future<List<Offense>> _fetchOffensesByIdentifier(String identifier) async {
    for (final column in _identifierColumns) {
      try {
        final response = await _client
            .from('offenses')
            .select()
            .eq(column, identifier)
            .order('created_at', ascending: false)
            .timeout(_requestTimeout, onTimeout: () => []);

        final offenses = (response as List<dynamic>?) ?? [];
        return offenses
            .map((json) => Offense.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (error) {
        if (_isMissingColumnError(error, column)) {
          continue;
        }
        rethrow;
      }
    }

    return [];
  }

  Future<Offense> _insertOffenseWithSchemaFallback(
    Map<String, dynamic> payload,
  ) async {
    final response = await _insertPayloadWithCompatibility(payload);
    return Offense.fromJson(response);
  }

  Future<void> _insertOffenseRecordWithSchemaFallback(
    Map<String, dynamic> payload,
  ) async {
    await _insertPayloadWithCompatibility(payload);
  }

  Future<License?> validateLicense(String licenseNumber) async {
    try {
      return await _dashboardService.getLicenseDetails(licenseNumber);
    } catch (_) {
      return null;
    }
  }

  Future<List<Offense>> getOffenses() async {
    try {
      if (!await SyncService().isOnline()) {
        final pending = LocalDatabaseService.getPendingOffenses();
        return pending.map((json) => Offense.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      
      final response = await _client
          .from('offenses')
          .select()
          .order('created_at', ascending: false)
          .timeout(_requestTimeout, onTimeout: () => []);
      final offenses = (response as List<dynamic>?) ?? [];
      return offenses
          .map((json) => Offense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch offenses: $e');
    }
  }

  Future<List<Offense>> getOffensesByLicenseNumber(String licenseNumber) async {
    try {
      if (!await SyncService().isOnline()) {
        final pending = LocalDatabaseService.getPendingOffenses();
        final filtered = pending.where((o) => 
            o['license_number'] == licenseNumber ||
            o['registration_number'] == licenseNumber ||
            o['register_number'] == licenseNumber
        ).toList();
        return filtered.map((json) => Offense.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      
      return await _fetchOffensesByIdentifier(licenseNumber);
    } catch (e) {
      throw Exception('Failed to fetch driver offenses: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOffenseTypesRaw() async {
    try {
      final response = await _client
          .from('offense_types')
          .select()
          .order('label')
          .timeout(_requestTimeout, onTimeout: () => []);

      return (response as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<OffenseType>> getOffenseTypes() async {
    if (!await SyncService().isOnline()) {
      final cached = LocalDatabaseService.getCachedOffenseTypes();
      return cached.map((json) => OffenseType.fromJson(json)).toList();
    }
    
    final raw = await getOffenseTypesRaw();
    log('OffenseService.getOffenseTypes raw response: $raw');
    await LocalDatabaseService.cacheOffenseTypes(raw);
    return raw.map((json) => OffenseType.fromJson(json)).toList();
  }

  Future<Offense> createOffense({
    required String name,
    required String licenseNumber,
    required String offenseTypeId,
    required String offenseType,
    required String location,
    required String fine,
    String? recordedBy,
    String? licenseClass,
  }) async {
    try {
      final license = await _dashboardService.getLicenseDetails(licenseNumber);
      if (license == null) {
        throw Exception('License not found - license number is invalid');
      }

      final payload = {
        'name': name,
        'registration_number': licenseNumber,
        if (offenseTypeId.isNotEmpty) 'offense_type_id': offenseTypeId,
        'offense_type': offenseType,
        'location': location,
        'status': 'Pending',
        'fine': fine,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (recordedBy != null && recordedBy.isNotEmpty) 'recorded_by': recordedBy,
        if (licenseClass != null && licenseClass.isNotEmpty) 'license_class': licenseClass,
      };

      if (!await SyncService().isOnline()) {
        await LocalDatabaseService.savePendingOffense(payload);
        return Offense.fromJson(payload);
      }

      return _insertOffenseWithSchemaFallback(payload);
    } catch (e) {
      throw Exception('Failed to create offense: $e');
    }
  }

  Future<void> recordOffenseForLicense({
    required String licenseId,
    required String licenseOwnerName,
    required String licenseNumber,
    required String offenseType,
    required String location,
    required String fine,
    String? recordedBy,
    String? licenseClass,
  }) async {
    try {
      if (licenseNumber.isEmpty) {
        throw Exception('License number is required');
      }

      final license = await _dashboardService.getLicenseDetails(licenseNumber);
      if (license == null) {
        throw Exception('License not found - cannot record offense');
      }

      final payload = {
        'name': licenseOwnerName,
        'registration_number': licenseNumber,
        'offense_type': offenseType,
        'location': location,
        'status': 'Pending',
        'fine': fine,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (recordedBy != null && recordedBy.isNotEmpty) 'recorded_by': recordedBy,
        if (licenseClass != null && licenseClass.isNotEmpty) 'license_class': licenseClass,
      };

      if (!await SyncService().isOnline()) {
        await LocalDatabaseService.savePendingOffense(payload);
        return;
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final verificationCheck = await _dashboardService
          .getLatestVerificationForLicense(
            licenseNumber: licenseNumber,
            verifiedAfter: oneHourAgo,
          );

      if (verificationCheck == null) {
        throw Exception('License must be verified before recording an offense');
      }

      await _insertOffenseRecordWithSchemaFallback(payload).timeout(_requestTimeout);
    } catch (e) {
      throw Exception('Failed to record offense: $e');
    }
  }

  Future<void> recordOffenseRecordDirectly(Map<String, dynamic> payload) async {
    await _insertOffenseRecordWithSchemaFallback(payload);
  }

  Future<void> updateOffenseStatus(String offenseId, String status) async {
    try {
      await _client.from('offenses').update({'status': status}).eq('id', offenseId);
    } catch (e) {
      throw Exception('Failed to update offense status: $e');
    }
  }
}
