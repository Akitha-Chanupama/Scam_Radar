import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      double? lat;
      double? lng;
      if (_selectedRegion != null) {
        final coords = ScamKeywords.sriLankanDistricts[_selectedRegion!]!;
        lat = coords[0];
        lng = coords[1];
      }

      await ref
          .read(scamNumbersProvider.notifier)
          .reportNumber(
            phoneNumber: _phoneCtrl.text.trim(),
            scamType: _selectedScamType,
            region: _selectedRegion,
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

              // Region dropdown
              DropdownButtonFormField<String?>(
                initialValue: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: 'Region (optional)',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.cyan,
                  ),
                ),
                hint: const Text('Select district'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...ScamKeywords.sriLankanDistricts.keys.map(
                    (d) => DropdownMenuItem(value: d, child: Text(d)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRegion = v),
              ),
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
