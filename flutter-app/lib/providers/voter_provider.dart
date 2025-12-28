import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voter.dart';
import '../models/enums/filter_option.dart';
import '../models/enums/sort_option.dart';
import '../models/enums/canvass_result.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';
import 'connectivity_provider.dart';

class VoterState {
  final List<Voter> voters;
  final bool isLoading;
  final int loadingProgress;
  final String? error;
  final FilterOption filter;
  final SortOption sort;
  final String searchQuery;
  final Set<String> selectedIds;
  final bool isSelectMode;
  final bool isOffline;
  final String? currentCutListId;

  const VoterState({
    this.voters = const [],
    this.isLoading = false,
    this.loadingProgress = 0,
    this.error,
    this.filter = FilterOption.all,
    this.sort = SortOption.name,
    this.searchQuery = '',
    this.selectedIds = const {},
    this.isSelectMode = false,
    this.isOffline = false,
    this.currentCutListId,
  });

  VoterState copyWith({
    List<Voter>? voters,
    bool? isLoading,
    int? loadingProgress,
    String? error,
    FilterOption? filter,
    SortOption? sort,
    String? searchQuery,
    Set<String>? selectedIds,
    bool? isSelectMode,
    bool? isOffline,
    String? currentCutListId,
  }) {
    return VoterState(
      voters: voters ?? this.voters,
      isLoading: isLoading ?? this.isLoading,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      error: error,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectMode: isSelectMode ?? this.isSelectMode,
      isOffline: isOffline ?? this.isOffline,
      currentCutListId: currentCutListId,
    );
  }

  List<Voter> get filteredVoters {
    var result = voters.where((v) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = v.displayName.toLowerCase().contains(query);
        final matchesAddress = v.fullAddress.toLowerCase().contains(query);
        if (!matchesName && !matchesAddress) return false;
      }

      // Status filter
      switch (filter) {
        case FilterOption.all:
          return true;
        case FilterOption.positive:
          return v.canvassResult.isPositive;
        case FilterOption.negative:
          return v.canvassResult.isNegative;
        case FilterOption.neutral:
          return v.canvassResult.isNeutral;
        case FilterOption.contacted:
          return v.canvassResult != CanvassResult.notContacted;
        case FilterOption.uncontacted:
          return v.canvassResult == CanvassResult.notContacted;
        case FilterOption.attempted:
          return v.contactAttempts > 0;
        case FilterOption.unattempted:
          return v.contactAttempts == 0;
        case FilterOption.livesAtProperty:
          return !v.livesElsewhere;
      }
    }).toList();

    // Sort
    switch (sort) {
      case SortOption.name:
        result.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case SortOption.streetName:
        result.sort((a, b) => a.streetName.compareTo(b.streetName));
        break;
      case SortOption.lastContact:
        result.sort((a, b) {
          if (a.lastContactAttempt == null && b.lastContactAttempt == null) return 0;
          if (a.lastContactAttempt == null) return 1;
          if (b.lastContactAttempt == null) return -1;
          return b.lastContactAttempt!.compareTo(a.lastContactAttempt!);
        });
        break;
    }

    return result;
  }

  // Statistics
  int get totalVoters => voters.length;
  int get contactedCount => voters.where((v) => v.canvassResult != CanvassResult.notContacted).length;
  int get supportiveCount => voters.where((v) => v.canvassResult.isSupportive).length;
  int get undecidedCount => voters.where((v) => v.canvassResult == CanvassResult.undecided).length;
  int get opposedCount => voters.where((v) => v.canvassResult == CanvassResult.opposed).length;
}

class VoterNotifier extends Notifier<VoterState> {
  @override
  VoterState build() {
    return const VoterState();
  }

  Future<void> loadVoters({bool forceRefresh = false}) async {
    final supabase = SupabaseService();
    final analytics = AnalyticsService();
    final cache = CacheService.instance;

    if (supabase.isDemoMode) {
      // Load demo voters
      state = state.copyWith(
        voters: _getDemoVoters(),
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null, loadingProgress: 0);

    // Check user permissions early
    final canManage = supabase.canManageCutLists;
    final currentUserId = supabase.currentUser?.id;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh && cache.isAvailable) {
      try {
        await cache.initialize();
        final cacheMeta = await cache.getVotersCacheMeta();
        final cachedVoters = await cache.getCachedVoters();

        // Validate cache ownership before using
        bool cacheValid = false;
        if (!cacheMeta.isEmpty && cachedVoters.isNotEmpty) {
          final cacheAge = DateTime.now().difference(cacheMeta.cacheTime!);
          if (cacheAge.inHours < 24) {
            if (cacheMeta.userId == currentUserId) {
              cacheValid = true;
            } else if (canManage && cacheMeta.fetchMode == 'all') {
              cacheValid = true;
            }
          }
        }

        if (cacheValid) {
          state = state.copyWith(
            voters: cachedVoters,
            isLoading: false,
            isOffline: false,
          );
          analytics.trackVotersLoaded(cachedVoters.length, 'cache');
          return;
        }
      } catch (_) {
        // Cache read failed, continue to network
      }
    }

    // Fetch from network
    try {
      List<Voter> voters;
      final userRole = supabase.currentProfile?.role ?? 'unknown';
      print('[VoterProvider] loadVoters: canManageCutLists=$canManage, role=$userRole');

      if (canManage) {
        print('[VoterProvider] Loading ALL voters (admin/team_lead)');
        voters = await supabase.fetchAllVoters(
          onProgress: (count) {
            state = state.copyWith(loadingProgress: count);
          },
        );
      } else {
        print('[VoterProvider] Loading assigned voters only (canvasser)');
        voters = await supabase.fetchMyAssignedVoters();
      }
      print('[VoterProvider] Loaded ${voters.length} voters');

      // Cache voters locally for offline access with user metadata
      if (cache.isAvailable && currentUserId != null) {
        await cache.initialize();
        await cache.cacheVotersWithMeta(
          voters,
          userId: currentUserId,
          fetchMode: canManage ? 'all' : 'assigned',
        );
      }

      state = state.copyWith(
        voters: voters,
        isLoading: false,
        isOffline: false,
      );

      ref.read(connectivityProvider.notifier).setOnlineSuccess();
      analytics.trackVotersLoaded(voters.length, 'cloud');
    } catch (e) {
      ref.read(connectivityProvider.notifier).setOffline(e.toString());

      // Try to load from cache if network fails
      if (cache.isAvailable) {
        try {
          await cache.initialize();
          final cacheMeta = await cache.getVotersCacheMeta();
          final cachedVoters = await cache.getCachedVoters();

          bool cacheValid = false;
          if (!cacheMeta.isEmpty && cachedVoters.isNotEmpty) {
            if (cacheMeta.userId == currentUserId) {
              cacheValid = true;
            } else if (canManage && cacheMeta.fetchMode == 'all') {
              cacheValid = true;
            }
          }

          if (cacheValid) {
            state = state.copyWith(
              voters: cachedVoters,
              isLoading: false,
              isOffline: true,
              error: null,
            );
            analytics.trackVotersLoaded(cachedVoters.length, 'cache');
            return;
          }
        } catch (_) {
          // Cache also failed
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load voters for a specific cut list
  Future<void> loadVotersForCutList(String cutListId) async {
    final supabase = SupabaseService();
    final analytics = AnalyticsService();
    final cache = CacheService.instance;

    state = state.copyWith(
      isLoading: true,
      error: null,
      loadingProgress: 0,
      currentCutListId: cutListId,
    );

    try {
      final voters = await supabase.fetchCutListVoters(cutListId);

      await cache.initialize();
      await cache.cacheVoters(voters);
      await cache.cacheCutListVoters(
        cutListId,
        voters.map((v) => v.uniqueId).toList(),
      );

      state = state.copyWith(
        voters: voters,
        isLoading: false,
        isOffline: false,
      );

      ref.read(connectivityProvider.notifier).setOnlineSuccess();
      analytics.trackVotersLoaded(voters.length, 'cutlist');
    } catch (e) {
      ref.read(connectivityProvider.notifier).setOffline(e.toString());

      try {
        await cache.initialize();
        final cachedVoters = await cache.getCachedVotersForCutList(cutListId);
        if (cachedVoters.isNotEmpty) {
          state = state.copyWith(
            voters: cachedVoters,
            isLoading: false,
            isOffline: true,
            error: null,
          );
          analytics.trackVotersLoaded(cachedVoters.length, 'cache');
          return;
        }
      } catch (_) {
        // Cache also failed
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearCutListFilter() {
    state = state.copyWith(currentCutListId: null);
    loadVoters();
  }

  void setFilter(FilterOption filter) {
    final analytics = AnalyticsService();
    state = state.copyWith(filter: filter);
    analytics.trackFilter(filter.displayName, 'voter_list');
  }

  void setSort(SortOption sort) {
    final analytics = AnalyticsService();
    state = state.copyWith(sort: sort);
    analytics.track(AnalyticsEvent.sortApplied, {'sort': sort.displayName});
  }

  void setSearchQuery(String query) {
    final analytics = AnalyticsService();
    state = state.copyWith(searchQuery: query);
    if (query.isNotEmpty) {
      analytics.track(AnalyticsEvent.searchPerformed);
    }
  }

  void toggleSelectMode() {
    state = state.copyWith(
      isSelectMode: !state.isSelectMode,
      selectedIds: {},
    );
  }

  void toggleSelection(String uniqueId) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(uniqueId)) {
      newSelected.remove(uniqueId);
    } else {
      newSelected.add(uniqueId);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  void selectAll() {
    final allIds = state.filteredVoters.map((v) => v.uniqueId).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  void clearAll() {
    state = const VoterState();
  }

  void setVoters(List<Voter> voters) {
    state = state.copyWith(voters: voters, isLoading: false);
  }

  List<Voter> getSelectedVoters() {
    return state.voters.where((v) => state.selectedIds.contains(v.uniqueId)).toList();
  }

  Future<bool> updateVoter(Voter voter) async {
    final supabase = SupabaseService();
    final analytics = AnalyticsService();
    final sync = SyncService.instance;

    // Update local state immediately
    final index = state.voters.indexWhere((v) => v.uniqueId == voter.uniqueId);
    if (index >= 0) {
      final newVoters = List<Voter>.from(state.voters);
      newVoters[index] = voter;
      state = state.copyWith(voters: newVoters);
    }

    // Sync to cloud
    if (!supabase.isDemoMode) {
      try {
        await supabase.updateVoterInfo(voter: voter);
        await supabase.saveCanvassData(voter: voter);
        analytics.trackCanvassResult(voter.canvassResult.displayName, voter.uniqueId);
        ref.read(connectivityProvider.notifier).setOnlineSuccess();
        return true;
      } catch (e) {
        print('[VoterProvider] Cloud sync failed, queuing for offline: $e');
        ref.read(connectivityProvider.notifier).setOffline(e.toString());
        await sync.queueVoterUpdate(voter);
        final pendingCount = await sync.refreshPendingCount();
        ref.read(connectivityProvider.notifier).updatePendingCount(pendingCount);
        return true;
      }
    }
    return true;
  }

  List<Voter> _getDemoVoters() {
    return [
      Voter(
        uniqueId: 'demo-1',
        firstName: 'John',
        lastName: 'Smith',
        ownerName: 'SMITH, JOHN',
        streetNum: '123',
        streetDir: 'N',
        streetName: 'Main St',
        city: 'Anytown',
        zip: '12345',
        cellPhone: '(555) 555-0101',
        partyDescription: 'Democratic',
        voterAge: 45,
        gender: 'M',
        latitude: 40.7128,
        longitude: -74.0060,
      ),
      Voter(
        uniqueId: 'demo-2',
        firstName: 'Jane',
        lastName: 'Doe',
        ownerName: 'DOE, JANE',
        streetNum: '456',
        streetDir: 'S',
        streetName: 'Oak Ave',
        city: 'Anytown',
        zip: '12345',
        cellPhone: '(555) 555-0202',
        partyDescription: 'Republican',
        voterAge: 52,
        gender: 'F',
        latitude: 40.7150,
        longitude: -74.0080,
      ),
      Voter(
        uniqueId: 'demo-3',
        firstName: 'Bob',
        lastName: 'Johnson',
        ownerName: 'JOHNSON, BOB',
        streetNum: '789',
        streetDir: 'E',
        streetName: 'Pine Rd',
        city: 'Anytown',
        zip: '12345',
        phone: '(555) 555-0303',
        partyDescription: 'Independent',
        voterAge: 38,
        gender: 'M',
        latitude: 40.7180,
        longitude: -74.0100,
      ),
    ];
  }
}

final voterProvider = NotifierProvider<VoterNotifier, VoterState>(() {
  return VoterNotifier();
});
