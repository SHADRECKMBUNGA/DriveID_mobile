// lib/features/traffic_officer/models/driver_license.dart
class DriverLicense {
  final String id;
  final String registerNumber;        // maps to 'license_number'
  final String ownerName;             // maps to 'full_name' from drivers
  final String licenseType;           // maps to 'license_class'
  final DateTime issueDate;           // 'issue_date'
  final DateTime? expiryDate;         // 'expiry_date'
  final String status;                // 'license_status' (valid, expired, etc.)
  final String? photoUrl;             // 'driver_photo_url' from drivers
  final String? driverId;             // 'driver_id'

  DriverLicense({
    required this.id,
    required this.registerNumber,
    required this.ownerName,
    required this.licenseType,
    required this.issueDate,
    this.expiryDate,
    required this.status,
    this.photoUrl,
    this.driverId,
  });

  factory DriverLicense.fromJson(Map<String, dynamic> json) {
    return DriverLicense(
      id: json['id'].toString(),
      // Database column 'license_number' -> registerNumber
      registerNumber: json['license_number'] ?? json['register_number'] ?? '',
      // Joined 'full_name' from drivers -> ownerName
      ownerName: json['full_name'] ?? json['owner_name'] ?? '',
      // Database column 'license_class' -> licenseType
      licenseType: json['license_class'] ?? json['license_type'] ?? '',
      issueDate: DateTime.parse(json['issue_date']),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      // Database column 'license_status' -> status
      status: json['license_status'] ?? json['status'] ?? 'valid',
      // Joined 'driver_photo_url' from drivers or direct 'photo_url'
      photoUrl: json['photo_url'] ?? json['driver_photo_url'],
      driverId: json['driver_id']?.toString(),
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'valid':
        return 'Valid';
      case 'active':
        return 'Valid';
      case 'expired':
        return 'Expired';
      case 'revoked':
        return 'Revoked';
      case 'suspended':
        return 'Suspended';
      default:
        return status;
    }
  }
}