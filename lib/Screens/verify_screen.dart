import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/verification_result_card.dart';
import '../widgets/offense_form.dart';
import '../services/dashboard_service.dart';
import '../services/offense_service.dart';
import '../models/license.dart';
import 'dashBoard_screen.dart';
import 'offenses_screen.dart';

enum VerificationStatus { none, success, inactive, notFound, error }

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with TickerProviderStateMixin {
  bool isQRMode = false;
  bool isScanned = false;
  bool _isVerifying = false;
  bool _showOffenseForm = false;

  License? _verificationLicense;
  String? _verificationMessage;
  VerificationStatus _verificationStatus = VerificationStatus.none;
  List<String> _offenseTypes = [];
  Map<String, String> _offenseFines = {}; // Map offense type to fine

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final DashboardService _dashboardService = DashboardService();
  final OffenseService _offenseService = OffenseService();
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOffenseTypes();
  }

  Future<void> _loadOffenseTypes() async {
    print('🔄 VerifyScreen: Loading offense types...');
    try {
      final types = await _offenseService.getOffenseTypes();
      print('✅ VerifyScreen: Loaded ${types.length} offense types');

      if (mounted) {
        setState(() {
          _offenseTypes = types.map((t) => t.label).toList();
          _offenseFines = {for (var type in types) type.label: type.fine};
        });
        print('📝 VerifyScreen: Set offense types: $_offenseTypes');
        print('💰 VerifyScreen: Set fines: $_offenseFines');
      }
    } catch (e) {
      print('❌ VerifyScreen: Error loading offense types: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading offense types: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (idx) {
          if (idx == 1) return;
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (idx == 2) {
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
              "Verify User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Scan QR code or search by register number",
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 20),

            // 🔄 Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isQRMode = false;
                        isScanned = false;
                      });
                    },
                    child: _toggleButton("Manual", Icons.search, !isQRMode),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isQRMode = true;
                        isScanned = false;
                      });
                    },
                    child: _toggleButton("QR Scan", Icons.qr_code, isQRMode),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Scanner or Manual Input
            Expanded(
              child:
                  _verificationStatus == VerificationStatus.none
                      ? (isQRMode ? _qrScannerView() : _manualView())
                      : _resultView(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RESULT VIEW =================
  Widget _resultView() {
    if (_verificationLicense == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _verificationStatus == VerificationStatus.notFound
                  ? Icons.search_off
                  : Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              _verificationMessage ?? 'Verification failed',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Result Card
        SingleChildScrollView(
          child: Column(
            children: [
              VerificationResultCard(
                license: _verificationLicense!,
                onRecordOffense: () {
                  setState(() => _showOffenseForm = true);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Offense Form Modal
        if (_showOffenseForm)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() => _showOffenseForm = false);
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: GestureDetector(
                  onTap: () {},
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) {
                      return OffenseForm(
                        licenseId: _verificationLicense!.id,
                        licenseOwnerName: _verificationLicense!.ownerName,
                        registrationNumber:
                            _verificationLicense!.registerNumber,
                        offenseTypes: _offenseTypes,
                        offenseFines: _offenseFines,
                        onSubmit: _handleOffenseSubmit,
                        onCancel: () {
                          setState(() => _showOffenseForm = false);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================= HANDLE OFFENSE SUBMISSION =================
  void _handleOffenseSubmit(OffenseFormData formData) async {
    if (_verificationLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License data not available')),
      );
      return;
    }

    try {
      await _offenseService.recordOffenseForLicense(
        licenseId: _verificationLicense!.id,
        licenseOwnerName: _verificationLicense!.ownerName,
        registrationNumber: _verificationLicense!.registerNumber,
        offenseType: formData.offenseType,
        location: formData.location,
        fine: formData.fine ?? 'TBD',
      );

      if (mounted) {
        setState(() => _showOffenseForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offense recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record offense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetVerification() {
    setState(() {
      _verificationStatus = VerificationStatus.none;
      _verificationMessage = null;
      _verificationLicense = null;
      _showOffenseForm = false;
      isScanned = false;
      _manualController.clear();
    });
  }

  // ================= TOGGLE BUTTON =================
  Widget _toggleButton(String text, IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: active ? AppTheme.gold : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: active ? Colors.black : Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= QR SCANNER VIEW =================
  Widget _qrScannerView() {
    return Stack(
      children: [
        // 📷 CAMERA
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (isScanned) return;

              // mobile_scanner v7+ uses BarcodeCapture
              Barcode? validBarcode;
              for (final b in capture.barcodes) {
                if (b.rawValue != null && b.rawValue!.isNotEmpty) {
                  validBarcode = b;
                  break;
                }
              }
              if (validBarcode == null) return;

              final String code = validBarcode.rawValue!;
              setState(() => isScanned = true);

              // 👉 HANDLE RESULT
              _onQRScanned(code);
            },
          ),
        ),

        // 🔲 DARK OVERLAY (semi-transparent fill)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        // 🎯 SCAN FRAME
        Center(
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gold, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 📍 INSTRUCTION TEXT
        const Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Position QR code within the frame",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MANUAL VIEW =================
  Widget _manualView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter register number...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                onPressed: _isVerifying ? null : _onManualVerify,
                icon:
                    _isVerifying
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 24,
                        ),
                style: IconButton.styleFrom(
                  backgroundColor: _isVerifying ? Colors.grey : AppTheme.gold,
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Format: 14-digit number (e.g., 20260104008973)",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // ================= HANDLE QR RESULT =================
  void _onQRScanned(String code) async {
    try {
      await _verifyLicense(code);
    } finally {
      setState(() => isScanned = false);
    }
  }

  // ================= HANDLE MANUAL VERIFICATION =================
  void _onManualVerify() async {
    FocusScope.of(context).unfocus();

    final regNumber = _manualController.text.trim();

    if (regNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a registration number')),
      );
      return;
    }

    if (!_isValidRegistrationNumber(regNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid registration number format')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await _verifyLicense(regNumber);
    } finally {
      setState(() => _isVerifying = false);
      _manualController.clear();
    }
  }

  // ================= VERIFY LICENSE =================
  Future<void> _verifyLicense(String registrationNumber) async {
    try {
      final success = await _dashboardService.verifyAndRecordLicense(
        registrationNumber,
      );

      final license = await _dashboardService.getLicenseDetails(
        registrationNumber,
      );

      if (!mounted) return;

      if (success && license != null) {
        setState(() {
          _verificationStatus = VerificationStatus.success;
          _verificationMessage = 'License verified and recorded';
          _verificationLicense = license;
        });
      } else if (license != null) {
        setState(() {
          _verificationStatus = VerificationStatus.inactive;
          _verificationMessage = 'License is inactive or expired';
          _verificationLicense = license;
        });
      } else {
        setState(() {
          _verificationStatus = VerificationStatus.notFound;
          _verificationMessage = 'License not found in the system';
          _verificationLicense = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verificationStatus = VerificationStatus.error;
        _verificationMessage = 'Verification error: $e';
        _verificationLicense = null;
      });
    }
  }

  // ================= VALIDATE REGISTRATION NUMBER =================
  bool _isValidRegistrationNumber(String regNumber) {
    final regExp = RegExp(r'^\d{14}$');
    return regExp.hasMatch(regNumber);
  }
}
