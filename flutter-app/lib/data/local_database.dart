import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

// Cached Voters table
class CachedVoters extends Table {
  TextColumn get uniqueId => text()();
  TextColumn get visitorId => text().nullable()();
  TextColumn get ownerName => text().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get middleName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get cellPhone => text().nullable()();
  TextColumn get streetNum => text().nullable()();
  TextColumn get streetDir => text().nullable()();
  TextColumn get streetName => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get zip => text().nullable()();
  TextColumn get partyDescription => text().nullable()();
  IntColumn get voterAge => integer().withDefault(const Constant(0))();
  TextColumn get gender => text().nullable()();
  TextColumn get registrationDate => text().nullable()();
  TextColumn get residenceAddress => text().nullable()();
  RealColumn get latitude => real().withDefault(const Constant(0))();
  RealColumn get longitude => real().withDefault(const Constant(0))();
  TextColumn get canvassResult => text().nullable()();
  TextColumn get canvassNotes => text().nullable()();
  DateTimeColumn get canvassDate => dateTime().nullable()();
  IntColumn get contactAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastContactAttempt => dateTime().nullable()();
  TextColumn get lastContactMethod => text().nullable()();
  BoolColumn get voicemailLeft => boolean().withDefault(const Constant(false))();
  // Mailing address
  TextColumn get mailAddress => text().nullable()();
  TextColumn get mailCity => text().nullable()();
  TextColumn get mailState => text().nullable()();
  TextColumn get mailZip => text().nullable()();
  BoolColumn get livesElsewhere => boolean().withDefault(const Constant(false))();
  BoolColumn get isMailVoter => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {uniqueId};
}

// Cached Cut Lists table
class CachedCutLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get boundaryPolygon => text().nullable()(); // JSON string
  IntColumn get voterCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Cut List Voter mapping
class CachedCutListVoters extends Table {
  TextColumn get cutListId => text()();
  TextColumn get voterUniqueId => text()();

  @override
  Set<Column> get primaryKey => {cutListId, voterUniqueId};
}

// Sync status table with user tracking for permission-aware caching
class SyncStatus extends Table {
  TextColumn get syncTableName => text()();
  DateTimeColumn get lastSyncAt => dateTime()();
  TextColumn get userId => text().nullable()();     // Who cached the data
  TextColumn get fetchMode => text().nullable()();  // 'all' or 'assigned'

  @override
  Set<Column> get primaryKey => {syncTableName};
}

// Pending voter updates (offline queue)
class PendingVoterUpdates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uniqueId => text()(); // Voter unique_id
  TextColumn get canvassResult => text()();
  TextColumn get canvassNotes => text().nullable()();
  DateTimeColumn get canvassDate => dateTime()();
  IntColumn get contactAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastContactAttempt => dateTime().nullable()();
  TextColumn get lastContactMethod => text().nullable()();
  BoolColumn get voicemailLeft => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Cached contact history entries
class CachedContactHistory extends Table {
  TextColumn get id => text()(); // Server ID (empty string for pending entries)
  TextColumn get uniqueId => text()(); // Voter unique_id
  TextColumn get method => text()(); // call, text, door
  TextColumn get result => text()(); // CanvassResult value
  TextColumn get notes => text().nullable()();
  DateTimeColumn get contactedAt => dateTime()();
  TextColumn get contactedBy => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))(); // True if not yet synced

  @override
  Set<Column> get primaryKey => {id, uniqueId, contactedAt}; // Composite key for pending entries
}

@DriftDatabase(tables: [CachedVoters, CachedCutLists, CachedCutListVoters, SyncStatus, PendingVoterUpdates, CachedContactHistory])
class LocalDatabase extends _$LocalDatabase {
  // Singleton instance
  static final LocalDatabase _instance = LocalDatabase._internal();
  static LocalDatabase get instance => _instance;
  factory LocalDatabase() => _instance;
  LocalDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.deleteTable('cached_voters');
            await m.createTable(cachedVoters);
          }
          if (from < 3) {
            await m.createTable(pendingVoterUpdates);
          }
          if (from < 4) {
            // Add userId and fetchMode columns to sync_status
            await m.addColumn(syncStatus, syncStatus.userId);
            await m.addColumn(syncStatus, syncStatus.fetchMode);
          }
          if (from < 5) {
            // Add contact history caching table
            await m.createTable(cachedContactHistory);
          }
          if (from < 6) {
            // Schema simplification: remove organization-specific columns
            // Easiest approach is to recreate tables with new schema
            await m.deleteTable('cached_voters');
            await m.createTable(cachedVoters);
            await m.deleteTable('pending_voter_updates');
            await m.createTable(pendingVoterUpdates);
          }
        },
      );

  // Clear all cached data (keeps pending updates!)
  Future<void> clearAllCache() async {
    await delete(cachedVoters).go();
    await delete(cachedCutLists).go();
    await delete(cachedCutListVoters).go();
    await delete(syncStatus).go();
    // Note: We do NOT clear pendingVoterUpdates - those need to sync!
  }

  // Pending Updates methods
  Future<void> addPendingUpdate(PendingVoterUpdatesCompanion update) async {
    // Remove any existing pending update for this voter (keep only latest)
    await (delete(pendingVoterUpdates)
          ..where((t) => t.uniqueId.equals(update.uniqueId.value)))
        .go();
    await into(pendingVoterUpdates).insert(update);
  }

  Future<List<PendingVoterUpdate>> getPendingUpdates() async {
    return select(pendingVoterUpdates).get();
  }

  Future<int> getPendingUpdateCount() async {
    final result = await (selectOnly(pendingVoterUpdates)
          ..addColumns([pendingVoterUpdates.id.count()]))
        .getSingle();
    return result.read(pendingVoterUpdates.id.count()) ?? 0;
  }

  Future<void> deletePendingUpdate(int id) async {
    await (delete(pendingVoterUpdates)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearPendingUpdates() async {
    await delete(pendingVoterUpdates).go();
  }

  // Update a cached voter with new data (canvass fields only)
  Future<void> updateCachedVoter({
    required String uniqueId,
    required String canvassResult,
    String? canvassNotes,
    required DateTime canvassDate,
    required int contactAttempts,
    DateTime? lastContactAttempt,
    String? lastContactMethod,
    required bool voicemailLeft,
  }) async {
    await (update(cachedVoters)..where((t) => t.uniqueId.equals(uniqueId)))
        .write(CachedVotersCompanion(
      canvassResult: Value(canvassResult),
      canvassNotes: Value(canvassNotes),
      canvassDate: Value(canvassDate),
      contactAttempts: Value(contactAttempts),
      lastContactAttempt: Value(lastContactAttempt),
      lastContactMethod: Value(lastContactMethod),
      voicemailLeft: Value(voicemailLeft),
    ));
  }

  // Update a cached voter with full server data
  Future<void> updateCachedVoterFromServer({
    required String uniqueId,
    String? canvassResult,
    String? canvassNotes,
    DateTime? canvassDate,
    int contactAttempts = 0,
    DateTime? lastContactAttempt,
    String? lastContactMethod,
    bool voicemailLeft = false,
  }) async {
    await (update(cachedVoters)..where((t) => t.uniqueId.equals(uniqueId)))
        .write(CachedVotersCompanion(
      canvassResult: Value(canvassResult),
      canvassNotes: Value(canvassNotes),
      canvassDate: Value(canvassDate),
      contactAttempts: Value(contactAttempts),
      lastContactAttempt: Value(lastContactAttempt),
      lastContactMethod: Value(lastContactMethod),
      voicemailLeft: Value(voicemailLeft),
      cachedAt: Value(DateTime.now()),
    ));
  }

  // Get last sync time for a table
  Future<DateTime?> getLastSyncTime(String table) async {
    final result = await (select(syncStatus)
          ..where((t) => t.syncTableName.equals(table)))
        .getSingleOrNull();
    return result?.lastSyncAt;
  }

  // Update sync time
  Future<void> updateSyncTime(String table) async {
    await into(syncStatus).insertOnConflictUpdate(
      SyncStatusCompanion(
        syncTableName: Value(table),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  // Update sync time with user metadata (for permission-aware caching)
  Future<void> updateSyncTimeWithMeta(String table, String userId, String fetchMode) async {
    await into(syncStatus).insertOnConflictUpdate(
      SyncStatusCompanion(
        syncTableName: Value(table),
        lastSyncAt: Value(DateTime.now()),
        userId: Value(userId),
        fetchMode: Value(fetchMode),
      ),
    );
  }

  // Get sync metadata (time, userId, fetchMode)
  Future<SyncStatusData?> getSyncMeta(String table) async {
    return await (select(syncStatus)
          ..where((t) => t.syncTableName.equals(table)))
        .getSingleOrNull();
  }

  // Contact History methods
  Future<void> cacheContactHistory(String uniqueId, List<CachedContactHistoryCompanion> entries) async {
    // Clear existing non-pending entries for this voter
    await (delete(cachedContactHistory)
          ..where((t) => t.uniqueId.equals(uniqueId) & t.isPending.equals(false)))
        .go();
    // Insert new entries
    await batch((b) {
      b.insertAll(cachedContactHistory, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<CachedContactHistoryData>> getCachedContactHistory(String uniqueId) async {
    return await (select(cachedContactHistory)
          ..where((t) => t.uniqueId.equals(uniqueId))
          ..orderBy([(t) => OrderingTerm.desc(t.contactedAt)]))
        .get();
  }

  Future<void> addPendingContactEntry(CachedContactHistoryCompanion entry) async {
    await into(cachedContactHistory).insert(entry);
  }

  Future<List<CachedContactHistoryData>> getPendingContactEntries() async {
    return await (select(cachedContactHistory)
          ..where((t) => t.isPending.equals(true)))
        .get();
  }

  Future<void> markContactEntrySynced(String uniqueId, DateTime contactedAt, String serverId) async {
    await (update(cachedContactHistory)
          ..where((t) => t.uniqueId.equals(uniqueId) & t.contactedAt.equals(contactedAt) & t.isPending.equals(true)))
        .write(CachedContactHistoryCompanion(
          id: Value(serverId),
          isPending: const Value(false),
        ));
  }

  Future<void> deletePendingContactEntry(String uniqueId, DateTime contactedAt) async {
    await (delete(cachedContactHistory)
          ..where((t) => t.uniqueId.equals(uniqueId) & t.contactedAt.equals(contactedAt) & t.isPending.equals(true)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'grassroots_canvass_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
