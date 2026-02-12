import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'media_provider.dart';

enum SyncStatus { idle, syncing, error, success }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage,
    );
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;
    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    try {
      await ref.read(mediaProvider.notifier).forceSync();
      state = SyncState(
        status: SyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );

      // Reset to idle after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (state.status == SyncStatus.success) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
