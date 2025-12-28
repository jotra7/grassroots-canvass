import '../models/voter.dart';
import '../models/cut_list.dart';
import '../models/contact_entry.dart';
import 'cache_service_interface.dart';
export 'cache_service_interface.dart' show CacheMeta;

/// Web implementation of CacheService.
/// This is a no-op implementation since SQLite is not available on web.
/// The app will work without offline caching on web.
class CacheServiceImpl implements CacheServiceInterface {
  static final CacheServiceImpl _instance = CacheServiceImpl._internal();
  static CacheServiceImpl get instance => _instance;
  factory CacheServiceImpl() => _instance;
  CacheServiceImpl._internal();

  @override
  bool get isAvailable => false;

  @override
  Future<void> initialize() async {
    // No-op on web
  }

  @override
  Future<void> cacheVoters(List<Voter> voters) async {
    // No-op on web
  }

  @override
  Future<List<Voter>> getCachedVoters() async {
    // No cached voters on web
    return [];
  }

  @override
  Future<List<Voter>> getCachedVotersForCutList(String cutListId) async {
    // No cached voters on web
    return [];
  }

  @override
  Future<DateTime?> getVotersCacheTime() async {
    // No cache time on web
    return null;
  }

  @override
  Future<void> cacheVotersWithMeta(List<Voter> voters, {required String userId, required String fetchMode}) async {
    // No-op on web
  }

  @override
  Future<CacheMeta> getVotersCacheMeta() async {
    // No cache meta on web
    return const CacheMeta();
  }

  @override
  Future<void> cacheCutLists(List<CutList> cutLists) async {
    // No-op on web
  }

  @override
  Future<List<CutList>> getCachedCutLists() async {
    // No cached cut lists on web
    return [];
  }

  @override
  Future<void> cacheCutListVoters(String cutListId, List<String> voterUniqueIds) async {
    // No-op on web
  }

  @override
  Future<void> clearAllCache() async {
    // No-op on web
  }

  @override
  Future<void> clearVoterCache() async {
    // No-op on web
  }

  // Pending updates - no-op on web (no offline support)
  @override
  Future<void> addPendingVoterUpdate(PendingVoterUpdateData update) async {}

  @override
  Future<List<PendingVoterUpdateData>> getPendingUpdates() async => [];

  @override
  Future<int> getPendingUpdateCount() async => 0;

  @override
  Future<void> deletePendingUpdate(int id) async {}

  @override
  Future<void> updateCachedVoterData(String uniqueId, PendingVoterUpdateData data) async {}

  @override
  Future<void> updateCachedVoterFromServer(Voter voter) async {}

  // Contact history - no-op on web (no offline support)
  @override
  Future<void> cacheContactHistory(String uniqueId, List<ContactEntry> entries) async {}

  @override
  Future<List<ContactEntry>> getCachedContactHistory(String uniqueId) async => [];

  @override
  Future<void> addPendingContactEntry(ContactEntry entry) async {}

  @override
  Future<List<ContactEntry>> getPendingContactEntries() async => [];

  @override
  Future<void> markContactEntrySynced(String uniqueId, DateTime contactedAt, String serverId) async {}

  @override
  Future<void> deletePendingContactEntry(String uniqueId, DateTime contactedAt) async {}
}

/// Factory function to create instance - used by conditional import
CacheServiceInterface createCacheService() => CacheServiceImpl.instance;
