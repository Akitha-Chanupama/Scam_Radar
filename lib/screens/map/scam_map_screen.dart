import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/theme.dart';
import '../../models/scam_number.dart';
import '../../providers/map_provider.dart';

class ScamMapScreen extends ConsumerWidget {
  const ScamMapScreen({super.key});

  Color _markerColor(String scamType) {
    switch (scamType.toLowerCase()) {
      case 'lottery / prize':
        return AppColors.errorRed;
      case 'bank fraud':
        return const Color(0xFFFFB020);
      case 'package delivery':
        return AppColors.blue;
      case 'insurance':
        return const Color(0xFF9B59B6);
      case 'romance / dating':
        return const Color(0xFFE91E8C);
      case 'investment':
        return const Color(0xFF00C9A7);
      case 'government impersonation':
        return const Color(0xFFE67E22);
      case 'tech support':
        return AppColors.cyan;
      case 'job offer':
        return const Color(0xFF3498DB);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scamNumbers = ref.watch(mapScamNumbersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(context, isDark, ref),
      body: scamNumbers.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (e, st) => _ErrorState(
          onRetry: () => ref.invalidate(mapScamNumbersProvider),
        ),
        data: (numbers) => Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(7.8731, 80.7718),
                initialZoom: 7.5,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.scam_radar',
                ),
                MarkerLayer(
                  markers: numbers
                      .map((sn) => _buildMarker(context, sn))
                      .toList(),
                ),
              ],
            ),

            // Legend
            Positioned(
              bottom: 20,
              left: 16,
              child: _buildLegend(context, isDark),
            ),

            // Count badge
            Positioned(
              top: 16,
              right: 16,
              child: _buildCountBadge(context, numbers.length, isDark),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, WidgetRef ref) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.bgDark.withValues(alpha: 0.95)
          : AppColors.bgLight.withValues(alpha: 0.95),
      elevation: 0,
      title: const Text(
        'Scam Map',
        style: TextStyle(
          color: AppColors.cyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: () => ref.invalidate(mapScamNumbersProvider),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.cyan.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white)
                .withValues(alpha: isDark ? 0.75 : 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.15),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCAM TYPES',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _legendItem('Lottery', AppColors.errorRed),
              _legendItem('Bank Fraud', const Color(0xFFFFB020)),
              _legendItem('Delivery', AppColors.blue),
              _legendItem('Investment', const Color(0xFF00C9A7)),
              _legendItem('Other', AppColors.textSecondary),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildCountBadge(
      BuildContext context, int count, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white)
                .withValues(alpha: isDark ? 0.75 : 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.2),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppColors.cyan, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count scam reports',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(BuildContext context, ScamNumber sn) {
    final color = _markerColor(sn.scamType);
    return Marker(
      point: LatLng(sn.latitude!, sn.longitude!),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showDetail(context, sn),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${sn.reportsCount}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, ScamNumber sn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _markerColor(sn.scamType);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.15),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.phone, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sn.phoneNumber,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            sn.scamType,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(context, Icons.report_outlined,
                    '${sn.reportsCount} reports'),
                if (sn.region != null)
                  _detailRow(context, Icons.location_on_outlined, sn.region!),
                _detailRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Reported on ${sn.createdAt.toLocal().toString().substring(0, 10)}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
          const SizedBox(height: 12),
          const Text('Failed to load map data',
              style: TextStyle(color: AppColors.errorRed)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
