import 'dart:convert';
import 'package:drift/drift.dart';
import '../data/local_database.dart';
import '../models/voter.dart';
import '../models/cut_list.dart';
import '../models/contact_entry.dart';
import '../models/enums/canvass_result.dart';
import '../models/enums/contact_method.dart';
import 'package:latlong2/latlong.dart';
import 'cache_service_interface.dart';

/// Mobile implementation of CacheService using SQLite via Drift.
class CacheServiceImpl implements CacheServiceInterface {
  static final CacheServiceImpl _instance = CacheServiceImpl._internal();
  static CacheServiceImpl get instance => _instance;
  factory CacheServiceImpl() => _instance;
  CacheServiceImpl._internal();

  late LocalDatabase _db;
  bool _initialized = false;

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _db = LocalDatabase();
    _initialized = true;
  }

  // MARK: - Voter Caching

  @override
  Future<void> cacheVoters(List<Voter> voters) async {
    if (!_initialized) await initialize();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedVoters,
        voters.map((v) => CachedVotersCompanion(
          uniqueId: Value(v.uniqueId),
          visitorId: Value(v.visitorId),
          ownerName: Value(v.ownerName),
          firstName: Value(v.firstName),
          middleName: Value(v.middleName),
          lastName: Value(v.lastName),
          phone: Value(v.phone),
          cellPhone: Value(v.cellPhone),
          streetNum: Value(v.streetNum),
          streetDir: Value(v.streetDir),
          streetName: Value(v.streetName),
          city: Value(v.city),
          zip: Value(v.zip),
          partyDescription: Value(v.partyDescription),
          voterAge: Value(v.voterAge),
          gender: Value(v.gender),
          registrationDate: Value(v.registrationDate),
          residenceAddress: Value(v.residenceAddress),
          latitude: Value(v.latitude),
          longitude: Value(v.longitude),
          canvassResult: Value(v.canvassResult.displayName),
          canvassNotes: Value(v.canvassNotes),
          canvassDate: Value(v.canvassDate),
          contactAttempts: Value(v.contactAttempts),
          lastContactAttempt: Value(v.lastContactAttempt),
          lastContactMethod: Value(v.lastContactMethod?.displayName),
          voicemailLeft: Value(v.voicemailLeft),
          mailAddress: Value(v.mailAddress),
          mailCity: Value(v.mailCity),
          mailState: Value(v.mailState),
          mailZip: Value(v.mailZip),
          livesElsewhere: Value(v.livesElsewhere),
          isMailVoter: Value(v.isMailVoter),
          cachedAt: Value(DateTime.now()),
        )).toList(),
      );
    });

    await _db.updateSyncTime('voters');
  }

  @override
  Future<List<Voter>> getCachedVoters() async {
    if (!_initialized) await initialize();

    final rows = await _db.select(_db.cachedVoters).get();
    return rows.map((r) => _voterFromCache(r)).toList();
  }

  @override
  Future<List<Voter>> getCachedVotersForCutList(String cutListId) async {
    if (!_initialized) await initialize();

    final voterIds = await (_db.select(_db.cachedCutListVoters)
          ..where((t) => t.cutListId.equals(cutListId)))
        .get();

    if (voterIds.isEmpty) return [];

    final uniqueIds = voterIds.map((v) => v.voterUniqueId).toList();

    final rows = await (_db.select(_db.cachedVoters)
          ..where((t) => t.uniqueId.isIn(uniqueIds)))
        .get();

    return rows.map((r) => _voterFromCache(r)).toList();
  }

  Voter _voterFromCache(CachedVoter r) {
    return Voter(
      uniqueId: r.uniqueId,
      visitorId: r.visitorId ?? '',
      ownerName: r.ownerName ?? '',
      firstName: r.firstName ?? '',
      middleName: r.middleName ?? '',
      lastName: r.lastName ?? '',
      phone: r.phone ?? '',
      cellPhone: r.cellPhone ?? '',
      streetNum: r.streetNum ?? '',
      streetDir: r.streetDir ?? '',
      streetName: r.streetName ?? '',
      city: r.city ?? '',
      zip: r.zip ?? '',
      partyDescription: r.partyDescription ?? '',
      voterAge: r.voterAge,
      gender: r.gender ?? '',
      registrationDate: r.registrationDate ?? '',
      residenceAddress: r.residenceAddress ?? '',
      latitude: r.latitude,
      longitude: r.longitude,
      canvassResult: CanvassResult.fromString(r.canvassResult ?? 'Not Contacted'),
      canvassNotes: r.canvassNotes ?? '',
      canvassDate: r.canvassDate,
      contactAttempts: r.contactAttempts,
      lastContactAttempt: r.lastContactAttempt,
      lastContactMethod: ContactMethod.fromString(r.lastContactMethod),
      voicemailLeft: r.voicemailLeft,
      mailAddress: r.mailAddress ?? '',
      mailCity: r.mailCity ?? '',
      mailState: r.mailState ?? '',
      mailZip: r.mailZip ?? '',
      livesElsewhere: r.livesElsewhere,
      isMailVoter: r.isMailVoter,
    );
  }

  @override
  Future<DateTime?> getVotersCacheTime() async {
    if (!_initialized) await initialize();
    return _db.getLastSyncTime('voters');
  }

  @override
  Future<void> cacheVotersWithMeta(List<Voter> voters, {required String userId, required String fetchMode}) async {
    if (!_initialized) await initialize();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedVoters,
        voters.map((v) => CachedVotersCompanion(
          uniqueId: Value(v.uniqueId),
          visitorId: Value(v.visitorId),
          ownerName: Value(v.ownerName),
          firstName: Value(v.firstName),
          middleName: Value(v.middleName),
          lastName: Value(v.lastName),
          phone: Value(v.phone),
          cellPhone: Value(v.cellPhone),
          streetNum: Value(v.streetNum),
          streetDir: Value(v.streetDir),
          streetName: Value(v.streetName),
          city: Value(v.city),
          zip: Value(v.zip),
          partyDescription: Value(v.partyDescription),
          voterAge: Value(v.voterAge),
          gender: Value(v.gender),
          registrationDate: Value(v.registrationDate),
          residenceAddress: Value(v.residenceAddress),
          latitude: Value(v.latitude),
          longitude: Value(v.longitude),
          canvassResult: Value(v.canvassResult.displayName),
          canvassNotes: Value(v.canvassNotes),
          canvassDate: Value(v.canvassDate),
          contactAttempts: Value(v.contactAttempts),
          lastContactAttempt: Value(v.lastContactAttempt),
          lastContactMethod: Value(v.lastContactMethod?.displayName),
          voicemailLeft: Value(v.voicemailLeft),
          mailAddress: Value(v.mailAddress),
          mailCity: Value(v.mailCity),
          mailState: Value(v.mailState),
          mailZip: Value(v.mailZip),
          livesElsewhere: Value(v.livesElsewhere),
          isMailVoter: Value(v.isMailVoter),
          cachedAt: Value(DateTime.now()),
        )).toList(),
      );
    });

    await _db.updateSyncTimeWithMeta('voters', userId, fetchMode);
  }

  @override
  Future<CacheMeta> getVotersCacheMeta() async {
    if (!_initialized) await initialize();
    final syncMeta = await _db.getSyncMeta('voters');
    if (syncMeta == null) {
      return const CacheMeta();
    }
    return CacheMeta(
      cacheTime: syncMeta.lastSyncAt,
      userId: syncMeta.userId,
      fetchMode: syncMeta.fetchMode,
    );
  }

  // MARK: - Cut List Caching

  @override
  Future<void> cacheCutLists(List<CutList> cutLists) async {
    if (!_initialized) await initialize();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedCutLists,
        cutLists.map((c) => CachedCutListsCompanion(
          id: Value(c.id),
          name: Value(c.name),
          description: Value(c.description),
          boundaryPolygon: Value(c.boundaryPolygon != null
              ? jsonEncode(c.boundaryPolygon!.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList())
              : null),
          voterCount: Value(c.voterCount),
          createdAt: Value(c.createdAt),
          updatedAt: Value(c.updatedAt),
          cachedAt: Value(DateTime.now()),
        )).toList(),
      );
    });

    await _db.updateSyncTime('cut_lists');
  }

  @override
  Future<List<CutList>> getCachedCutLists() async {
    if (!_initialized) await initialize();

    final rows = await _db.select(_db.cachedCutLists).get();
    return rows.map((r) => _cutListFromCache(r)).toList();
  }

  CutList _cutListFromCache(CachedCutList r) {
    List<LatLng>? polygon;
    if (r.boundaryPolygon != null) {
      final List<dynamic> coords = jsonDecode(r.boundaryPolygon!);
      polygon = coords.map((c) => LatLng(c['lat'], c['lng'])).toList();
    }

    return CutList(
      id: r.id,
      name: r.name,
      description: r.description,
      boundaryPolygon: polygon,
      voterCount: r.voterCount,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  // MARK: - Cut List Voters Caching

  @override
  Future<void> cacheCutListVoters(String cutListId, List<String> voterUniqueIds) async {
    if (!_initialized) await initialize();

    // Clear existing voters for this cut list
    await (_db.delete(_db.cachedCutListVoters)
          ..where((t) => t.cutListId.equals(cutListId)))
        .go();

    // Add new voters
    await _db.batch((batch) {
      batch.insertAll(
        _db.cachedCutListVoters,
        voterUniqueIds.map((id) => CachedCutListVotersCompanion(
          cutListId: Value(cutListId),
          voterUniqueId: Value(id),
        )).toList(),
      );
    });
  }

  // MARK: - Clear Cache

  @override
  Future<void> clearAllCache() async {
    if (!_initialized) await initialize();
    await _db.clearAllCache();
  }

  @override
  Future<void> clearVoterCache() async {
    if (!_initialized) await initialize();
    await _db.delete(_db.cachedVoters).go();
  }

  // MARK: - Pending Updates (Offline Sync Queue)

  @override
  Future<void> addPendingVoterUpdate(PendingVoterUpdateData update) async {
    if (!_initialized) await initialize();
    await _db.addPendingUpdate(PendingVoterUpdatesCompanion(
      uniqueId: Value(update.uniqueId),
      canvassResult: Value(update.canvassResult),
      canvassNotes: Value(update.canvassNotes),
      canvassDate: Value(update.canvassDate),
      contactAttempts: Value(update.contactAttempts),
      lastContactAttempt: Value(update.lastContactAttempt),
      lastContactMethod: Value(update.lastContactMethod),
      voicemailLeft: Value(update.voicemailLeft),
    ));
  }

  @override
  Future<List<PendingVoterUpdateData>> getPendingUpdates() async {
    if (!_initialized) await initialize();
    final rows = await _db.getPendingUpdates();
    return rows.map((r) => PendingVoterUpdateData(
      id: r.id,
      uniqueId: r.uniqueId,
      canvassResult: r.canvassResult,
      canvassNotes: r.canvassNotes,
      canvassDate: r.canvassDate,
      contactAttempts: r.contactAttempts,
      lastContactAttempt: r.lastContactAttempt,
      lastContactMethod: r.lastContactMethod,
      voicemailLeft: r.voicemailLeft,
    )).toList();
  }

  @override
  Future<int> getPendingUpdateCount() async {
    if (!_initialized) await initialize();
    return _db.getPendingUpdateCount();
  }

  @override
  Future<void> deletePendingUpdate(int id) async {
    if (!_initialized) await initialize();
    await _db.deletePendingUpdate(id);
  }

  @override
  Future<void> updateCachedVoterData(String uniqueId, PendingVoterUpdateData data) async {
    if (!_initialized) await initialize();
    await _db.updateCachedVoter(
      uniqueId: uniqueId,
      canvassResult: data.canvassResult,
      canvassNotes: data.canvassNotes,
      canvassDate: data.canvassDate,
      contactAttempts: data.contactAttempts,
      lastContactAttempt: data.lastContactAttempt,
      lastContactMethod: data.lastContactMethod,
      voicemailLeft: data.voicemailLeft,
    );
  }

  @override
  Future<void> updateCachedVoterFromServer(Voter voter) async {
    if (!_initialized) await initialize();
    await _db.updateCachedVoterFromServer(
      uniqueId: voter.uniqueId,
      canvassResult: voter.canvassResult.displayName,
      canvassNotes: voter.canvassNotes.isEmpty ? null : voter.canvassNotes,
      canvassDate: voter.canvassDate,
      contactAttempts: voter.contactAttempts,
      lastContactAttempt: voter.lastContactAttempt,
      lastContactMethod: voter.lastContactMethod?.displayName,
      voicemailLeft: voter.voicemailLeft,
    );
  }

  // MARK: - Contact History Caching

  @override
  Future<void> cacheContactHistory(String uniqueId, List<ContactEntry> entries) async {
    if (!_initialized) await initialize();
    await _db.cacheContactHistory(
      uniqueId,
      entries.map((e) => CachedContactHistoryCompanion(
        id: Value(e.id),
        uniqueId: Value(uniqueId),
        method: Value(e.method.displayName),
        result: Value(e.result.displayName),
        notes: Value(e.notes),
        contactedAt: Value(e.contactedAt),
        contactedBy: Value(e.contactedBy),
        isPending: const Value(false),
      )).toList(),
    );
  }

  @override
  Future<List<ContactEntry>> getCachedContactHistory(String uniqueId) async {
    if (!_initialized) await initialize();
    final rows = await _db.getCachedContactHistory(uniqueId);
    return rows.map((r) => ContactEntry(
      id: r.id,
      visitorId: r.uniqueId,
      method: ContactMethod.fromString(r.method) ?? ContactMethod.call,
      result: CanvassResult.fromString(r.result),
      notes: r.notes,
      contactedAt: r.contactedAt,
      contactedBy: r.contactedBy,
    )).toList();
  }

  @override
  Future<void> addPendingContactEntry(ContactEntry entry) async {
    if (!_initialized) await initialize();
    await _db.addPendingContactEntry(CachedContactHistoryCompanion(
      id: Value('pending_${DateTime.now().millisecondsSinceEpoch}'),
      uniqueId: Value(entry.visitorId),
      method: Value(entry.method.displayName),
      result: Value(entry.result.displayName),
      notes: Value(entry.notes),
      contactedAt: Value(entry.contactedAt),
      contactedBy: Value(entry.contactedBy),
      isPending: const Value(true),
    ));
  }

  @override
  Future<List<ContactEntry>> getPendingContactEntries() async {
    if (!_initialized) await initialize();
    final rows = await _db.getPendingContactEntries();
    return rows.map((r) => ContactEntry(
      id: r.id,
      visitorId: r.uniqueId,
      method: ContactMethod.fromString(r.method) ?? ContactMethod.call,
      result: CanvassResult.fromString(r.result),
      notes: r.notes,
      contactedAt: r.contactedAt,
      contactedBy: r.contactedBy,
    )).toList();
  }

  @override
  Future<void> markContactEntrySynced(String uniqueId, DateTime contactedAt, String serverId) async {
    if (!_initialized) await initialize();
    await _db.markContactEntrySynced(uniqueId, contactedAt, serverId);
  }

  @override
  Future<void> deletePendingContactEntry(String uniqueId, DateTime contactedAt) async {
    if (!_initialized) await initialize();
    await _db.deletePendingContactEntry(uniqueId, contactedAt);
  }
}

/// Factory function to create instance - used by conditional import
CacheServiceInterface createCacheService() => CacheServiceImpl.instance;
