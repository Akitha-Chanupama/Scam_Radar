import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/particle_background.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please check your email to verify.',
            ),
            backgroundColor: AppColors.cyan,
          ),
        );
        context.go('/login');
      }
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
    if (error.contains('already registered')) {
      return 'This email is already registered. Try logging in.';
    }
    if (error.contains('password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    return 'Sign up failed. Please try again.';
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
                    'Join Scam Radar',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                  const SizedBox(height: 6),
                  Text(
                    'Help protect your community from scams',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 32),

                  // ── Glassmorphism Card ──
                  ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  (isDark ? AppColors.cardDark : Colors.white)
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
                                    'Create Account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ).animate().fadeIn(delay: 300.ms),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Join the community fighting scams',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ).animate().fadeIn(delay: 400.ms),
                                  const SizedBox(height: 24),

                                  // Full Name
                                  TextFormField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        validator: Validators.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 420.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 16),

                                  // Email
                                  TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        validator: Validators.email,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 470.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 16),

                                  // Password
                                  TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.next,
                                        validator: Validators.password,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(
                                            Icons.lock_outlined,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 520.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 16),

                                  // Confirm Password
                                  TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirm,
                                        textInputAction: TextInputAction.done,
                                        validator: (v) =>
                                            Validators.confirmPassword(
                                              v,
                                              _passwordController.text,
                                            ),
                                        onFieldSubmitted: (_) => _signUp(),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon: const Icon(
                                            Icons.lock_outlined,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 570.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 28),

                                  // Sign Up Button
                                  _GlowButton(
                                        onPressed: _isLoading ? null : _signUp,
                                        isLoading: _isLoading,
                                        label: 'Create Account',
                                      )
                                      .animate()
                                      .fadeIn(delay: 650.ms)
                                      .slideY(begin: 0.2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 500.ms)
                      .scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 750.ms),
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
          width: 90,
          height: 90,
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, anim) =>
                CustomPaint(painter: _RadarPainter(controller.value)),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          duration: 800.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweep;
  _RadarPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const cyan = AppColors.cyan;

    final ringPaint = Paint()
      ..color = cyan.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }

    final crossPaint = Paint()
      ..color = cyan.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      crossPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      crossPaint,
    );

    final sweepAngle = -pi / 2 + sweep * 2 * pi;
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

    final borderPaint = Paint()
      ..color = cyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    final dotPaint = Paint()..color = cyan;
    canvas.drawCircle(
      center + Offset(radius * 0.35, -radius * 0.2),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.5, radius * 0.3),
      2.5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.sweep != sweep;
}

// ── Glowing Submit Button ──────────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GlowButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

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
