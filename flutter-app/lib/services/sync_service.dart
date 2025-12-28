import 'dart:async';
import '../models/voter.dart';
import 'supabase_service.dart';
import 'cache_service.dart';

/// Handles offline sync with periodic retries
class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _pendingCount = 0;

  /// Number of pending updates waiting to sync
  int get pendingCount => _pendingCount;

  /// Start periodic sync (call on app startup)
  void startPeriodicSync() {
    // Sync every 5 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingUpdates();
    });

    // Also sync immediately on start
    syncPendingUpdates();
  }

  /// Stop periodic sync (call on app shutdown)
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Queue a voter update for offline sync
  Future<void> queueVoterUpdate(Voter voter) async {
    final cache = CacheService.instance;
    if (!cache.isAvailable) return;

    final updateData = PendingVoterUpdateData(
      uniqueId: voter.uniqueId,
      canvassResult: voter.canvassResult.displayName,
      canvassNotes: voter.canvassNotes.isEmpty ? null : voter.canvassNotes,
      canvassDate: voter.canvassDate ?? DateTime.now(),
      contactAttempts: voter.contactAttempts,
      lastContactAttempt: voter.lastContactAttempt,
      lastContactMethod: voter.lastContactMethod?.displayName,
      voicemailLeft: voter.voicemailLeft,
    );

    // Add to pending queue
    await cache.addPendingVoterUpdate(updateData);

    // Also update the local cache so changes persist
    await cache.updateCachedVoterData(voter.uniqueId, updateData);

    _pendingCount = await cache.getPendingUpdateCount();
    print('[SyncService] Queued update for ${voter.uniqueId}, pending: $_pendingCount');
  }

  /// Try to sync all pending updates
  Future<int> syncPendingUpdates() async {
    if (_isSyncing) return 0;

    final cache = CacheService.instance;
    if (!cache.isAvailable) return 0;

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;
    const maxRetries = 3;
    const timeout = Duration(seconds: 10);

    try {
      final pending = await cache.getPendingUpdates();
      _pendingCount = pending.length;

      if (pending.isEmpty) {
        print('[SyncService] No pending updates to sync');
        return 0;
      }

      print('[SyncService] Attempting to sync ${pending.length} pending updates');

      final supabase = SupabaseService.instance;
      if (!supabase.isAuthenticated || supabase.isDemoMode) {
        print('[SyncService] Not authenticated or in demo mode, skipping sync');
        return 0;
      }

      for (final update in pending) {
        if (failedCount >= maxRetries) {
          print('[SyncService] Too many failures, stopping sync early');
          break;
        }

        try {
          // Try to sync to cloud with timeout
          await supabase.saveCanvassResult(
            uniqueId: update.uniqueId,
            result: update.canvassResult,
            notes: update.canvassNotes,
          ).timeout(timeout, onTimeout: () {
            throw TimeoutException('Sync timed out for ${update.uniqueId}');
          });

          // If successful, remove from pending queue
          await cache.deletePendingUpdate(update.id);
          syncedCount++;
          failedCount = 0; // Reset fail counter on success
          print('[SyncService] Synced ${update.uniqueId}');

          // Two-way sync: fetch latest from server and update local cache
          try {
            final serverVoter = await supabase.fetchVoterByUniqueId(update.uniqueId)
                .timeout(timeout);
            if (serverVoter != null) {
              await cache.updateCachedVoterFromServer(serverVoter);
              print('[SyncService] Updated local cache with server data for ${update.uniqueId}');
            }
          } catch (e) {
            // Non-critical - local cache update failed but sync succeeded
            print('[SyncService] Failed to update local cache from server: $e');
          }
        } catch (e) {
          // Failed to sync this one, leave it in queue for next retry
          failedCount++;
          print('[SyncService] Failed to sync ${update.uniqueId}: $e');
        }
      }

      _pendingCount = await cache.getPendingUpdateCount();
      print('[SyncService] Synced $syncedCount updates, $_pendingCount remaining');
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Get count of pending updates
  Future<int> refreshPendingCount() async {
    final cache = CacheService.instance;
    if (!cache.isAvailable) return 0;

    _pendingCount = await cache.getPendingUpdateCount();
    return _pendingCount;
  }
}
