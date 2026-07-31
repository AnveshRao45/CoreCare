import 'dart:math';
import 'dart:ui' show Offset;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ExerciseCounter {
  static const _minLikelihood = 0.55;
  static const _smoothBy = 0.35;
  static const _stableFrames = 3;
  static const _repGap = Duration(milliseconds: 750);

  int bicepCount = 0;
  int squatCount = 0;
  int pushupCount = 0;

  final _RepState _bicep = _RepState();
  final _RepState _squat = _RepState();
  final _RepState _pushup = _RepState();

  void detectBicepCurl(Pose pose) {
    final angle = _armAngle(pose);
    if (angle == null) return;
    _bicep.run(
      _smooth(_bicep.smoothed, angle),
      extendedMin: 155,
      flexedMax: 65,
      onRep: () => bicepCount++,
    );
  }

  void detectSquat(Pose pose) {
    final angle = _legAngle(pose);
    if (angle == null) return;
    _squat.run(
      _smooth(_squat.smoothed, angle),
      extendedMin: 155,
      flexedMax: 95,
      onRep: () => squatCount++,
    );
  }

  void detectPushUp(Pose pose) {
    final angle = _armAngle(pose);
    if (angle == null) return;
    _pushup.run(
      _smooth(_pushup.smoothed, angle),
      extendedMin: 150,
      flexedMax: 88,
      onRep: () => pushupCount++,
    );
  }

  double _smooth(double? prev, double next) {
    if (prev == null) return next;
    return prev + _smoothBy * (next - prev);
  }

  double? _armAngle(Pose pose) {
    final left = _chainAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final right = _chainAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    return _pickSide(left, right);
  }

  double? _legAngle(Pose pose) {
    final left = _chainAngle(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    final right = _chainAngle(
      pose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );
    return _pickSide(left, right);
  }

  _ScoredAngle? _chainAngle(
    Pose pose,
    PoseLandmarkType a,
    PoseLandmarkType b,
    PoseLandmarkType c,
  ) {
    final la = pose.landmarks[a];
    final lb = pose.landmarks[b];
    final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return null;

    final score = min(la.likelihood, min(lb.likelihood, lc.likelihood));
    if (score < _minLikelihood) return null;

    return _ScoredAngle(_angle(la, lb, lc), score);
  }

  double? _pickSide(_ScoredAngle? left, _ScoredAngle? right) {
    if (left == null) return right?.angle;
    if (right == null) return left.angle;
    return left.score >= right.score ? left.angle : right.angle;
  }

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    if (magAB == 0 || magCB == 0) return 180;

    final cosAngle = (dot / (magAB * magCB)).clamp(-1.0, 1.0);
    return acos(cosAngle) * (180 / pi);
  }
}

class _ScoredAngle {
  _ScoredAngle(this.angle, this.score);
  final double angle;
  final double score;
}

class _RepState {
  bool ready = false;
  int stable = 0;
  DateTime? lastAt;
  double? smoothed;

  void run(
    double angle, {
    required double extendedMin,
    required double flexedMax,
    required void Function() onRep,
  }) {
    smoothed = angle;

    if (angle >= extendedMin) {
      if (!ready) {
        stable++;
        if (stable >= ExerciseCounter._stableFrames) {
          ready = true;
          stable = 0;
        }
      } else {
        stable = 0;
      }
      return;
    }

    if (angle <= flexedMax && ready) {
      stable++;
      if (stable >= ExerciseCounter._stableFrames) {
        final now = DateTime.now();
        if (lastAt == null || now.difference(lastAt!) >= ExerciseCounter._repGap) {
          lastAt = now;
          onRep();
        }
        ready = false;
        stable = 0;
      }
      return;
    }

    stable = 0;
  }
}
