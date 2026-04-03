import 'package:flutter/material.dart';
import '../models/license.dart';
import '../theme/app_theme.dart';

class VerificationResultCard extends StatelessWidget {
  final License license;
  final VoidCallback onRecordOffense;

  const VerificationResultCard({
    super.key,
    required this.license,
    required this.onRecordOffense,
  });

  Color _getStatusColor() {
    if (license.isRevoked) return Colors.red;
    if (license.isExpired) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (license.isRevoked) return 'Revoked';
    if (license.isExpired) return 'Expired';
    return 'Valid';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      license.isRevoked
                          ? Icons.block
                          : license.isExpired
                          ? Icons.schedule
                          : Icons.verified,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'License ${_getStatusText()}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Section - Horizontal Layout
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.gold.withOpacity(0.15),
                      child:
                          license.profilePictureUrl != null
                              ? ClipOval(
                                child: Image.network(
                                  license.profilePictureUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: AppTheme.gold,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                              : const Icon(
                                Icons.person,
                                color: AppTheme.gold,
                                size: 50,
                              ),
                    ),
                    const SizedBox(width: 20),

                    // Owner Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            license.ownerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              license.licenseType,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                // License Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Expiry Date
                    Column(
                      children: [
                        Icon(
                          Icons.event,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Expiry Date',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          license.expiryDate.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                license.isExpired ? Colors.red : Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Status Validity
                    Column(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Validity',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          license.daysUntilExpiry.split(' ')[0],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                license.isExpired ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Record Offense Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRecordOffense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.red.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Record Offense',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
