import '../models/voter.dart';
import '../models/cut_list.dart';
import '../models/contact_entry.dart';
import 'cache_service_interface.dart';
export 'cache_service_interface.dart' show CacheMeta, PendingVoterUpdateData;

// Conditional imports based on platform
import 'cache_service_stub.dart'
    if (dart.library.io) 'cache_service_mobile.dart'
    if (dart.library.html) 'cache_service_web.dart';

/// Platform-aware cache service.
/// Uses SQLite on mobile, no-op on web.
class CacheService implements CacheServiceInterface {
  static final CacheService _instance = CacheService._internal();
  static CacheService get instance => _instance;
  factory CacheService() => _instance;
  CacheService._internal() : _delegate = createCacheService();

  final CacheServiceInterface _delegate;

  @override
  bool get isAvailable => _delegate.isAvailable;

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<void> cacheVoters(List<Voter> voters) => _delegate.cacheVoters(voters);

  @override
  Future<List<Voter>> getCachedVoters() => _delegate.getCachedVoters();

  @override
  Future<List<Voter>> getCachedVotersForCutList(String cutListId) =>
      _delegate.getCachedVotersForCutList(cutListId);

  @override
  Future<DateTime?> getVotersCacheTime() => _delegate.getVotersCacheTime();

  @override
  Future<void> cacheVotersWithMeta(List<Voter> voters, {required String userId, required String fetchMode}) =>
      _delegate.cacheVotersWithMeta(voters, userId: userId, fetchMode: fetchMode);

  @override
  Future<CacheMeta> getVotersCacheMeta() => _delegate.getVotersCacheMeta();

  @override
  Future<void> cacheCutLists(List<CutList> cutLists) =>
      _delegate.cacheCutLists(cutLists);

  @override
  Future<List<CutList>> getCachedCutLists() => _delegate.getCachedCutLists();

  @override
  Future<void> cacheCutListVoters(String cutListId, List<String> voterUniqueIds) =>
      _delegate.cacheCutListVoters(cutListId, voterUniqueIds);

  @override
  Future<void> clearAllCache() => _delegate.clearAllCache();

  @override
  Future<void> clearVoterCache() => _delegate.clearVoterCache();

  // Pending updates (offline sync queue)
  @override
  Future<void> addPendingVoterUpdate(PendingVoterUpdateData update) =>
      _delegate.addPendingVoterUpdate(update);

  @override
  Future<List<PendingVoterUpdateData>> getPendingUpdates() =>
      _delegate.getPendingUpdates();

  @override
  Future<int> getPendingUpdateCount() => _delegate.getPendingUpdateCount();

  @override
  Future<void> deletePendingUpdate(int id) => _delegate.deletePendingUpdate(id);

  @override
  Future<void> updateCachedVoterData(String uniqueId, PendingVoterUpdateData data) =>
      _delegate.updateCachedVoterData(uniqueId, data);

  @override
  Future<void> updateCachedVoterFromServer(Voter voter) =>
      _delegate.updateCachedVoterFromServer(voter);

  // Contact history methods
  @override
  Future<void> cacheContactHistory(String uniqueId, List<ContactEntry> entries) =>
      _delegate.cacheContactHistory(uniqueId, entries);

  @override
  Future<List<ContactEntry>> getCachedContactHistory(String uniqueId) =>
      _delegate.getCachedContactHistory(uniqueId);

  @override
  Future<void> addPendingContactEntry(ContactEntry entry) =>
      _delegate.addPendingContactEntry(entry);

  @override
  Future<List<ContactEntry>> getPendingContactEntries() =>
      _delegate.getPendingContactEntries();

  @override
  Future<void> markContactEntrySynced(String uniqueId, DateTime contactedAt, String serverId) =>
      _delegate.markContactEntrySynced(uniqueId, contactedAt, serverId);

  @override
  Future<void> deletePendingContactEntry(String uniqueId, DateTime contactedAt) =>
      _delegate.deletePendingContactEntry(uniqueId, contactedAt);
}
