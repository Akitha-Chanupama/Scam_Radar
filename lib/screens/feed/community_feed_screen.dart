import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/community_feed_provider.dart';
import '../../widgets/scam_card.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(communityFeedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: feedState.filterType == null,
                  onSelected: () =>
                      ref.read(communityFeedProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Messages',
                  isSelected: feedState.filterType == 'message',
                  onSelected: () => ref
                      .read(communityFeedProvider.notifier)
                      .setFilter('message'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Numbers',
                  isSelected: feedState.filterType == 'number',
                  onSelected: () => ref
                      .read(communityFeedProvider.notifier)
                      .setFilter('number'),
                ),
              ],
            ),
          ),

          // Feed list
          Expanded(
            child: feedState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : feedState.reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reports yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Community reports will appear here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(communityFeedProvider.notifier)
                            .loadReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: feedState.reports.length,
                          itemBuilder: (context, index) {
                            final report = feedState.reports[index];
                            return ScamCard(report: report);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }
}
