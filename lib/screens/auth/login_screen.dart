import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/particle_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: ParticleBackground(
        particleCount: isDark ? 45 : 25,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated Radar Logo ──
                  _RadarLogo(controller: _radarController),
                  const SizedBox(height: 20),

                  Text(
                    'Scam Radar',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                          letterSpacing: 1.5,
                        ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                  const SizedBox(height: 6),
                  Text(
                    'Detect & report scams in Sri Lanka',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 40),

                  // ── Glassmorphism Card ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.cardDark : Colors.white)
                              .withValues(alpha: isDark ? 0.6 : 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.18),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ).animate().fadeIn(delay: 300.ms),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to your account',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ).animate().fadeIn(delay: 400.ms),
                              const SizedBox(height: 24),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: Validators.password,
                                onFieldSubmitted: (_) => _signIn(),
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                              const SizedBox(height: 28),

                              // Sign In Button
                              _GlowButton(
                                onPressed: _isLoading ? null : _signIn,
                                isLoading: _isLoading,
                                label: 'Sign In',
                              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms).scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Radar Logo ────────────────────────────────────────────────────────
class _RadarLogo extends StatelessWidget {
  final AnimationController controller;
  const _RadarLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          painter: _RadarPainter(controller.value),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut);
  }
}

class _RadarPainter extends CustomPainter {
  final double sweep; // 0..1

  _RadarPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const cyan = AppColors.cyan;

    // Concentric rings
    final ringPaint = Paint()
      ..color = cyan.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }

    // Crosshair
    final crossPaint = Paint()
      ..color = cyan.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Sweep arc (gradient fill)
    final sweepAngle = -3.14 / 2 + sweep * 2 * 3.14159;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 1.0,
        endAngle: sweepAngle,
        colors: [Colors.transparent, cyan.withValues(alpha: 0.5)],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 1.0,
      1.0,
      true,
      sweepPaint,
    );

    // Sweep line
    final linePaint = Paint()
      ..color = cyan
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * cos(sweepAngle),
        center.dy + radius * sin(sweepAngle),
      ),
      linePaint,
    );

    // Outer border
    final borderPaint = Paint()
      ..color = cyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Blip dots
    final dotPaint = Paint()..color = cyan;
    canvas.drawCircle(center + Offset(radius * 0.35, -radius * 0.2), 3, dotPaint);
    canvas.drawCircle(center + Offset(-radius * 0.5, radius * 0.3), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.sweep != sweep;
}

// ── Glowing Submit Button ──────────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GlowButton({required this.onPressed, required this.isLoading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.bgDark),
                ),
              )
            : Text(label),
      ),
    );
  }
}
