import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:logging/logging.dart';

import '../models/health_vitals.dart';
import '../providers/user_provider.dart';
import '../services/daily_goals_service.dart';
import '../services/health_service.dart';

final healthPermissionProvider =
    NotifierProvider<HealthPermissionNotifier, bool>(
  () => HealthPermissionNotifier(),
);

class HealthPermissionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) {
    state = value;
  }
}

final healthDiagnosisProvider =
    NotifierProvider<HealthDiagnosisNotifier, Map<String, dynamic>>(
  () => HealthDiagnosisNotifier(),
);

class HealthDiagnosisNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() => const {};

  void update(Map<String, dynamic> value) {
    state = value;
  }
}

final healthVitalsProvider =
    AsyncNotifierProvider<HealthVitalsNotifier, HealthVitals>(
  () => HealthVitalsNotifier(),
);

class HealthVitalsNotifier extends AsyncNotifier<HealthVitals> {
  static const String _tag = '[HEALTH-PROVIDER]';
  static final _log = Logger('HealthVitalsNotifier');

  void _debug(String msg) {
    _log.info(msg);
    debugPrint('$_tag $msg');
  }

  void _err(String msg, Object e, [StackTrace? st]) {
    _log.severe(msg, e, st);
    debugPrint('$_tag ERROR: $msg — $e');
  }

  @override
  Future<HealthVitals> build() async {
    _debug('Initialising HealthVitalsNotifier...');

    // 1. Make sure Health Connect is available on Android. If it's not we
    // still return an empty snapshot but log it loudly so the UI knows.
    final hcStatus = await HealthService.getSdkStatus();
    _debug('Health Connect SDK status on startup: $hcStatus');

    // 2. Check permissions and propagate to the boolean provider
    final hasPerms = await HealthService.hasPermissions();
    ref.read(healthPermissionProvider.notifier).update(hasPerms);

    // 3. Run a diagnosis so the UI / console has immediate context
    final diagnosis = await HealthService.diagnoseConnection();
    ref.read(healthDiagnosisProvider.notifier).update(diagnosis);

    if (hasPerms) {
      return _fetchVitals();
    }

    _debug('Health permissions not granted — returning empty vitals.');
    return HealthVitals.empty();
  }

  /// Returns true if Health Connect is installed and ready (Android),
  /// or true on iOS (HealthKit is always available).
  Future<bool> isHealthConnectAvailable() =>
      HealthService.isHealthConnectAvailable();

  /// Launches the Play Store so the user can install Health Connect.
  Future<void> installHealthConnect() =>
      HealthService.installHealthConnect();

  /// Request health data permissions from the user.
  Future<bool> requestPermissions() async {
    try {
      _debug('Requesting health permissions...');

      // Block early if Health Connect isn't installed on Android.
      final available = await HealthService.isHealthConnectAvailable();
      if (!available) {
        _debug('Health Connect not installed — prompting user to install.');
        return false;
      }

      final granted = await HealthService.requestPermissions();
      ref.read(healthPermissionProvider.notifier).update(granted);

      // Re-run diagnosis so the UI sees the new state.
      final diagnosis = await HealthService.diagnoseConnection();
      ref.read(healthDiagnosisProvider.notifier).update(diagnosis);

      if (granted) {
        _debug('Permissions granted — fetching vitals...');
        state = const AsyncValue.loading();
        final vitals = await _fetchVitals();
        state = AsyncValue.data(vitals);
      } else {
        _debug('Permissions denied by user.');
      }

      return granted;
    } catch (e, st) {
      _err('Error requesting permissions', e, st);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refresh health data from wearables.
  Future<void> refresh() async {
    _debug('Refreshing health vitals...');
    final hasPerms = ref.read(healthPermissionProvider);
    if (!hasPerms) {
      // Maybe permissions were granted externally (eg. user opened HC settings)
      final nowHasPerms = await HealthService.hasPermissions();
      ref.read(healthPermissionProvider.notifier).update(nowHasPerms);

      if (!nowHasPerms) {
        _debug('Cannot refresh: no permissions');
        return;
      }
    }

    state = const AsyncValue.loading();
    try {
      await HealthService.ensureExtendedAccess();
      await HealthService.ensureHeartRatePermissions();
      final diagnosis = await HealthService.diagnoseConnection();
      ref.read(healthDiagnosisProvider.notifier).update(diagnosis);

      final vitals = await _fetchVitals();
      ref
          .read(healthDiagnosisProvider.notifier)
          .update(HealthService.lastDiagnosis);
      state = AsyncValue.data(vitals);
    } catch (e, st) {
      _err('Error refreshing vitals', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Add water — saved locally first so the UI always updates; Health Connect
  /// sync is attempted in the background.
  Future<void> addWater(double liters) async {
    try {
      await DailyGoalsService.addHydrationLiters(liters);
      final totalLiters = DailyGoalsService.getHydrationLiters();
      _debug('Water added: ${liters}L (total today: ${totalLiters}L)');

      final current = state.value ?? HealthVitals.empty();
      state = AsyncValue.data(
        current.copyWith(
          hydrationLiters: totalLiters,
          lastSyncTime: DateTime.now(),
        ),
      );

      // Optional sync to Health Connect — do not block the UI on this.
      final hcOk = await HealthService.writeWater(liters);
      if (!hcOk) {
        _debug('Health Connect water write skipped or failed — local log kept.');
      }
    } catch (e, st) {
      _err('Error adding water', e, st);
    }
  }

  /// Personalised daily targets from the user profile (not hard-coded).
  HealthVitals _withUserGoals(HealthVitals vitals) {
    final user = ref.read(userProfileProvider);
    if (user == null) return vitals;

    int stepGoal = 10000;
    int calGoal = 2000;

    if (user.weight != null && user.height != null && user.age != null) {
      double bmr;
      if (user.gender?.toLowerCase() == 'male') {
        bmr = 88.362 +
            13.397 * user.weight! +
            4.799 * user.height! -
            5.677 * user.age!;
      } else {
        bmr = 447.593 +
            9.247 * user.weight! +
            3.098 * user.height! -
            4.330 * user.age!;
      }
      double factor = 1.55;
      switch (user.activityLevel?.toLowerCase()) {
        case 'sedentary':
        case 'low':
          factor = 1.2;
          break;
        case 'light':
        case 'lightly active':
          factor = 1.375;
          break;
        case 'high':
        case 'very active':
          factor = 1.725;
          break;
        case 'extremely active':
          factor = 1.9;
          break;
      }
      calGoal = (bmr * factor).round();
      stepGoal = user.activityLevel?.toLowerCase() == 'high' ||
              user.activityLevel?.toLowerCase() == 'very active'
          ? 12000
          : 10000;
    }

    final localHydration = DailyGoalsService.getHydrationLiters();
    final hydrationLiters = vitals.hydrationLiters >= localHydration
        ? vitals.hydrationLiters
        : localHydration;

    return vitals.copyWith(
      stepGoal: stepGoal,
      caloriesGoal: calGoal,
      hydrationLiters: hydrationLiters,
    );
  }

  /// Internal method to fetch all vitals from the health service.
  Future<HealthVitals> _fetchVitals() async {
    try {
      final vitals = _withUserGoals(await HealthService.fetchAllVitals());
      _debug('Vitals loaded: '
          'connected=${vitals.isConnected}, '
          'steps=${vitals.steps}, '
          'hr=${vitals.heartRate.toStringAsFixed(0)}, '
          'cal=${vitals.caloriesBurned}, '
          'sleep=${vitals.sleepFormatted}, '
          'water=${vitals.hydrationLiters.toStringAsFixed(2)}L');
      return vitals;
    } catch (e, st) {
      _err('Error fetching vitals', e, st);
      return HealthVitals.empty();
    }
  }
}

final healthConnectSdkStatusProvider =
    FutureProvider<HealthConnectSdkStatus>((ref) async {
  return HealthService.getSdkStatus();
});
