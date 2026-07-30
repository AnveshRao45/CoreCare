import 'package:flutter/material.dart';
import 'dart:math' as math;

class DailyGoalsSection extends StatelessWidget {
  const DailyGoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Daily Goals",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
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
                        children: const [
                          GoalCircle(
                            progress: 0.25,
                            gradient: LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.water_drop,
                            iconColor: Colors.blue,
                            label: "Water",
                            sublabel: "2/8 glasses",
                          ),
                          GoalCircle(
                            progress: 0.5,
                            gradient: LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.directions_walk,
                            iconColor: Colors.green,
                            label: "Steps",
                            sublabel: "5k/10k",
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          GoalCircle(
                            progress: 1.0,
                            gradient: LinearGradient(
                              colors: [Color(0xFFBA68C8), Color(0xFF8E24AA)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.fitness_center,
                            iconColor: Colors.purple,
                            label: "Workout",
                            sublabel: "1/1 done",
                          ),
                          GoalCircle(
                            progress: 0.9,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            icon: Icons.local_fire_department,
                            iconColor: Colors.orange,
                            label: "Calories",
                            sublabel: "1800/2000",
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white70, thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    "Nutritional Goals",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nutritional Grid
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(
                            child: NutrientGoal(
                              progress: 0.6,
                              gradient: LinearGradient(
                                colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              icon: Icons.grain,
                              iconColor: Colors.purple,
                              title: "Carbs",
                              subtitle: "150 / 250 g",
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: NutrientGoal(
                              progress: 0.75,
                              gradient: LinearGradient(
                                colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              icon: Icons.egg,
                              iconColor: Colors.teal,
                              title: "Proteins",
                              subtitle: "90 / 120 g",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(
                            child: NutrientGoal(
                              progress: 0.45,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFCA28), Color(0xFFFFA000)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              icon: Icons.oil_barrel,
                              iconColor: Colors.amber,
                              title: "Fats",
                              subtitle: "45 / 60 g",
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: NutrientGoal(
                              progress: 0.8,
                              gradient: LinearGradient(
                                colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              icon: Icons.eco,
                              iconColor: Colors.green,
                              title: "Fiber",
                              subtitle: "24 / 30 g",
                            ),
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

class NutrientGoal extends StatelessWidget {
  final double progress;
  final LinearGradient gradient;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const NutrientGoal({
    super.key,
    required this.progress,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(40, 40),
                painter: CirclePainter(progress: progress, gradient: gradient),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
      ],
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
