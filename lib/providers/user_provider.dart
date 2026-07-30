import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:upgrade/models/user_profile.dart';
import 'package:upgrade/services/user_data_service.dart';

final userProfileProvider = StateProvider<UserNotifier>(
  (ref) => UserNotifier(),
);

class UserNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final user = UserDataService.getCurrentUser();

    return user;
  }
}
