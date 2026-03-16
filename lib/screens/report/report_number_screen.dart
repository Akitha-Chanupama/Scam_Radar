import 'dart:math' show sqrt;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/community_report.dart';
import '../../models/scam_number.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scam_messages_provider.dart'
    show databaseServiceProvider;
import '../../providers/scam_numbers_provider.dart';
import '../../utils/constants.dart';

class ReportNumberScreen extends ConsumerStatefulWidget {
  const ReportNumberScreen({super.key});

  @override
  ConsumerState<ReportNumberScreen> createState() => _ReportNumberScreenState();
}

class _ReportNumberScreenState extends ConsumerState<ReportNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedScamType = ScamKeywords.scamTypes.first;
  String? _selectedRegion;
  ScamNumber? _existingReport;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  // GPS location state
  bool _useGps = false;
  double? _gpsLat;
  double? _gpsLng;
  String? _gpsNearestDistrict;
  bool _gettingLocation = false;
  String? _gpsError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchNumber(String phone) async {
    if (phone.length < 9) {
      setState(() => _existingReport = null);
      return;
    }
    setState(() => _isSearching = true);
    final result = await ref
        .read(scamNumbersProvider.notifier)
        .searchNumber(phone);
    setState(() {
      _existingReport = result;
      _isSearching = false;
    });
  }

  /// Return the name of the district whose centre is closest to [lat]/[lng].
  String? _nearestDistrict(double lat, double lng) {
    String? closest;
    double minDist = double.infinity;
    ScamKeywords.sriLankanDistricts.forEach((name, coords) {
      final dlat = lat - coords[0];
      final dlng = lng - coords[1];
      final d = sqrt(dlat * dlat + dlng * dlng);
      if (d < minDist) {
        minDist = d;
        closest = name;
      }
    });
    return closest;
  }

  Future<void> _getGpsLocation() async {
    setState(() {
      _gettingLocation = true;
      _gpsError = null;
    });

    try {
      // Check/request permission first.
      // NOTE: We skip isLocationServiceEnabled() — on some Android devices
      // (e.g. Huawei EMUI) it falsely returns false even when GPS is on.
      // If the service is genuinely off, getCurrentPosition() will throw
      // LocationServiceDisabledException which we catch below.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Location permission denied.';
            _gettingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError =
              'Location permission permanently denied.\nPlease enable it in App Settings.';
          _gettingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
        _gpsNearestDistrict = _nearestDistrict(pos.latitude, pos.longitude);
        _gettingLocation = false;
      });
    } on LocationServiceDisabledException {
      setState(() {
        _gpsError =
            'Device location/GPS is turned off.\nPlease enable it in your device settings.';
        _gettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Could not get location: ${e.toString()}';
        _gettingLocation = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      double? lat;
      double? lng;
      String? region;

      if (_useGps && _gpsLat != null && _gpsLng != null) {
        lat = _gpsLat;
        lng = _gpsLng;
        region = _gpsNearestDistrict;
      } else if (_selectedRegion != null) {
        final coords = ScamKeywords.sriLankanDistricts[_selectedRegion!]!;
        lat = coords[0];
        lng = coords[1];
        region = _selectedRegion;
      }

      await ref
          .read(scamNumbersProvider.notifier)
          .reportNumber(
            phoneNumber: _phoneCtrl.text.trim(),
            scamType: _selectedScamType,
            region: region,
            latitude: lat,
            longitude: lng,
          );

      // Also insert community report
      final scamNum = await ref
          .read(scamNumbersProvider.notifier)
          .searchNumber(_phoneCtrl.text.trim());

      await ref
          .read(databaseServiceProvider)
          .insertCommunityReport(
            CommunityReport(
              reporterId: user.id,
              reportType: 'number',
              scamNumberId: scamNum?.id,
              description: _descCtrl.text.trim(),
              createdAt: DateTime.now(),
            ),
          );

      setState(() => _isSubmitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(isDark),
      body: _isSubmitted
          ? _buildSuccessState(context, isDark)
          : _buildForm(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.bgDark.withValues(alpha: 0.95)
          : AppColors.bgLight.withValues(alpha: 0.95),
      elevation: 0,
      title: const Text(
        'Report Number',
        style: TextStyle(
          color: AppColors.cyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.cyan.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context, isDark),
            const SizedBox(height: 24),

            // Existing report warning
            if (_existingReport != null)
              _buildWarningBanner(context, _existingReport!, isDark),

            // Form card
            _buildFormCard(context, isDark),
            const SizedBox(height: 24),

            // Submit button
            _buildSubmitButton(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.errorRed.withValues(alpha: 0.12),
                AppColors.blue.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.errorRed.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorRed.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flag,
                  color: AppColors.errorRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help protect the community',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Report scam numbers to warn others.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildWarningBanner(
    BuildContext context,
    ScamNumber existing,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB020).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFB020),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Already reported ${existing.reportsCount}× as "${existing.scamType}"',
              style: const TextStyle(
                color: Color(0xFFFFB020),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildFormCard(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white).withValues(
              alpha: isDark ? 0.55 : 0.85,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Phone field
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone, color: AppColors.cyan),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyan,
                            ),
                          ),
                        )
                      : null,
                  hintText: '07X XXX XXXX',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a phone number';
                  return null;
                },
                onChanged: _searchNumber,
              ),
              const SizedBox(height: 16),

              // Scam type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedScamType,
                decoration: const InputDecoration(
                  labelText: 'Scam Type',
                  prefixIcon: Icon(Icons.category, color: AppColors.cyan),
                ),
                items: ScamKeywords.scamTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedScamType = v);
                },
              ),
              const SizedBox(height: 16),

              // Location section
              _buildLocationSection(),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined, color: AppColors.cyan),
                  hintText: 'Tell us what this scammer said…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05);
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle: District / GPS
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Location (optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _locationToggleChip(
                    label: 'District',
                    icon: Icons.map_outlined,
                    selected: !_useGps,
                    onTap: () => setState(() {
                      _useGps = false;
                      _gpsError = null;
                    }),
                  ),
                  _locationToggleChip(
                    label: 'GPS',
                    icon: Icons.gps_fixed,
                    selected: _useGps,
                    onTap: () => setState(() {
                      _useGps = true;
                      _gpsError = null;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // District dropdown
        if (!_useGps)
          DropdownButtonFormField<String?>(
            initialValue: _selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Select district',
              prefixIcon: Icon(
                Icons.location_city_outlined,
                color: AppColors.cyan,
              ),
              isDense: true,
            ),
            hint: const Text('None'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
              ...ScamKeywords.sriLankanDistricts.keys.map(
                (d) => DropdownMenuItem(value: d, child: Text(d)),
              ),
            ],
            onChanged: (v) => setState(() => _selectedRegion = v),
          )
        else
          // GPS picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _gettingLocation ? null : _getGpsLocation,
                icon: _gettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyan,
                        ),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _gettingLocation
                      ? 'Getting location…'
                      : _gpsLat != null
                      ? 'Update Location'
                      : 'Get My Location',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_gpsError != null) ...
                [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _gpsError!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              if (_gpsLat != null && _gpsLng != null) ...
                [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          color: AppColors.cyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_gpsNearestDistrict != null)
                                Text(
                                  _gpsNearestDistrict!,
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              Text(
                                '${_gpsLat!.toStringAsFixed(5)}, ${_gpsLng!.toStringAsFixed(5)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.cyan,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
      ],
    );
  }

  Widget _locationToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.cyan : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorRed.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send, size: 18),
        label: Text(
          _isSubmitting ? 'Submitting…' : 'Submit Report',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildSuccessState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D97E).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF00D97E).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D97E).withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00D97E),
                    size: 44,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  curve: Curves.elasticOut,
                  duration: 700.ms,
                )
                .fadeIn(),
            const SizedBox(height: 28),
            Text(
              'Report Submitted!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              'Thank you for helping protect the community from scammers.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isSubmitted = false;
                  _phoneCtrl.clear();
                  _descCtrl.clear();
                  _selectedScamType = ScamKeywords.scamTypes.first;
                  _selectedRegion = null;
                  _existingReport = null;
                  _useGps = false;
                  _gpsLat = null;
                  _gpsLng = null;
                  _gpsNearestDistrict = null;
                  _gpsError = null;
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Report Another'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text(
                'Go Back',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ).animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }
}
