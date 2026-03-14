import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/scam_messages_provider.dart';
import '../../widgets/scam_score_gauge.dart';

class MessageAnalysisScreen extends ConsumerStatefulWidget {
  final String messageText;
  final int scamScore;
  final List<String> reasons;

  const MessageAnalysisScreen({
    super.key,
    required this.messageText,
    required this.scamScore,
    required this.reasons,
  });

  @override
  ConsumerState<MessageAnalysisScreen> createState() =>
      _MessageAnalysisScreenState();
}

class _MessageAnalysisScreenState extends ConsumerState<MessageAnalysisScreen> {
  bool _isReporting = false;
  bool _isReported = false;

  Future<void> _reportMessage() async {
    setState(() => _isReporting = true);
    try {
      await ref.read(scamMessagesProvider.notifier).reportMessage();
      if (mounted) {
        setState(() {
          _isReporting = false;
          _isReported = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message reported to the community!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to report. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _scoreColor(int score) {
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score gauge
            Center(
              child: ScamScoreGauge(score: widget.scamScore),
            ),
            const SizedBox(height: 28),

            // Original message
            Text(
              'Analyzed Message',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.messageText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reasons
            Text(
              'Detection Reasons',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.reasons.isEmpty)
              Text(
                'No specific scam indicators found.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.reasons.map((reason) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _scoreColor(widget.scamScore)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _scoreColor(widget.scamScore)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: _scoreColor(widget.scamScore),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            reason,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _scoreColor(widget.scamScore),
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            // Action buttons
            if (!_isReported)
              ElevatedButton.icon(
                onPressed: _isReporting ? null : _reportMessage,
                icon: _isReporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined),
                label: Text(
                    _isReporting ? 'Reporting...' : 'Report This Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Reported to community',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Analyze Another Message'),
            ),
          ],
        ),
      ),
    );
  }
}
