import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/particle_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final seen = await ref.read(onboardingSeenProvider.future);
    if (!mounted) return;
    if (!seen) {
      context.go('/onboarding');
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: ParticleBackground(
        particleCount: 50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildTagline(),
              const SizedBox(height: 64),
              _buildLoader(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, anim) {
        final p = _pulseController.value;
        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgDark,
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3 + p * 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.15 + p * 0.2),
                blurRadius: 30 + p * 20,
                spreadRadius: 4 + p * 6,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.radar,
              size: 54,
              color: AppColors.cyan.withValues(alpha: 0.8 + p * 0.2),
            ),
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          curve: Curves.elasticOut,
          duration: 1000.ms,
        )
        .fadeIn(duration: 600.ms);
  }

  Widget _buildTitle() {
    return const Text(
      'SCAM RADAR',
      style: TextStyle(
        color: AppColors.cyan,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, delay: 400.ms);
  }

  Widget _buildTagline() {
    return const Text(
      'Protecting Sri Lanka from digital fraud',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 600.ms);
  }

  Widget _buildLoader() {
    return SizedBox(
      width: 130,
      child: LinearProgressIndicator(
        backgroundColor: AppColors.cyan.withValues(alpha: 0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
        borderRadius: BorderRadius.circular(4),
      ),
    ).animate().fadeIn(delay: 900.ms);
  }
}
