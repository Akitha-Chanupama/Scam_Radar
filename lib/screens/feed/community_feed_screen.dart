import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/community_feed_provider.dart' show communityFeedProvider, FeedState;
import '../../widgets/scam_card.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(communityFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          _buildFilterBar(context, ref, feedState, isDark),
          Expanded(
            child: feedState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : feedState.reports.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        color: AppColors.cyan,
                        backgroundColor:
                            isDark ? AppColors.cardDark : Colors.white,
                        onRefresh: () =>
                            ref.read(communityFeedProvider.notifier).loadReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: feedState.reports.length,
                          itemBuilder: (context, index) {
                            return ScamCard(report: feedState.reports[index])
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                      milliseconds: 50 + index * 40),
                                  duration: 300.ms,
                                )
                                .slideX(begin: 0.04);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.bgDark.withValues(alpha: 0.95)
          : AppColors.bgLight.withValues(alpha: 0.95),
      elevation: 0,
      title: const Text(
        'Community Feed',
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref,
      FeedState feedState, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: (isDark ? AppColors.bgDark : AppColors.bgLight)
              .withValues(alpha: 0.7),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CyberChip(
                  label: 'All',
                  isSelected: feedState.filterType == null,
                  onTap: () => ref
                      .read(communityFeedProvider.notifier)
                      .setFilter(null),
                ),
                const SizedBox(width: 8),
                _CyberChip(
                  label: 'Messages',
                  isSelected: feedState.filterType == 'message',
                  onTap: () => ref
                      .read(communityFeedProvider.notifier)
                      .setFilter('message'),
                ),
                const SizedBox(width: 8),
                _CyberChip(
                  label: 'Numbers',
                  isSelected: feedState.filterType == 'number',
                  onTap: () => ref
                      .read(communityFeedProvider.notifier)
                      .setFilter('number'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cyber Filter Chip ─────────────────────────────────────────────────────────
class _CyberChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CyberChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.08),
              border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.2), width: 2),
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 38, color: AppColors.cyan),
          ).animate().scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'No reports yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 6),
          Text(
            'Community reports will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
