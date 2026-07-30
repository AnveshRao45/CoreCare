import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/health_vitals.dart';
import '../services/health_service.dart';

/// Tracks whether health permissions have been granted.
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

/// Provides the current health vitals data from wearables.
final healthVitalsProvider =
    AsyncNotifierProvider<HealthVitalsNotifier, HealthVitals>(
  () => HealthVitalsNotifier(),
);

/// Async notifier that fetches and caches wearable health data.
class HealthVitalsNotifier extends AsyncNotifier<HealthVitals> {
  static final _log = Logger('HealthVitalsNotifier');

  @override
  Future<HealthVitals> build() async {
    // Check if we have permissions on init
    final hasPerms = await HealthService.hasPermissions();
    ref.read(healthPermissionProvider.notifier).update(hasPerms);

    if (hasPerms) {
      return _fetchVitals();
    }

    _log.info('🔐 Health permissions not granted, returning empty vitals');
    return HealthVitals.empty();
  }

  /// Request health data permissions from the user.
  Future<bool> requestPermissions() async {
    try {
      final granted = await HealthService.requestPermissions();
      ref.read(healthPermissionProvider.notifier).update(granted);

      if (granted) {
        _log.info('✅ Permissions granted, fetching vitals...');
        state = const AsyncValue.loading();
        final vitals = await _fetchVitals();
        state = AsyncValue.data(vitals);
      } else {
        _log.info('❌ Permissions denied by user');
      }

      return granted;
    } catch (e, st) {
      _log.severe('❌ Error requesting permissions: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refresh health data from wearables.
  Future<void> refresh() async {
    final hasPerms = ref.read(healthPermissionProvider);
    if (!hasPerms) {
      // Try checking again in case permissions were granted externally
      final nowHasPerms = await HealthService.hasPermissions();
      ref.read(healthPermissionProvider.notifier).update(nowHasPerms);

      if (!nowHasPerms) {
        _log.info('🔐 Cannot refresh: no permissions');
        return;
      }
    }

    state = const AsyncValue.loading();
    try {
      final vitals = await _fetchVitals();
      state = AsyncValue.data(vitals);
    } catch (e, st) {
      _log.severe('❌ Error refreshing vitals: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Add water and refresh hydration data.
  Future<void> addWater(double liters) async {
    try {
      final success = await HealthService.writeWater(liters);
      if (success) {
        _log.info('💧 Water added: ${liters}L, refreshing...');
        // Update optimistically
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              hydrationLiters: current.hydrationLiters + liters,
              lastSyncTime: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      _log.severe('❌ Error adding water: $e');
    }
  }

  /// Internal method to fetch all vitals from the health service.
  Future<HealthVitals> _fetchVitals() async {
    try {
      final vitals = await HealthService.fetchAllVitals();
      _log.info('📊 Vitals loaded: '
          'steps=${vitals.steps}, '
          'hr=${vitals.heartRate.toStringAsFixed(0)}, '
          'cal=${vitals.caloriesBurned}, '
          'sleep=${vitals.sleepFormatted}, '
          'water=${vitals.hydrationLiters.toStringAsFixed(2)}L');
      return vitals;
    } catch (e) {
      _log.severe('❌ Error fetching vitals: $e');
      return HealthVitals.empty();
    }
  }
}
