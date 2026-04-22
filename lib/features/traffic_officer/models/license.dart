// lib/models/license.dart
// ignore: unused_import
import 'package:driveid_app/features/traffic_officer/models/dashboard_stats.dart';
// ignore: unused_import
import 'package:driveid_app/features/driver/my_license_tab.dart';

class License {
  final String id;
  final String registerNumber;
  final String ownerName;
  final String licenseType;
  final DateTime expiryDate;
  final String status;
  final String? profilePictureUrl;

  License({
    required this.id,
    required this.registerNumber,
    required this.ownerName,
    required this.licenseType,
    required this.expiryDate,
    required this.status,
    this.profilePictureUrl,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'].toString(),
      registerNumber: json['register_number'] ?? '',
      ownerName: json['owner_name'] ?? '',
      licenseType: json['license_type'] ?? '',
      expiryDate: DateTime.parse(json['expiry_date']),
      status: json['status'] ?? 'active',
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'register_number': registerNumber,
      'owner_name': ownerName,
      'license_type': licenseType,
      'expiry_date': expiryDate.toIso8601String(),
      'status': status,
      'profile_picture_url': profilePictureUrl,
    };
  }

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isRevoked => status.toLowerCase() == 'revoked';
  
  String get daysUntilExpiry {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    if (difference < 0) return 'Expired ${difference.abs()} days ago';
    if (difference == 0) return 'Expires today';
    return 'Expires in $difference days';
  }
  
  String get statusDisplay {
    if (isRevoked) return 'Revoked';
    if (isExpired) return 'Expired';
    return 'Valid';
  }
}