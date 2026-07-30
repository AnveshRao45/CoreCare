import 'dart:math';
import 'dart:ui' show Offset;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ExerciseCounter {
  int bicepCount = 0;
  bool bicepDown = false;

  int squatCount = 0;
  bool squatDown = false;

  int pushupCount = 0;
  bool pushupDown = false;

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = (ab.dx * cb.dx + ab.dy * cb.dy);
    final magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);

    final angle = acos(dot / (magAB * magCB));
    return angle * (180 / pi);
  }

  void detectBicepCurl(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow]!;
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist]!;

    double angle = _angle(shoulder, elbow, wrist);

    if (angle > 160) bicepDown = true;
    if (angle < 60 && bicepDown) {
      bicepCount++;
      bicepDown = false;
    }
  }

  void detectSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final knee = pose.landmarks[PoseLandmarkType.leftKnee]!;
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle]!;

    final angle = _angle(hip, knee, ankle);

    if (angle > 160) squatDown = true;
    if (angle < 100 && squatDown) {
      squatCount++;
      squatDown = false;
    }
  }

  void detectPushUp(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow]!;
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist]!;

    final angle = _angle(shoulder, elbow, wrist);

    if (angle > 160) pushupDown = true;
    if (angle < 85 && pushupDown) {
      pushupCount++;
      pushupDown = false;
    }
  }
}
