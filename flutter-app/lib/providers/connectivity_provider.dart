import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

class ConnectivityState {
  final bool isOnline;
  final int pendingUpdates;
  final String? lastError;
  final DateTime? lastSuccessfulSync;

  const ConnectivityState({
    this.isOnline = true,
    this.pendingUpdates = 0,
    this.lastError,
    this.lastSuccessfulSync,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    int? pendingUpdates,
    String? lastError,
    DateTime? lastSuccessfulSync,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      pendingUpdates: pendingUpdates ?? this.pendingUpdates,
      lastError: lastError,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
    );
  }
}

class ConnectivityNotifier extends Notifier<ConnectivityState> {
  Timer? _refreshTimer;

  @override
  ConnectivityState build() {
    _startMonitoring();
    return const ConnectivityState();
  }

  void _startMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshPendingCount();
    });
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final sync = SyncService.instance;
    final count = await sync.refreshPendingCount();
    state = state.copyWith(pendingUpdates: count);
  }

  void setOnline(bool online) {
    state = state.copyWith(
      isOnline: online,
      lastError: online ? null : state.lastError,
    );
  }

  void setOffline(String? error) {
    state = state.copyWith(
      isOnline: false,
      lastError: error,
    );
  }

  void setOnlineSuccess() {
    state = state.copyWith(
      isOnline: true,
      lastError: null,
      lastSuccessfulSync: DateTime.now(),
    );
  }

  void updatePendingCount(int count) {
    state = state.copyWith(pendingUpdates: count);
  }

  void dispose() {
    _refreshTimer?.cancel();
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityState>(() {
  return ConnectivityNotifier();
});
