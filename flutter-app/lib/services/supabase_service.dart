import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voter.dart';
import '../models/user_profile.dart';
import '../models/contact_entry.dart';
import '../models/app_notification.dart';
import '../models/cut_list.dart';
import '../models/text_template.dart';
import '../models/campaign.dart';
import '../models/enums/contact_method.dart';
import '../models/enums/canvass_result.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  bool isDemoMode = false;
  UserProfile? currentProfile;

  // Auth state
  bool get isAuthenticated => _client.auth.currentUser != null || isDemoMode;
  User? get currentUser => _client.auth.currentUser;

  bool get isApproved => currentProfile?.isApproved ?? false;
  bool get isAdmin => currentProfile?.isAdmin ?? false;
  bool get isTeamLead => currentProfile?.isTeamLead ?? false;
  bool get isPending => currentProfile?.isPending ?? false;
  /// Team leads and admins can manage cut lists and load all voters
  bool get canManageCutLists => currentProfile?.canManageCutLists ?? false;

  // Initialize
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.projectURL,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // MARK: - Auth Methods

  Future<void> signUp(String email, String password, {String? fullName}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    if (response.user != null) {
      // Create user profile with full name
      await _client.from('user_profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      await fetchCurrentProfile();
    }
  }

  Future<void> signIn(String email, String password) async {
    // Check for demo account (if configured via --dart-define flags)
    if (SupabaseConfig.hasDemoAccount &&
        email.toLowerCase() == SupabaseConfig.demoEmail.toLowerCase() &&
        password == SupabaseConfig.demoPassword) {
      isDemoMode = true;
      currentProfile = UserProfile(
        id: 'demo-user-id',
        email: email,
        fullName: 'Demo User',
        role: 'canvasser',
        approvedAt: '2024-01-01',
        createdAt: '2024-01-01',
      );
      return;
    }

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await fetchCurrentProfile();
    }
  }

  Future<void> signOut() async {
    if (!isDemoMode) {
      await _client.auth.signOut();
    }
    isDemoMode = false;
    currentProfile = null;
  }

  Future<void> deleteAccount() async {
    if (isDemoMode) {
      throw Exception('Cannot delete demo account');
    }

    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Delete user profile
    await _client.from('user_profiles').delete().eq('id', userId);
    await signOut();
  }

  Future<void> fetchCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    currentProfile = UserProfile.fromJson(response);
  }

  // MARK: - Admin Methods

  Future<List<UserProfile>> fetchAllUsers() async {
    final response = await _client
        .from('user_profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  Future<bool> approveUser(String userId) async {
    try {
      await _client.from('user_profiles').update({
        'role': 'canvasser',
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': currentUser?.id,
      }).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> revokeUser(String userId) async {
    await _client.from('user_profiles').update({
      'role': 'pending',
    }).eq('id', userId);
  }

  Future<void> makeAdmin(String userId) async {
    await _client.from('user_profiles').update({
      'role': 'admin',
    }).eq('id', userId);
  }

  Future<List<UserProfile>> getPendingUsers() async {
    final response = await _client
        .from('user_profiles')
        .select()
        .eq('role', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  Future<List<UserProfile>> getAllUsers() async {
    return fetchAllUsers();
  }

  Future<bool> rejectUser(String userId) async {
    try {
      await _client.from('user_profiles').delete().eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setUserRole(String userId, String role) async {
    try {
      await _client.from('user_profiles').update({
        'role': role,
        if (role == 'canvasser' || role == 'admin')
          'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // MARK: - Voter Methods

  /// Fetch contact counts for all voters in one query
  Future<Map<String, int>> _fetchContactCounts() async {
    try {
      final response = await _client
          .from('contact_history')
          .select('unique_id');

      final countMap = <String, int>{};
      for (final row in response as List) {
        final uid = row['unique_id'] as String?;
        if (uid != null) {
          countMap[uid] = (countMap[uid] ?? 0) + 1;
        }
      }
      return countMap;
    } catch (e) {
      print('[SupabaseService] Failed to fetch contact counts: $e');
      return {};
    }
  }

  /// Apply contact counts to a list of voters
  List<Voter> _applyContactCounts(List<Voter> voters, Map<String, int> counts) {
    if (counts.isEmpty) return voters;
    return voters.map((v) {
      final count = counts[v.uniqueId] ?? 0;
      if (count > 0) {
        return v.copyWith(contactAttempts: count);
      }
      return v;
    }).toList();
  }

  Future<List<Voter>> fetchVoters({int limit = 1000, int offset = 0, bool includeContactCounts = true}) async {
    // Start contact counts fetch in parallel
    final countsFuture = includeContactCounts ? _fetchContactCounts() : Future.value(<String, int>{});

    final response = await _client
        .from('voters')
        .select()
        .order('votes', ascending: false)
        .range(offset, offset + limit - 1);

    final counts = await countsFuture;
    final voters = (response as List).map((json) => Voter.fromSupabase(json)).toList();
    return _applyContactCounts(voters, counts);
  }

  Future<List<Voter>> fetchVotersFiltered({
    double? minVotes,
    double? maxVotes,
    String? party,
    int? minVoterScore,
    int limit = 5000,
  }) async {
    var query = _client.from('voters').select();

    if (minVotes != null && minVotes > 0) {
      query = query.gte('votes', minVotes);
    }
    if (maxVotes != null && maxVotes < 100) {
      query = query.lte('votes', maxVotes);
    }
    if (party != null && party.isNotEmpty) {
      query = query.eq('party', party);
    }
    if (minVoterScore != null && minVoterScore > 0) {
      query = query.gte('voter_score', minVoterScore);
    }

    final response = await query
        .order('votes', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Voter.fromSupabase(json))
        .toList();
  }

  Future<List<Voter>> fetchAllVoters({Function(int)? onProgress}) async {
    List<Voter> allVoters = [];
    const batchSize = 1000;
    int offset = 0;

    while (true) {
      final batch = await fetchVoters(limit: batchSize, offset: offset);
      allVoters.addAll(batch);
      onProgress?.call(allVoters.length);

      if (batch.length < batchSize) {
        break; // No more records
      }
      offset += batchSize;
    }

    return allVoters;
  }

  Future<List<Voter>> fetchVotersByRegion({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int limit = 500,
  }) async {
    final response = await _client
        .from('voters')
        .select()
        .gte('latitude', minLat)
        .lte('latitude', maxLat)
        .gte('longitude', minLon)
        .lte('longitude', maxLon)
        .neq('latitude', 0)
        .order('votes', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Voter.fromSupabase(json))
        .toList();
  }

  /// Fetch voters for cut list creation - only those with valid coordinates
  /// This matches the web admin's filtering: NOT NULL latitude AND NOT NULL longitude
  Future<List<Voter>> fetchVotersForCutListCreation({Function(int)? onProgress}) async {
    // Only fetch columns needed for cut list (same as web admin - much faster)
    const columns = 'unique_id,first_name,last_name,latitude,longitude,party,owner_code,lives_elsewhere,is_pevl,canvass_result';

    // First, get count of voters with valid coordinates
    try {
      final countResponse = await _client
          .from('voters')
          .select('unique_id')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .count(CountOption.exact);
      print('[fetchVotersForCutList] Total voters with coords in DB: ${countResponse.count}');
    } catch (e) {
      print('[fetchVotersForCutList] Count query failed: $e');
    }

    List<Voter> allVoters = [];
    const batchSize = 1000;
    int offset = 0;
    int batchNum = 0;

    while (true) {
      batchNum++;
      print('[fetchVotersForCutList] Batch #$batchNum: Fetching at offset $offset');

      final response = await _client
          .from('voters')
          .select(columns)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .range(offset, offset + batchSize - 1);

      final responseList = response as List;
      print('[fetchVotersForCutList] Batch #$batchNum: Got ${responseList.length} rows');

      if (responseList.isNotEmpty && offset == 0) {
        final first = responseList.first;
        print('[fetchVotersForCutList] First row keys: ${first.keys.toList()}');
        print('[fetchVotersForCutList] First row lat: ${first['latitude']} (${first['latitude'].runtimeType})');
        print('[fetchVotersForCutList] First row lng: ${first['longitude']} (${first['longitude'].runtimeType})');
      }

      final batch = responseList.map((json) => Voter.fromSupabase(json)).toList();

      // Debug: Check first voter's parsed coords
      if (batch.isNotEmpty && offset == 0) {
        final v = batch.first;
        print('[fetchVotersForCutList] First parsed voter: lat=${v.latitude}, lng=${v.longitude}');
      }

      allVoters.addAll(batch);
      onProgress?.call(allVoters.length);

      if (batch.length < batchSize) {
        print('[fetchVotersForCutList] Batch #$batchNum: Last batch (${batch.length} < $batchSize), stopping');
        break;
      }
      offset += batchSize;

      // Safety limit to prevent infinite loops
      if (batchNum > 100) {
        print('[fetchVotersForCutList] Safety limit reached (100 batches), stopping');
        break;
      }
    }

    print('[fetchVotersForCutList] Complete: ${allVoters.length} voters in $batchNum batches');
    return allVoters;
  }

  Future<void> saveCanvassResult({
    required String uniqueId,
    required String result,
    String? notes,
  }) async {
    final Map<String, dynamic> data = {
      'canvass_result': result,
      'canvass_date': DateTime.now().toIso8601String(),
    };
    if (notes != null && notes.isNotEmpty) {
      data['canvass_notes'] = notes;
    }

    await _client.from('voters').update(data).eq('unique_id', uniqueId);
  }

  Future<void> saveCanvassData({required Voter voter}) async {
    if (voter.uniqueId.isEmpty) {
      throw Exception('Voter has no unique ID');
    }

    await _client
        .from('voters')
        .update(voter.toCanvassJson())
        .eq('unique_id', voter.uniqueId);
  }

  Future<void> updateVoterInfo({required Voter voter}) async {
    if (voter.uniqueId.isEmpty) {
      throw Exception('Voter has no unique ID');
    }

    await _client
        .from('voters')
        .update(voter.toEditableJson())
        .eq('unique_id', voter.uniqueId);
  }

  /// Fetch a single voter by unique_id
  Future<Voter?> fetchVoterByUniqueId(String uniqueId) async {
    if (isDemoMode) return null;

    try {
      final response = await _client
          .from('voters')
          .select()
          .eq('unique_id', uniqueId)
          .single();

      return Voter.fromSupabase(response);
    } catch (e) {
      print('[SupabaseService] Failed to fetch voter $uniqueId: $e');
      return null;
    }
  }

  Future<void> updateContactAttempt({
    required String uniqueId,
    required String method,
    required String result,
  }) async {
    // First get current contact attempts
    final response = await _client
        .from('voters')
        .select('contact_attempts')
        .eq('unique_id', uniqueId)
        .single();

    final currentAttempts = response['contact_attempts'] ?? 0;

    await _client.from('voters').update({
      'contact_attempts': currentAttempts + 1,
      'last_contact_attempt': DateTime.now().toIso8601String(),
      'last_contact_method': method,
      'canvass_result': result,
      'canvass_date': DateTime.now().toIso8601String(),
    }).eq('unique_id', uniqueId);
  }

  // MARK: - Contact History Methods

  Future<List<ContactEntry>> fetchContactHistory(String uniqueId) async {
    // Return empty list if no valid uniqueId
    if (uniqueId.isEmpty) {
      return [];
    }

    if (isDemoMode) {
      // Return demo data for demo mode
      return [
        ContactEntry(
          id: 'demo-1',
          visitorId: uniqueId,
          method: ContactMethod.call,
          result: CanvassResult.leftVoicemail,
          notes: 'Left voicemail about upcoming election',
          contactedAt: DateTime.now().subtract(const Duration(days: 3)),
          contactedBy: 'Demo User',
        ),
        ContactEntry(
          id: 'demo-2',
          visitorId: uniqueId,
          method: ContactMethod.door,
          result: CanvassResult.notHome,
          notes: null,
          contactedAt: DateTime.now().subtract(const Duration(days: 7)),
          contactedBy: 'Demo User',
        ),
      ];
    }

    // Query by unique_id (always populated) instead of visitor_id (often null)
    final response = await _client
        .from('contact_history')
        .select()
        .eq('unique_id', uniqueId)
        .order('contacted_at', ascending: false);

    return (response as List)
        .map((json) => ContactEntry.fromJson(json))
        .toList();
  }

  Future<ContactEntry?> addContactEntry(ContactEntry entry) async {
    if (isDemoMode) {
      return entry.copyWith(id: 'demo-${DateTime.now().millisecondsSinceEpoch}');
    }

    final data = entry.toJson();
    data['contacted_by'] = currentUser?.id;

    final response = await _client
        .from('contact_history')
        .insert(data)
        .select()
        .single();

    return ContactEntry.fromJson(response);
  }

  Future<bool> updateContactEntry(ContactEntry entry) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('contact_history')
          .update(entry.toJson())
          .eq('id', entry.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteContactEntry(String entryId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('contact_history')
          .delete()
          .eq('id', entryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // MARK: - Notification Methods

  Future<List<AppNotification>> fetchNotifications({bool unreadOnly = false}) async {
    if (isDemoMode) {
      // Return demo notifications
      return [
        AppNotification(
          id: 'demo-notif-1',
          userId: 'demo-user-id',
          title: 'New User Signup',
          message: 'John Doe (john@example.com) has signed up and is waiting for approval.',
          type: 'signup',
          read: false,
          data: {'new_user_email': 'john@example.com', 'new_user_name': 'John Doe'},
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: 'demo-notif-2',
          userId: 'demo-user-id',
          title: 'New User Signup',
          message: 'Jane Smith (jane@example.com) has signed up and is waiting for approval.',
          type: 'signup',
          read: true,
          data: {'new_user_email': 'jane@example.com', 'new_user_name': 'Jane Smith'},
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }

    final userId = currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', userId);

    if (unreadOnly) {
      query = query.eq('read', false);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  Future<int> getUnreadNotificationCount() async {
    if (isDemoMode) return 1;

    final userId = currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);

    return (response as List).length;
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    if (isDemoMode) return true;

    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // MARK: - Cut List Methods

  Future<List<CutList>> fetchCutLists() async {
    if (isDemoMode) {
      return [
        CutList(
          id: 'demo-list-1',
          name: 'North Mesa Area',
          description: 'High priority voters in North Mesa',
          voterCount: 45,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CutList(
          id: 'demo-list-2',
          name: 'Downtown District',
          description: 'Downtown apartment complexes',
          voterCount: 120,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }

    final response = await _client
        .from('cut_lists')
        .select('*, cut_list_voters(count)')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      // Get actual voter count from cut_list_voters join
      final cutListVoters = json['cut_list_voters'] as List?;
      int actualVoterCount = 0;
      if (cutListVoters != null && cutListVoters.isNotEmpty) {
        actualVoterCount = cutListVoters[0]['count'] as int? ?? 0;
      }
      // Override stored voter_count with actual count
      json['voter_count'] = actualVoterCount;
      return CutList.fromJson(json);
    }).toList();
  }

  Future<List<CutList>> fetchMyCutLists() async {
    if (isDemoMode) return fetchCutLists();

    final userId = currentUser?.id;
    if (userId == null) return [];

    // If admin, return all lists
    if (isAdmin) {
      return fetchCutLists();
    }

    // Otherwise, return only assigned lists
    final response = await _client
        .from('cut_list_assignments')
        .select('cut_list_id, cut_lists(*, cut_list_voters(count))')
        .eq('user_id', userId);

    return (response as List).map((json) {
      final cutListJson = json['cut_lists'] as Map<String, dynamic>;
      // Get actual voter count from cut_list_voters join
      final cutListVoters = cutListJson['cut_list_voters'] as List?;
      int actualVoterCount = 0;
      if (cutListVoters != null && cutListVoters.isNotEmpty) {
        actualVoterCount = cutListVoters[0]['count'] as int? ?? 0;
      }
      // Override stored voter_count with actual count
      cutListJson['voter_count'] = actualVoterCount;
      return CutList.fromJson(cutListJson);
    }).toList();
  }

  Future<CutList?> createCutList(CutList cutList) async {
    if (isDemoMode) {
      return cutList.copyWith(id: 'demo-${DateTime.now().millisecondsSinceEpoch}');
    }

    final data = cutList.toJson();
    data['created_by'] = currentUser?.id;

    final response = await _client
        .from('cut_lists')
        .insert(data)
        .select()
        .single();

    return CutList.fromJson(response);
  }

  Future<bool> updateCutList(CutList cutList) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('cut_lists')
          .update(cutList.toJson())
          .eq('id', cutList.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCutList(String cutListId) async {
    if (isDemoMode) return true;

    try {
      await _client.from('cut_lists').delete().eq('id', cutListId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addVotersToCutList(String cutListId, List<String> voterUniqueIds) async {
    if (isDemoMode) return true;

    try {
      // Batch inserts to avoid Supabase limits on large inserts
      const batchSize = 500;
      for (var i = 0; i < voterUniqueIds.length; i += batchSize) {
        final batchIds = voterUniqueIds.sublist(
          i,
          i + batchSize > voterUniqueIds.length ? voterUniqueIds.length : i + batchSize,
        );
        final data = batchIds
            .map((id) => {'cut_list_id': cutListId, 'voter_unique_id': id})
            .toList();

        await _client.from('cut_list_voters').upsert(data);
      }
      return true;
    } catch (e) {
      print('[SupabaseService] Failed to add voters to cut list: $e');
      return false;
    }
  }

  Future<bool> removeVoterFromCutList(String cutListId, String voterUniqueId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('cut_list_voters')
          .delete()
          .eq('cut_list_id', cutListId)
          .eq('voter_unique_id', voterUniqueId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears all voters from a cut list (used when updating polygon)
  Future<bool> clearCutListVoters(String cutListId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('cut_list_voters')
          .delete()
          .eq('cut_list_id', cutListId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> fetchCutListVoterIds(String cutListId) async {
    if (isDemoMode) return ['demo-voter-1', 'demo-voter-2'];

    final response = await _client
        .from('cut_list_voters')
        .select('voter_unique_id')
        .eq('cut_list_id', cutListId);

    return (response as List).map((r) => r['voter_unique_id'] as String).toList();
  }

  Future<List<Voter>> fetchCutListVoters(String cutListId) async {
    final voterIds = await fetchCutListVoterIds(cutListId);
    if (voterIds.isEmpty) return [];

    // Start contact counts fetch in parallel
    final countsFuture = _fetchContactCounts();

    final response = await _client
        .from('voters')
        .select()
        .inFilter('unique_id', voterIds);

    final counts = await countsFuture;
    final voters = (response as List).map((json) => Voter.fromSupabase(json)).toList();
    return _applyContactCounts(voters, counts);
  }

  Future<List<Voter>> fetchMyAssignedVoters() async {
    print('[SupabaseService] fetchMyAssignedVoters called');
    print('[SupabaseService] isDemoMode=$isDemoMode, isAdmin=$isAdmin');

    if (isDemoMode) {
      print('[SupabaseService] Demo mode - returning all voters');
      return fetchVoters();
    }

    final userId = currentUser?.id;
    print('[SupabaseService] userId=$userId');
    if (userId == null) return [];

    // If admin, return all voters
    if (isAdmin) {
      print('[SupabaseService] isAdmin=true - returning all voters');
      return fetchVoters();
    }

    // Get all cut lists assigned to this user
    final assignments = await _client
        .from('cut_list_assignments')
        .select('cut_list_id')
        .eq('user_id', userId);

    print('[SupabaseService] Found ${(assignments as List).length} cut list assignments');
    if (assignments.isEmpty) return [];

    final cutListIds = assignments.map((a) => a['cut_list_id']).toList();
    print('[SupabaseService] cutListIds=$cutListIds');

    // Get all voter IDs from those cut lists (paginated to handle large lists)
    final Set<String> voterIdSet = {};
    const pageSize = 1000;
    int offset = 0;

    while (true) {
      final voterIdsResponse = await _client
          .from('cut_list_voters')
          .select('voter_unique_id')
          .inFilter('cut_list_id', cutListIds)
          .range(offset, offset + pageSize - 1);

      final batch = (voterIdsResponse as List)
          .map((r) => r['voter_unique_id'] as String);
      voterIdSet.addAll(batch);

      if (batch.length < pageSize) break; // No more pages
      offset += pageSize;
    }

    final voterIds = voterIdSet.toList();

    print('[SupabaseService] Found ${voterIds.length} voter IDs from cut lists');
    if (voterIds.isEmpty) return [];

    // Fetch contact counts in parallel with first batch
    final contactCountsFuture = _fetchContactCounts();

    // Fetch voters in batches to avoid URL length limits
    // Supabase has ~8KB URL limit, so batch by 100 IDs at a time
    const batchSize = 100;
    final List<Voter> allVoters = [];

    for (var i = 0; i < voterIds.length; i += batchSize) {
      final batchIds = voterIds.sublist(
        i,
        i + batchSize > voterIds.length ? voterIds.length : i + batchSize,
      );

      final response = await _client
          .from('voters')
          .select()
          .inFilter('unique_id', batchIds);

      allVoters.addAll(
        (response as List).map((json) => Voter.fromSupabase(json)),
      );
    }

    // Apply contact counts
    final counts = await contactCountsFuture;
    final votersWithCounts = _applyContactCounts(allVoters, counts);

    // Sort by name
    votersWithCounts.sort((a, b) => a.displayName.compareTo(b.displayName));

    print('[SupabaseService] Fetched ${votersWithCounts.length} voters');
    return votersWithCounts;
  }

  // Cut List Assignments

  Future<List<CutListAssignment>> fetchCutListAssignments(String cutListId) async {
    if (isDemoMode) return [];

    final response = await _client
        .from('cut_list_assignments')
        .select('*, user_profiles(email, full_name)')
        .eq('cut_list_id', cutListId);

    return (response as List)
        .map((json) => CutListAssignment.fromJson(json))
        .toList();
  }

  Future<bool> assignCutListToUser(String cutListId, String userId) async {
    if (isDemoMode) return true;

    try {
      await _client.from('cut_list_assignments').upsert({
        'cut_list_id': cutListId,
        'user_id': userId,
        'assigned_by': currentUser?.id,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unassignCutListFromUser(String cutListId, String userId) async {
    if (isDemoMode) return true;

    try {
      await _client
          .from('cut_list_assignments')
          .delete()
          .eq('cut_list_id', cutListId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // MARK: - Text Template Methods

  /// Fetch text templates from Supabase
  /// Returns templates available to the current user based on:
  /// - Templates assigned directly to them
  /// - Templates assigned to their cut lists
  /// - All active templates for their district
  /// Falls back to hardcoded defaults if fetch fails or in demo mode
  Future<List<TextTemplate>> fetchTextTemplates({
    String? district,
    String? position,
  }) async {
    if (isDemoMode) {
      return TextTemplate.defaults;
    }

    try {
      // Fetch templates with candidate data joined
      var query = _client
          .from('text_templates')
          .select('*, candidate:candidates(*)')
          .eq('is_active', true);

      // Filter by district if provided
      if (district != null) {
        query = query.eq('district', district);
      }

      // Filter by position if provided
      if (position != null) {
        query = query.eq('position', position);
      }

      final response = await query
          .order('category')
          .order('display_order');

      final templates = (response as List)
          .map((json) => TextTemplate.fromJson(json))
          .toList();

      // Return fetched templates, or defaults if empty
      return templates.isNotEmpty ? templates : TextTemplate.defaults;
    } catch (e) {
      print('[SupabaseService] Failed to fetch text templates: $e');
      return TextTemplate.defaults;
    }
  }

  // MARK: - Campaign Methods

  /// Get all campaigns the current user is a member of
  Future<List<Campaign>> getUserCampaigns() async {
    if (isDemoMode) {
      // Return a demo campaign for demo mode
      return [
        Campaign(
          id: 'demo-campaign',
          name: 'Demo Campaign',
          description: 'A sample campaign for demonstration',
          candidateName: 'Demo Candidate',
          createdAt: DateTime.now(),
          userRole: 'admin',
        ),
      ];
    }

    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      // Get campaigns with user's role from campaign_members
      final response = await _client
          .from('campaign_members')
          .select('role, campaigns(*)')
          .eq('user_id', userId);

      return (response as List).map((row) {
        final campaignJson = row['campaigns'] as Map<String, dynamic>;
        final role = row['role'] as String;
        return Campaign.fromJson(campaignJson, userRole: role);
      }).toList();
    } catch (e) {
      print('[SupabaseService] Failed to fetch user campaigns: $e');
      // If campaigns table doesn't exist yet, return empty list
      // This allows backwards compatibility with single-campaign deployments
      return [];
    }
  }

  /// Get the user's currently active campaign ID from their profile
  Future<String?> getActiveCampaignId() async {
    if (isDemoMode) return 'demo-campaign';

    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('active_campaign_id')
          .eq('id', userId)
          .single();

      return response['active_campaign_id'] as String?;
    } catch (e) {
      print('[SupabaseService] Failed to get active campaign: $e');
      return null;
    }
  }

  /// Set the user's active campaign
  Future<void> setActiveCampaignId(String? campaignId) async {
    if (isDemoMode) return;

    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('user_profiles')
          .update({'active_campaign_id': campaignId})
          .eq('id', userId);
    } catch (e) {
      print('[SupabaseService] Failed to set active campaign: $e');
    }
  }

  /// Create a new campaign (admin only)
  Future<Campaign> createCampaign({
    required String name,
    String? description,
    String? organizationName,
    String? candidateName,
    DateTime? electionDate,
    String? district,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Insert campaign
    final campaignResponse = await _client
        .from('campaigns')
        .insert({
          'name': name,
          'description': description,
          'organization_name': organizationName,
          'candidate_name': candidateName,
          'election_date': electionDate?.toIso8601String().split('T').first,
          'district': district,
          'created_by': userId,
        })
        .select()
        .single();

    final campaign = Campaign.fromJson(campaignResponse, userRole: 'admin');

    // Add creator as campaign admin
    await _client.from('campaign_members').insert({
      'campaign_id': campaign.id,
      'user_id': userId,
      'role': 'admin',
      'invited_by': userId,
    });

    // Set as active campaign
    await setActiveCampaignId(campaign.id);

    return campaign;
  }

  /// Update campaign settings
  Future<void> updateCampaign(Campaign campaign) async {
    await _client
        .from('campaigns')
        .update(campaign.toJson())
        .eq('id', campaign.id);
  }

  /// Get campaign members
  Future<List<CampaignMember>> getCampaignMembers(String campaignId) async {
    final response = await _client
        .from('campaign_members')
        .select('*, user_profiles(email, full_name)')
        .eq('campaign_id', campaignId)
        .order('joined_at');

    return (response as List)
        .map((json) => CampaignMember.fromJson(json))
        .toList();
  }

  /// Invite a user to a campaign
  Future<void> inviteToCampaign({
    required String campaignId,
    required String userId,
    String role = 'canvasser',
  }) async {
    await _client.from('campaign_members').insert({
      'campaign_id': campaignId,
      'user_id': userId,
      'role': role,
      'invited_by': currentUser?.id,
    });
  }

  /// Update a member's role in a campaign
  Future<void> updateCampaignMemberRole({
    required String campaignId,
    required String userId,
    required String role,
  }) async {
    await _client
        .from('campaign_members')
        .update({'role': role})
        .eq('campaign_id', campaignId)
        .eq('user_id', userId);
  }

  /// Remove a member from a campaign
  Future<void> removeFromCampaign({
    required String campaignId,
    required String userId,
  }) async {
    await _client
        .from('campaign_members')
        .delete()
        .eq('campaign_id', campaignId)
        .eq('user_id', userId);
  }
}
