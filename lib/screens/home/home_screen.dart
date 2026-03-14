import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/scam_messages_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/scam_card.dart';
import '../../widgets/screenshot_scanner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _analyzeMessage() {
    if (!_formKey.currentState!.validate()) return;

    final text = _messageController.text.trim();
    ref.read(scamMessagesProvider.notifier).analyzeMessage(text);

    final state = ref.read(scamMessagesProvider);
    if (state.status == AnalysisStatus.result && state.result != null) {
      context.push('/analysis', extra: {
        'messageText': text,
        'scamScore': state.result!.score,
        'reasons': state.result!.reasons,
      });
    }
  }

  void _openScreenshotScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ScreenshotScanner(
        onTextExtracted: (text) {
          _messageController.text = text;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Scam Radar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(communityFeedProvider.notifier).loadReports(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Message Analysis Section ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Check a Suspicious Message',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paste a message below to analyze it for scam indicators',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 3,
                          validator: Validators.message,
                          decoration: const InputDecoration(
                            hintText:
                                'Paste a suspicious message here...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _analyzeMessage,
                          icon: const Icon(Icons.search),
                          label: const Text('Analyze Message'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _openScreenshotScanner,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Scan Screenshot'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Quick Actions ──
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.phone_outlined,
                      label: 'Report\nNumber',
                      color: colorScheme.tertiary,
                      onTap: () => context.push('/report-number'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.feed_outlined,
                      label: 'Community\nFeed',
                      color: colorScheme.secondary,
                      onTap: () => context.go('/feed'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.map_outlined,
                      label: 'Scam\nMap',
                      color: colorScheme.error,
                      onTap: () => context.go('/map'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Scams Section ──
              Row(
                children: [
                  Text(
                    'Recent Scam Reports',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/feed'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (feedState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (feedState.reports.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 48,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scam reports yet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to report a scam!',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...feedState.reports.take(5).map((report) => ScamCard(
                      report: report,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
