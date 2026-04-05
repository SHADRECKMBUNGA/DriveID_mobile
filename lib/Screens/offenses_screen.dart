import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/license_search_dialog.dart';
import '../widgets/license_preview_card.dart';
import '../services/offense_service.dart';
import '../services/dashboard_service.dart';
import '../models/offense.dart';
import '../models/license.dart';
import 'dashBoard_screen.dart';
import 'verify_screen.dart';

class OffensesScreen extends StatefulWidget {
  const OffensesScreen({super.key});

  @override
  State<OffensesScreen> createState() => _OffensesScreenState();
}

class _OffensesScreenState extends State<OffensesScreen> {
  bool? isRecording = false;
  final TextEditingController locationController = TextEditingController();
  String? selectedOffenseId;
  License? _selectedLicense;

  final OffenseService _offenseService = OffenseService();
  final DashboardService _dashboardService = DashboardService();
  List<Offense> _offenses = [];
  List<OffenseType> _offenseTypes = [];
  List<License> _allLicenses = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedOffenseId = null;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final offenses = await _offenseService.getOffenses();
      final fetchedTypes = await _offenseService.getOffenseTypes();
      final licenses = await _dashboardService.getAllLicenses();

      final defaultTypes = <OffenseType>[
        OffenseType(
          id: '550e8400-e29b-41d4-a716-446655440001',
          label: 'Speeding',
          fine: 'MWK 25,000',
        ),
        OffenseType(
          id: '550e8400-e29b-41d4-a716-446655440002',
          label: 'Driving without license',
          fine: 'MWK 50,000',
        ),
        OffenseType(
          id: '550e8400-e29b-41d4-a716-446655440003',
          label: 'Reckless driving',
          fine: 'MWK 75,000',
        ),
        OffenseType(
          id: '550e8400-e29b-41d4-a716-446655440004',
          label: 'Drunk driving',
          fine: 'MWK 100,000',
        ),
        OffenseType(
          id: '550e8400-e29b-41d4-a716-446655440005',
          label: 'Dangerous driving',
          fine: 'MWK 150,000',
        ),
      ];
      setState(() {
        _offenses = offenses;
        _offenseTypes = fetchedTypes.isNotEmpty ? fetchedTypes : defaultTypes;
        _allLicenses = licenses;
        selectedOffenseId =
            _offenseTypes.isNotEmpty ? _offenseTypes.first.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> _submitOffense() async {
    if (_selectedLicense == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a license')));
      return;
    }

    if (locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a location')));
      return;
    }

    if (selectedOffenseId == null || selectedOffenseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an offense type.')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('Confirm Offense Recording'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationRow('Driver', _selectedLicense!.ownerName),
                _buildConfirmationRow(
                  'Registration',
                  _selectedLicense!.registerNumber,
                ),
                _buildConfirmationRow(
                  'License Type',
                  _selectedLicense!.licenseType,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                _buildConfirmationRow(
                  'Offense',
                  _offenseTypes
                      .firstWhere((t) => t.id == selectedOffenseId)
                      .label,
                ),
                _buildConfirmationRow(
                  'Fine',
                  _offenseTypes
                      .firstWhere((t) => t.id == selectedOffenseId)
                      .fine,
                ),
                _buildConfirmationRow('Location', locationController.text),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Edit'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Record',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final selectedType = _offenseTypes.firstWhere(
        (type) => type.id == selectedOffenseId,
      );

      await _offenseService.createOffense(
        name: _selectedLicense!.ownerName,
        registrationNumber: _selectedLicense!.registerNumber,
        offenseTypeId: selectedOffenseId!,
        offenseType: selectedType.label,
        location: locationController.text,
        fine: selectedType.fine,
      );

      locationController.clear();
      selectedOffenseId =
          _offenseTypes.isNotEmpty ? _offenseTypes.first.id : null;
      _selectedLicense = null;
      isRecording = false;

      // Reload data to show the new offense
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offense recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to record offense: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (idx) {
          if (idx == 2) return;
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (idx == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VerifyScreen()),
            );
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offenses',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Record traffic violations',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Top header + record button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record Offense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () =>
                          setState(() => isRecording = !(isRecording ?? false)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(isRecording == true ? 'Close' : 'Record'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (isRecording == true)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // License Search Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => LicenseSearchDialog(
                                  licenses: _allLicenses,
                                  onLicenseSelected: (license) {
                                    setState(() => _selectedLicense = license);
                                  },
                                ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text('Search License'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // License Preview Card
                    if (_selectedLicense != null)
                      Column(
                        children: [
                          LicensePreviewCard(
                            license: _selectedLicense!,
                            onEdit: () {
                              setState(() => _selectedLicense = null);
                              showDialog(
                                context: context,
                                builder:
                                    (_) => LicenseSearchDialog(
                                      licenses: _allLicenses,
                                      onLicenseSelected: (license) {
                                        setState(
                                          () => _selectedLicense = license,
                                        );
                                      },
                                    ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Location Field
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationController,
                      enabled: _selectedLicense != null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            _selectedLicense == null
                                ? 'Select a license first...'
                                : 'Enter offense location',
                        hintStyle: const TextStyle(color: Colors.white54),
                        fillColor: AppTheme.background,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.gold),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Offense Type Dropdown
                    const Text(
                      'Offense Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOffenseId,
                          dropdownColor: AppTheme.cardDark,
                          style: const TextStyle(color: Colors.white),
                          hint: const Text(
                            'Select offense type',
                            style: TextStyle(color: Colors.white70),
                          ),
                          isExpanded: true,
                          items:
                              _offenseTypes
                                  .map(
                                    (offenseType) => DropdownMenuItem<String>(
                                      value: offenseType.id,
                                      child: Text(
                                        '${offenseType.label} - ${offenseType.fine}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedOffenseId = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ||
                                    _selectedLicense == null ||
                                    locationController.text.isEmpty ||
                                    selectedOffenseId == null
                                ? null
                                : _submitOffense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: AppTheme.gold.withOpacity(
                            0.5,
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Review & Record',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Offense list
            const Text(
              'Recent Offenses',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_offenses.isEmpty)
              const Center(
                child: Text(
                  'No offenses recorded yet',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ..._offenses.map((offense) {
                return Card(
                  color: AppTheme.cardDark,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offense.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offense.registrationNumber,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          offense.offenseType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offense.location,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    offense.status.toLowerCase() == 'pending'
                                        ? Colors.amber.shade700
                                        : Colors.green.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                offense.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              offense.fine,
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
