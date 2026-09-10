import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backs the offline banner shown in [AppShell]. This app deliberately
/// does not queue writes for later replay while offline (spec §34 —
/// "submissions must not bypass deadlines offline", "exam submission
/// must require backend confirmation"): every write already just fails
/// with a [NetworkException] when there's no connection, which is the
/// safe behavior. This stream exists purely to tell the student *why*
/// something failed, proactively, rather than making them guess.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider).valueOrNull;
  if (result == null || result.isEmpty) return false;
  return result.every((r) => r == ConnectivityResult.none);
});
