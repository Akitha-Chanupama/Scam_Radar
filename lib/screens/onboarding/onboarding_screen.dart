import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/particle_background.dart';

// ── Page data ─────────────────────────────────────────────────────────────────
class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

const List<_OnboardPage> _pages = [
  _OnboardPage(
    icon: Icons.shield_outlined,
    color: AppColors.cyan,
    title: 'Detect Scams',
    subtitle:
        'Paste or scan any suspicious message.\nOur AI identifies scam patterns in seconds.',
  ),
  _OnboardPage(
    icon: Icons.flag_outlined,
    color: Color(0xFFFFB020),
    title: 'Report Numbers',
    subtitle:
        'Flag scam callers and share warnings\nwith the community to protect others.',
  ),
  _OnboardPage(
    icon: Icons.map_outlined,
    color: Color(0xFF00D97E),
    title: 'Threat Map',
    subtitle:
        'See where scams are happening across\nSri Lanka in real time.',
  ),
  _OnboardPage(
    icon: Icons.lock_outlined,
    color: AppColors.blue,
    title: 'Stay Protected',
    subtitle:
        'Join thousands of Sri Lankans defending\nagainst digital fraud every day.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(markOnboardingSeenProvider)();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _PageContent(page: _pages[index]),
                ),
              ),

              // Dot indicators
              _buildDots(),
              const SizedBox(height: 28),

              // CTA button
              _buildButton(isLast),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? AppColors.cyan
                : AppColors.textSecondary.withValues(alpha: 0.3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.45),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildButton(bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: ElevatedButton(
              key: ValueKey(isLast),
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.bgDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isLast ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page content ──────────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _OnboardPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withValues(alpha: 0.08),
              border: Border.all(
                color: page.color.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.22),
                  blurRadius: 45,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(page.icon, size: 60, color: page.color),
          )
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                curve: Curves.elasticOut,
                duration: 700.ms,
              )
              .fadeIn(),

          const SizedBox(height: 48),

          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 120.ms, duration: 500.ms)
              .slideY(begin: 0.1, delay: 120.ms),

          const SizedBox(height: 18),

          Text(
            page.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 230.ms, duration: 500.ms),
        ],
      ),
    );
  }
}
