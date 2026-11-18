import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/prefs_repository_impl.dart';
import '../../domain/repositories/prefs_repository.dart';

/// Wiring DI untuk fitur settings.

final prefsRepositoryProvider = Provider<PrefsRepository>((ref) {
  return PrefsRepositoryImpl();
});

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}
