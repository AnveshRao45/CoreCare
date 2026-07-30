/// Immutable data class holding today's health snapshot from wearables.
class HealthVitals {
  final int steps;
  final int stepGoal;

  final double heartRate; // latest bpm, 0 if unavailable
  final double heartRateAvg; // average bpm today
  final String heartRateStatus; // "Normal", "High", "Low", "N/A"

  final int caloriesBurned;
  final int caloriesGoal;

  final Duration sleepDuration;
  final Duration? sleepChange; // difference vs yesterday (positive = more)

  final double hydrationLiters;
  final double hydrationGoal;

  final int stepsChange; // delta vs yesterday (positive = more)

  final DateTime lastSyncTime;
  final bool isConnected; // health data available & permissions granted

  const HealthVitals({
    this.steps = 0,
    this.stepGoal = 10000,
    this.heartRate = 0,
    this.heartRateAvg = 0,
    this.heartRateStatus = 'N/A',
    this.caloriesBurned = 0,
    this.caloriesGoal = 2000,
    this.sleepDuration = Duration.zero,
    this.sleepChange,
    this.hydrationLiters = 0,
    this.hydrationGoal = 2.0,
    this.stepsChange = 0,
    required this.lastSyncTime,
    this.isConnected = false,
  });

  /// Default "not connected" state
  factory HealthVitals.empty() => HealthVitals(
        lastSyncTime: DateTime.now(),
        isConnected: false,
      );

  /// Progress ratios (clamped 0.0 – 1.0)
  double get stepsProgress => (steps / stepGoal).clamp(0.0, 1.0);
  double get caloriesProgress =>
      (caloriesBurned / caloriesGoal).clamp(0.0, 1.0);
  double get hydrationProgress =>
      (hydrationLiters / hydrationGoal).clamp(0.0, 1.0);

  /// Sleep formatted as "7h 45m"
  String get sleepFormatted {
    if (sleepDuration == Duration.zero) return '--';
    final hours = sleepDuration.inHours;
    final minutes = sleepDuration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Sleep change formatted as "+30min" or "-15min"
  String get sleepChangeFormatted {
    if (sleepChange == null) return '';
    final mins = sleepChange!.inMinutes;
    if (mins == 0) return 'Same as yesterday';
    final sign = mins > 0 ? '+' : '';
    return '$sign${mins}min vs yesterday';
  }

  /// Steps change formatted
  String get stepsChangeFormatted {
    if (stepsChange == 0) return '';
    final sign = stepsChange > 0 ? '+' : '';
    return '$sign$stepsChange vs yesterday';
  }

  /// Formatted steps string
  String get stepsFormatted {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(steps % 1000 == 0 ? 0 : 1)}k';
    }
    return steps.toString();
  }

  /// Copy with updated fields
  HealthVitals copyWith({
    int? steps,
    int? stepGoal,
    double? heartRate,
    double? heartRateAvg,
    String? heartRateStatus,
    int? caloriesBurned,
    int? caloriesGoal,
    Duration? sleepDuration,
    Duration? sleepChange,
    double? hydrationLiters,
    double? hydrationGoal,
    int? stepsChange,
    DateTime? lastSyncTime,
    bool? isConnected,
  }) {
    return HealthVitals(
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      heartRate: heartRate ?? this.heartRate,
      heartRateAvg: heartRateAvg ?? this.heartRateAvg,
      heartRateStatus: heartRateStatus ?? this.heartRateStatus,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      sleepChange: sleepChange ?? this.sleepChange,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      stepsChange: stepsChange ?? this.stepsChange,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
