import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/scam_messages_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/particle_background.dart';
import '../../widgets/scam_card.dart';
import '../../widgets/screenshot_scanner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _analyzeMessage() {
    if (!_formKey.currentState!.validate()) return;
    final text = _messageController.text.trim();
    ref.read(scamMessagesProvider.notifier).analyzeMessage(text);
    final state = ref.read(scamMessagesProvider);
    if (state.status == AnalysisStatus.result && state.result != null) {
      context.push(
        '/analysis',
        extra: {
          'messageText': text,
          'scamScore': state.result!.score,
          'reasons': state.result!.reasons,
        },
      );
    } else if (state.status == AnalysisStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Analysis failed. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _openScreenshotScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScreenshotScanner(
        onTextExtracted: (text) {
          _messageController.text = text;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _analyzeMessage();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(context, isDark, themeMode),
      body: ParticleBackground(
        particleCount: isDark ? 20 : 12,
        child: RefreshIndicator(
          color: AppColors.cyan,
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          onRefresh: () =>
              ref.read(communityFeedProvider.notifier).loadReports(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroBanner(context, isDark),
                const SizedBox(height: 16),
                _buildAnalysisCard(context, isDark),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentReports(context, feedState, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    ThemeMode themeMode,
  ) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.bgDark.withValues(alpha: 0.95)
          : AppColors.bgLight.withValues(alpha: 0.95),
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, anim) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(
                      alpha: 0.4 + 0.3 * _pulseController.value,
                    ),
                    blurRadius: 6 + 4 * _pulseController.value,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Scam Radar',
            style: TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggle(),
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

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blue.withValues(alpha: isDark ? 0.3 : 0.15),
                AppColors.cyan.withValues(alpha: isDark ? 0.12 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Protected',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detect and report scams in Sri Lanka',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, anim) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(
                          alpha: 0.15 + 0.1 * _pulseController.value,
                        ),
                        blurRadius: 16 + 8 * _pulseController.value,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.radar, color: AppColors.cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildAnalysisCard(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white).withValues(
              alpha: isDark ? 0.55 : 0.85,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analyze Message',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste a suspicious message to check for scam indicators',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 3,
                  validator: Validators.message,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste a suspicious message here...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                _GlowButton(
                  onPressed: _analyzeMessage,
                  icon: Icons.search,
                  label: 'Analyze Message',
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openScreenshotScanner,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Scan Screenshot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: BorderSide(
                      color: AppColors.cyan.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.phone_outlined,
            label: 'Report\nNumber',
            color: AppColors.blue,
            onTap: () => context.push('/report-number'),
            delay: 300,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.feed_outlined,
            label: 'Community\nFeed',
            color: AppColors.cyan,
            onTap: () => context.go('/feed'),
            delay: 380,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.map_outlined,
            label: 'Scam\nMap',
            color: AppColors.errorRed,
            onTap: () => context.go('/map'),
            delay: 460,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(
    BuildContext context,
    dynamic feedState,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recent Scam Reports',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/feed'),
              child: const Text(
                'See all',
                style: TextStyle(color: AppColors.cyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (feedState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          )
        else if (feedState.reports.isEmpty)
          _EmptyReportsCard(isDark: isDark)
        else
          ...feedState.reports
              .take(5)
              .map((report) => ScamCard(report: report)),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }
}

// ── Glow Button ───────────────────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GlowButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white).withValues(
              alpha: isDark ? 0.6 : 0.9,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
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
                    child: Icon(icon, color: color, size: 22),
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
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 350.ms,
        )
        .scale(
          begin: const Offset(0.92, 0.92),
          delay: Duration(milliseconds: delay),
        );
  }
}

// ── Empty Reports Card ────────────────────────────────────────────────────────
class _EmptyReportsCard extends StatelessWidget {
  final bool isDark;
  const _EmptyReportsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white).withValues(
              alpha: isDark ? 0.5 : 0.8,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 48,
                color: AppColors.cyan.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No scam reports yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to report a scam!',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
