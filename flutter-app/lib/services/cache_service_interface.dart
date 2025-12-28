import '../models/voter.dart';
import '../models/cut_list.dart';
import '../models/contact_entry.dart';

/// Cache metadata for permission-aware caching
class CacheMeta {
  final DateTime? cacheTime;
  final String? userId;
  final String? fetchMode; // 'all' or 'assigned'

  const CacheMeta({this.cacheTime, this.userId, this.fetchMode});

  bool get isEmpty => cacheTime == null;
}

/// Abstract interface for cache service.
/// Has mobile (SQLite) and web (no-op) implementations.
abstract class CacheServiceInterface {
  Future<void> initialize();

  // Voter caching
  Future<void> cacheVoters(List<Voter> voters);
  Future<void> cacheVotersWithMeta(List<Voter> voters, {required String userId, required String fetchMode});
  Future<List<Voter>> getCachedVoters();
  Future<List<Voter>> getCachedVotersForCutList(String cutListId);
  Future<DateTime?> getVotersCacheTime();
  Future<CacheMeta> getVotersCacheMeta();

  // Cut list caching
  Future<void> cacheCutLists(List<CutList> cutLists);
  Future<List<CutList>> getCachedCutLists();
  Future<void> cacheCutListVoters(String cutListId, List<String> voterUniqueIds);

  // Clear cache
  Future<void> clearAllCache();
  Future<void> clearVoterCache();

  // Pending updates (offline sync queue)
  Future<void> addPendingVoterUpdate(PendingVoterUpdateData update);
  Future<List<PendingVoterUpdateData>> getPendingUpdates();
  Future<int> getPendingUpdateCount();
  Future<void> deletePendingUpdate(int id);
  Future<void> updateCachedVoterData(String uniqueId, PendingVoterUpdateData data);

  /// Update cached voter with data from server (for two-way sync)
  Future<void> updateCachedVoterFromServer(Voter voter);

  // Contact history caching
  Future<void> cacheContactHistory(String uniqueId, List<ContactEntry> entries);
  Future<List<ContactEntry>> getCachedContactHistory(String uniqueId);
  Future<void> addPendingContactEntry(ContactEntry entry);
  Future<List<ContactEntry>> getPendingContactEntries();
  Future<void> markContactEntrySynced(String uniqueId, DateTime contactedAt, String serverId);
  Future<void> deletePendingContactEntry(String uniqueId, DateTime contactedAt);

  /// Returns true if caching is available on this platform
  bool get isAvailable;
}

/// Data class for pending voter updates (platform-agnostic)
class PendingVoterUpdateData {
  final int id;
  final String uniqueId;
  final String canvassResult;
  final String? canvassNotes;
  final DateTime canvassDate;
  final int contactAttempts;
  final DateTime? lastContactAttempt;
  final String? lastContactMethod;
  final bool voicemailLeft;

  const PendingVoterUpdateData({
    this.id = 0,
    required this.uniqueId,
    required this.canvassResult,
    this.canvassNotes,
    required this.canvassDate,
    this.contactAttempts = 0,
    this.lastContactAttempt,
    this.lastContactMethod,
    this.voicemailLeft = false,
  });
}
