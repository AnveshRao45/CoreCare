import 'package:flutter/material.dart';
import 'dart:math' as math;

class VitalsSection extends StatelessWidget {
  const VitalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vitals from Wearables",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 120, child: HydrationCard()),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HeartRateCard(),
              StepsCard(),
              CaloriesCard(),
              SleepCard(),
            ],
          ),
        ],
      ),
    );
  }
}

// ❤️ Heart Rate
class HeartRateCard extends StatelessWidget {
  const HeartRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFEE2E2), Color(0xFFF8D0D0)],
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFEF5350),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Heart Rate",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              text: "78 ",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
              children: [
                TextSpan(
                  text: "bpm",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Normal",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              Text(
                "Avg: 75",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🚶 Steps
class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _vitalCard(
      icon: Icons.directions_walk,
      iconColor: const Color(0xFF66BB6A),
      label: "Steps",
      mainValue: "8,000",
      subValue: "/10k",
      footer: "+500 vs yesterday",
      footerColor: Colors.green,
      progress: 0.8,
    );
  }
}

// 🔥 Calories
class CaloriesCard extends StatelessWidget {
  const CaloriesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _vitalCardWithBar(
      icon: Icons.local_fire_department,
      iconColor: const Color(0xFFFFA726),
      label: "Calories Burned",
      mainValue: "1,200",
      subValue: "/2,000",
      footer: "Great progress!",
      footerColor: Colors.amber.shade700,
      progress: 0.6,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
      ),
    );
  }
}

// 💤 Sleep
class SleepCard extends StatelessWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _vitalCardWithBar(
      icon: Icons.bedtime,
      iconColor: const Color(0xFF5C6BC0),
      label: "Sleep",
      mainValue: "7h 45m",
      subValue: "",
      footer: "+30min vs yesterday",
      footerColor: Colors.green,
      progress: 0.95,
      gradient: const LinearGradient(
        colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
      ),
    );
  }
}

// 💧 Hydration
class HydrationCard extends StatelessWidget {
  const HydrationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hydration",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text.rich(
                    TextSpan(
                      text: "1.5",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: "/2L",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Color(0xFF42A5F5), size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Icon(
                  Icons.water_drop,
                  size: 50,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.75,
                    child: const Icon(
                      Icons.water_drop,
                      size: 50,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_hydrationButton("+250ml"), _hydrationButton("+500ml")],
          ),
        ],
      ),
    );
  }

  Widget _hydrationButton(String label) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF42A5F5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- Shared Helpers ---
Widget _vitalCard({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String mainValue,
  required String subValue,
  required String footer,
  required Color footerColor,
  required double progress,
}) {
  return Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CustomPaint(
            size: const Size(60, 60),
            painter: _ProgressRingPainter(progress: progress, color: iconColor),
            child: Center(child: Icon(icon, color: iconColor, size: 18)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: mainValue,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: subValue,
                style: const TextStyle(color: Colors.grey, fontSize: 9),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          footer,
          style: TextStyle(
            fontSize: 8,
            color: footerColor,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _vitalCardWithBar({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String mainValue,
  required String subValue,
  required String footer,
  required Color footerColor,
  required double progress,
  required Gradient gradient,
}) {
  return Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: mainValue,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: subValue,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Spacer(),

        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),

        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            footer,
            style: TextStyle(
              fontSize: 10,
              color: footerColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(2, 4),
    ),
  ],
);

// --- Custom Painter for circular progress ---
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = 4.0;
    final radius = (size.width / 2) - (strokeWidth / 2);

    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    final angle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
