import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:math' as math;

import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/services/daily_goals_service.dart';
import 'package:upgrade/providers/health_provider.dart';

class ProgresssOfUSer extends ConsumerStatefulWidget {
  const ProgresssOfUSer({super.key});

  @override
  ConsumerState<ProgresssOfUSer> createState() => _ProgresssOfUSerState();
}

class _ProgresssOfUSerState extends ConsumerState<ProgresssOfUSer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Refresh data when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final waterProgress = DailyGoalsService.getWaterProgress();
    final workoutProgress = DailyGoalsService.getWorkoutProgress();
    final intakeProgress = DailyGoalsService.getCaloriesEatenProgress(user);

    final vitals = ref.watch(healthVitalsProvider).value;
    final stepsProgress = vitals != null && vitals.isConnected
        ? vitals.stepsProgress
        : DailyGoalsService.getStepsProgress();

    final overallProgress =
        (waterProgress + stepsProgress + intakeProgress + workoutProgress) /
            4.0;

    final progressColor = _getProgressColor(overallProgress);

    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow effect
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  progressColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Progress ring
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(85, 85),
                painter: CirclePainter(
                  progress: overallProgress * _animation.value,
                  gradient: LinearGradient(
                    colors: _getGradientColors(overallProgress),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  strokeWidth: 6,
                ),
              );
            },
          ),
          // Inner content
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: 0,
                        end: (overallProgress * 100).toInt(),
                      ),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '$value%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: progressColor,
                            height: 1.2,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return const Color(0xFF4CAF50); // Green
    } else if (progress >= 0.5) {
      return const Color(0xFFFF9800); // Orange
    } else if (progress >= 0.25) {
      return const Color(0xFF2196F3); // Blue
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  List<Color> _getGradientColors(double progress) {
    if (progress >= 0.8) {
      return [
        const Color(0xFF4CAF50),
        const Color(0xFF66BB6A),
        const Color(0xFF81C784),
      ];
    } else if (progress >= 0.5) {
      return [
        const Color(0xFFFF9800),
        const Color(0xFFFFB74D),
        const Color(0xFFFFCC80),
      ];
    } else if (progress >= 0.25) {
      return [
        const Color(0xFF2196F3),
        const Color(0xFF42A5F5),
        const Color(0xFF64B5F6),
      ];
    } else {
      return [
        const Color(0xFFF44336),
        const Color(0xFFE57373),
        const Color(0xFFEF5350),
      ];
    }
  }
}

class CirclePainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;
  final double strokeWidth;

  CirclePainter({
    required this.progress,
    required this.gradient,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2 - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Background circle
    final Paint basePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);

    // Progress arc with gradient
    if (progress > 0) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      final double sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

      // Add a subtle glow at the end of the progress arc
      if (progress > 0.05) {
        final Paint glowPaint = Paint()
          ..shader = gradient.createShader(rect)
          ..strokeWidth = strokeWidth + 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

        final double angle = -math.pi / 2 + sweepAngle;
        final double endX = center.dx + radius * math.cos(angle);
        final double endY = center.dy + radius * math.sin(angle);

        canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}
