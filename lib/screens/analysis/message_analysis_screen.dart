import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
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

  Color get _scoreColor {
    if (widget.scamScore < 30) return const Color(0xFF00D97E);
    if (widget.scamScore < 60) return const Color(0xFFFFB020);
    return AppColors.errorRed;
  }

  String get _threatLabel {
    if (widget.scamScore < 30) return 'LOW RISK';
    if (widget.scamScore < 60) return 'MEDIUM RISK';
    return 'HIGH RISK';
  }

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
          const SnackBar(
            content: Text('Message reported to the community!'),
            backgroundColor: AppColors.cyan,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to report. Please try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(context, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildThreatBanner(context, isDark),
            const SizedBox(height: 24),
            Center(child: ScamScoreGauge(score: widget.scamScore))
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 28),
            _buildMessageCard(context, isDark),
            const SizedBox(height: 20),
            if (widget.reasons.isNotEmpty) ...[
              _buildReasonsCard(context, isDark),
              const SizedBox(height: 20),
            ],
            _buildActionSection(context, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.bgDark.withValues(alpha: 0.95)
          : AppColors.bgLight.withValues(alpha: 0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.cyan,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Analysis Result',
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

  Widget _buildThreatBanner(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor.withValues(alpha: isDark ? 0.18 : 0.1),
            _scoreColor.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _scoreColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              widget.scamScore >= 60
                  ? Icons.gpp_bad_outlined
                  : widget.scamScore >= 30
                  ? Icons.gpp_maybe_outlined
                  : Icons.verified_user_outlined,
              color: _scoreColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _threatLabel,
                style: TextStyle(
                  color: _scoreColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
              ),
              Text(
                'Threat score: ${widget.scamScore}/100',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.08);
  }

  Widget _buildMessageCard(BuildContext context, bool isDark) {
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.message_outlined,
                    color: AppColors.cyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzed Message',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Text(
                  widget.messageText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimary.withValues(alpha: 0.85)
                        : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildReasonsCard(BuildContext context, bool isDark) {
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
            border: Border.all(color: _scoreColor.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _scoreColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detection Indicators',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.reasons.asMap().entries.map((entry) {
                  return _ReasonChip(
                    reason: entry.value,
                    color: _scoreColor,
                    delay: 400 + entry.key * 60,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildActionSection(BuildContext context, bool isDark) {
    if (_isReported) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00D97E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00D97E).withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00D97E), size: 22),
            SizedBox(width: 10),
            Text(
              'Reported to community',
              style: TextStyle(
                color: Color(0xFF00D97E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.scamScore >= 30)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.errorRed.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isReporting ? null : _reportMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              icon: _isReporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.flag_outlined, size: 18),
              label: Text(
                _isReporting ? 'Reporting...' : 'Report This Message',
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Analyze Another Message'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.cyan,
            side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
          ),
        ).animate().fadeIn(delay: 580.ms),
      ],
    );
  }
}

// ── Reason Chip ───────────────────────────────────────────────────────────────
class _ReasonChip extends StatelessWidget {
  final String reason;
  final Color color;
  final int delay;
  const _ReasonChip({
    required this.reason,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 300.ms,
        )
        .scale(begin: const Offset(0.85, 0.85));
  }
}
