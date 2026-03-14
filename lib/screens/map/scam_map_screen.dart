import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/scam_number.dart';
import '../../providers/map_provider.dart';

class ScamMapScreen extends ConsumerWidget {
  const ScamMapScreen({super.key});

  Color _markerColor(String scamType) {
    switch (scamType.toLowerCase()) {
      case 'lottery / prize':
        return Colors.red;
      case 'bank fraud':
        return Colors.orange;
      case 'package delivery':
        return Colors.blue;
      case 'insurance':
        return Colors.purple;
      case 'romance / dating':
        return Colors.pink;
      case 'investment':
        return Colors.teal;
      case 'government impersonation':
        return Colors.brown;
      case 'tech support':
        return Colors.cyan;
      case 'job offer':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scamNumbers = ref.watch(mapScamNumbersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scam Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mapScamNumbersProvider),
          ),
        ],
      ),
      body: scamNumbers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load map data',
                  style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(mapScamNumbersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (numbers) => Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(7.8731, 80.7718), // Sri Lanka center
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
                  markers: numbers.map((sn) => _buildMarker(context, sn)).toList(),
                ),
              ],
            ),

            // Legend
            Positioned(
              bottom: 16,
              left: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scam Types',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      _legendItem('Lottery', Colors.red),
                      _legendItem('Bank Fraud', Colors.orange),
                      _legendItem('Delivery', Colors.blue),
                      _legendItem('Investment', Colors.teal),
                      _legendItem('Other', Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            // Count badge
            Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '${numbers.length} scam reports',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
            color: color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _markerColor(sn.scamType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone,
                      color: _markerColor(sn.scamType)),
                ),
                const SizedBox(width: 12),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _markerColor(sn.scamType),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(context, Icons.report_outlined,
                '${sn.reportsCount} reports'),
            if (sn.region != null)
              _detailRow(context, Icons.location_on_outlined, sn.region!),
            _detailRow(context, Icons.calendar_today_outlined,
                'Reported on ${sn.createdAt.toLocal().toString().substring(0, 10)}'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
