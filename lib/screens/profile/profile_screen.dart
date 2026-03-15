import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scam_messages_provider.dart'
    show databaseServiceProvider;
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final name = authState.user?.userMetadata?['name'] as String? ?? 'User';
    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(context, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvatarSection(context, name, email, isDark),
            const SizedBox(height: 24),
            _buildStatsSection(context, ref, isDark),
            const SizedBox(height: 24),
            _buildSettingsCard(context, ref, isDark),
            const SizedBox(height: 24),
            _buildSignOutButton(context, ref),
            const SizedBox(height: 24),
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
      title: const Text(
        'Profile',
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

  Widget _buildAvatarSection(
    BuildContext context,
    String name,
    String email,
    bool isDark,
  ) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.bgDark.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStatsSection(BuildContext context, WidgetRef ref, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(databaseServiceProvider).getScamStats(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          );
        }
        final data = snap.data;
        final analyzed = data?['total_messages_analyzed'] ?? 0;
        final reported = data?['total_numbers_reported'] ?? 0;
        final highRisk = data?['high_risk_messages'] ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR ACTIVITY',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.search,
                    value: '$analyzed',
                    label: 'Analysed',
                    color: AppColors.cyan,
                    isDark: isDark,
                    delay: 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.flag,
                    value: '$reported',
                    label: 'Reported',
                    color: AppColors.blue,
                    isDark: isDark,
                    delay: 80,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning_amber_rounded,
                    value: '$highRisk',
                    label: 'High Risk',
                    color: AppColors.errorRed,
                    isDark: isDark,
                    delay: 160,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref, bool isDark) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _settingTile(
                context,
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.blue,
                label: 'Dark Mode',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                  activeThumbColor: AppColors.cyan,
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.cyan.withValues(alpha: 0.07),
                indent: 18,
                endIndent: 18,
              ),
              _settingTile(
                context,
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFFB020),
                label: 'Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.cyan,
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.cyan.withValues(alpha: 0.07),
                indent: 18,
                endIndent: 18,
              ),
              _settingTile(
                context,
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF00D97E),
                label: 'Privacy',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmSignOut(context, ref),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Sign Out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.errorRed,
        side: const BorderSide(color: AppColors.errorRed, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cardDark : Colors.white).withValues(
                  alpha: isDark ? 0.55 : 0.85,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + delay))
        .scale(
          begin: const Offset(0.85, 0.85),
          curve: Curves.elasticOut,
          duration: 600.ms,
        );
  }
}
