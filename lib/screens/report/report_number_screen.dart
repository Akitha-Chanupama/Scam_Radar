import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/scam_number.dart';
import '../../models/community_report.dart';
import '../../providers/scam_numbers_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scam_messages_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class ReportNumberScreen extends ConsumerStatefulWidget {
  const ReportNumberScreen({super.key});

  @override
  ConsumerState<ReportNumberScreen> createState() => _ReportNumberScreenState();
}

class _ReportNumberScreenState extends ConsumerState<ReportNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedScamType = ScamKeywords.scamTypes.first;
  String? _selectedRegion;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSubmitted = false;
  ScamNumber? _existingReport;

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final result =
          await ref.read(scamNumbersProvider.notifier).searchNumber(phone);
      setState(() {
        _existingReport = result;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final coords = _selectedRegion != null
          ? ScamKeywords.sriLankanDistricts[_selectedRegion]
          : null;

      await ref.read(scamNumbersProvider.notifier).reportNumber(
            phoneNumber: _phoneController.text.trim(),
            scamType: _selectedScamType,
            region: _selectedRegion,
            latitude: coords?[0],
            longitude: coords?[1],
          );

      // Also create community report
      final db = ref.read(databaseServiceProvider);
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        final scamNumber =
            await db.searchScamNumber(_phoneController.text.trim());
        if (scamNumber != null) {
          await db.insertCommunityReport(
            CommunityReport(
              reporterId: userId,
              reportType: 'number',
              scamNumberId: scamNumber.id,
              description: _descriptionController.text.trim().isEmpty
                  ? '$_selectedScamType scam reported'
                  : _descriptionController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit report. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isSubmitted = false;
      _existingReport = null;
      _phoneController.clear();
      _descriptionController.clear();
      _selectedScamType = ScamKeywords.scamTypes.first;
      _selectedRegion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Scam Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isSubmitted ? _buildSuccessState(colorScheme) : _buildForm(colorScheme),
      ),
    );
  }

  Widget _buildSuccessState(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
        ),
        const SizedBox(height: 24),
        Text(
          'Report Submitted!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for helping keep the community safe.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _resetForm,
          child: const Text('Report Another Number'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.phoneNumber,
            onChanged: (_) => _searchNumber(),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+94 7X XXX XXXX',
              prefixIcon: const Icon(Icons.phone_outlined),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),

          // Existing report indicator
          if (_existingReport != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Already reported ${_existingReport!.reportsCount} time(s)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Type: ${_existingReport!.scamType}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Scam type dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedScamType,
            decoration: const InputDecoration(
              labelText: 'Scam Type',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: ScamKeywords.scamTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedScamType = v!),
          ),
          const SizedBox(height: 16),

          // Region dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Region (optional)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select region'),
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
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Describe the scam call/message...',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitReport,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'Submitting...' : 'Submit Report'),
          ),
        ],
      ),
    );
  }
}
