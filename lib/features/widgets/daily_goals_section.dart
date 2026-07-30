import 'package:flutter/material.dart';
// import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'dart:math' as math;
import 'package:upgrade/services/daily_goals_service.dart';

class DailyGoalsSection extends StatefulWidget {
  const DailyGoalsSection({super.key});

  @override
  State<DailyGoalsSection> createState() => _DailyGoalsSectionState();
}

class _DailyGoalsSectionState extends State<DailyGoalsSection> {
  @override
  void initState() {
    super.initState();
    // Refresh data when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get real progress data
    final waterProgress = DailyGoalsService.getWaterProgress();
    final waterProgressString = DailyGoalsService.getWaterProgressString();

    final stepsProgress = DailyGoalsService.getStepsProgress();
    final stepsProgressString = DailyGoalsService.getStepsProgressString();

    final workoutProgress = DailyGoalsService.getWorkoutProgress();
    final workoutProgressString = DailyGoalsService.getWorkoutProgressString();

    final caloriesProgress = DailyGoalsService.getCaloriesProgress();
    final caloriesProgressString =
        DailyGoalsService.getCaloriesProgressString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Daily Goals",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
                tooltip: 'Refresh goals',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD6E8FF), Color(0xFFEFF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Main Goals (2x2 Grid)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GoalCircle(
                            progress: waterProgress,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.water_drop,
                            iconColor: Colors.blue,
                            label: "Water",
                            sublabel: waterProgressString,
                          ),
                          GoalCircle(
                            progress: stepsProgress,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.directions_walk,
                            iconColor: Colors.green,
                            label: "Steps",
                            sublabel: stepsProgressString,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GoalCircle(
                            progress: workoutProgress,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBA68C8), Color(0xFF8E24AA)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.fitness_center,
                            iconColor: Colors.purple,
                            label: "Workout",
                            sublabel: workoutProgressString,
                          ),
                          GoalCircle(
                            progress: caloriesProgress,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.local_fire_department,
                            iconColor: Colors.orange,
                            label: "Calories",
                            sublabel: caloriesProgressString,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Components ====================
class GoalCircle extends StatelessWidget {
  final double progress;
  final LinearGradient gradient;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const GoalCircle({
    super.key,
    required this.progress,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(80, 80),
                painter: CirclePainter(progress: progress, gradient: gradient),
              ),
              Icon(icon, color: iconColor, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
      ],
    );
  }
}

class CaloriesGoal extends StatelessWidget {
  final double progress;
  final LinearGradient gradient;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String current;
  final String target;
  final String unit;

  const CaloriesGoal({
    super.key,
    required this.progress,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // Semi-circular progress
          SizedBox(
            width: 100,
            height: 60,
            child: CustomPaint(
              painter: ArcProgressPainter(
                progress: progress,
                gradient: gradient,
                strokeWidth: 8,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      "${(progress * 100).round()}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: current,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF2C2C2C),
                    ),
                    children: [
                      TextSpan(
                        text: " / $target $unit",
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Great progress today! 🔥",
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArcProgressPainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;
  final double strokeWidth;

  ArcProgressPainter({
    required this.progress,
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = (size.width / 2) - strokeWidth;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Progress arc
    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background arc (180 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Draw progress arc
    final sweepAngle = math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ArcProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class CirclePainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;

  CirclePainter({required this.progress, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ),
      )
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final double radius = size.width / 2 - 4;
    final Offset center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, basePaint);

    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
