import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../models/app_notification.dart';
import '../../models/cut_list.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/adaptive_icons.dart';
import '../../utils/adaptive_colors.dart';
import 'cut_list_creator_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<UserProfile> _pendingUsers = [];
  List<UserProfile> _allUsers = [];
  List<AppNotification> _notifications = [];
  List<CutList> _cutLists = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('admin');
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final pending = await SupabaseService.instance.getPendingUsers();
    final all = await SupabaseService.instance.getAllUsers();
    final notifications = await SupabaseService.instance.fetchNotifications();
    final unreadCount = await SupabaseService.instance.getUnreadNotificationCount();
    final cutLists = await SupabaseService.instance.fetchCutLists();

    setState(() {
      _pendingUsers = pending;
      _allUsers = all;
      _notifications = notifications;
      _unreadCount = unreadCount;
      _cutLists = cutLists;
      _isLoading = false;
    });
  }

  Future<void> _loadUsers() async {
    await _loadData();
  }

  Future<void> _approveUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Approve ${user.email} as a canvasser?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseService.instance.approveUser(user.id);
      if (success) {
        AnalyticsService.instance.trackAction('user_approved');
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email} approved')),
          );
        }
      }
    }
  }

  Future<void> _rejectUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Reject and remove ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseService.instance.rejectUser(user.id);
      if (success) {
        AnalyticsService.instance.trackAction('user_rejected');
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email} rejected')),
          );
        }
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'team_lead':
        return 'Team Lead';
      case 'canvasser':
        return 'Canvasser';
      default:
        return role;
    }
  }

  Future<void> _changeUserRole(UserProfile user, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role to ${_getRoleDisplayName(newRole)}'),
        content: Text(
          'Change ${user.email} role to ${_getRoleDisplayName(newRole)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseService.instance.setUserRole(user.id, newRole);
      if (success) {
        AnalyticsService.instance.trackAction('role_changed_$newRole');
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email} is now a ${_getRoleDisplayName(newRole)}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateData = ref.watch(authProvider);

    if (!authStateData.isAdmin) {
      return PlatformScaffold(
        body: const Center(
          child: Text('Admin access required'),
        ),
      );
    }

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Admin'),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(AdaptiveIcons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Material(
        child: Column(
        children: [
          // Tab bar
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(
                    'Pending',
                    'pending',
                    _pendingUsers.length,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    'Users',
                    'all',
                    _allUsers.length,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    'Cut Lists',
                    'cutlists',
                    _cutLists.length,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    'Notifications',
                    'notifications',
                    _unreadCount,
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'pending'
                    ? _buildPendingList()
                    : _selectedTab == 'all'
                        ? _buildAllUsersList()
                        : _selectedTab == 'cutlists'
                            ? _buildCutListsTab()
                            : _buildNotificationsList(),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tab, int count) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AdaptiveIcons.checkCircleOutline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        user.email.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? user.email,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectUser(user),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _approveUser(user),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllUsersList() {
    if (_allUsers.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: user.role == 'admin'
                ? _getRoleColor(user.role, forBackground: true)
                : Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              user.role == 'admin' ? AdaptiveIcons.admin : AdaptiveIcons.person,
              color: user.role == 'admin'
                  ? _getRoleColor(user.role)
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(user.displayName ?? user.email),
          subtitle: Text(user.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role, forBackground: true),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  if (user.role == 'canvasser')
                    const PopupMenuItem(
                      value: 'team_lead',
                      child: Text('Make Team Lead'),
                    ),
                  if (user.role == 'canvasser' || user.role == 'team_lead')
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Make Admin'),
                    ),
                  if (user.role == 'team_lead')
                    const PopupMenuItem(
                      value: 'canvasser',
                      child: Text('Demote to Canvasser'),
                    ),
                  if (user.role == 'admin')
                    const PopupMenuItem(
                      value: 'team_lead',
                      child: Text('Demote to Team Lead'),
                    ),
                ],
                onSelected: (value) {
                  if (value != null) {
                    _changeUserRole(user, value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role, {bool forBackground = false}) {
    final colors = AdaptiveColors.of(context);
    if (forBackground) {
      return colors.getRoleBackgroundColor(role);
    }
    return colors.getRoleColor(role);
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AdaptiveIcons.notificationsOutlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: Icon(AdaptiveIcons.doneAll, size: 18),
                  label: const Text('Mark all as read'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationCard(notification, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification notification, int index) {
    final isUnread = !notification.read;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(AdaptiveIcons.deleteOutlined, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification, index),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isUnread
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50)
            : null,
        child: InkWell(
          onTap: () => _onNotificationTap(notification, index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _getNotificationColor(notification.type),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'signup':
        return Colors.blue;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'signup':
        return AdaptiveIcons.personAdd;
      case 'alert':
        return AdaptiveIcons.warning;
      default:
        return AdaptiveIcons.notifications;
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Future<void> _onNotificationTap(AppNotification notification, int index) async {
    // Mark as read if unread
    if (!notification.read) {
      await SupabaseService.instance.markNotificationAsRead(notification.id);
      setState(() {
        _notifications[index] = notification.copyWith(read: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    }

    // If it's a signup notification, switch to pending tab
    if (notification.type == 'signup') {
      setState(() => _selectedTab = 'pending');
    }
  }

  Future<void> _markAllAsRead() async {
    await SupabaseService.instance.markAllNotificationsAsRead();
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(read: true))
          .toList();
      _unreadCount = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification, int index) async {
    await SupabaseService.instance.deleteNotification(notification.id);
    setState(() {
      _notifications.removeAt(index);
      if (!notification.read) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    }
  }

  // Cut Lists Tab
  Widget _buildCutListsTab() {
    return Column(
      children: [
        // Create button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createCutList,
              icon: Icon(AdaptiveIcons.add),
              label: const Text('Create Cut List'),
            ),
          ),
        ),

        // Cut lists
        Expanded(
          child: _cutLists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AdaptiveIcons.mapOutlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cut lists yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a cut list to assign voters to canvassers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _cutLists.length,
                  itemBuilder: (context, index) {
                    final cutList = _cutLists[index];
                    return _buildCutListCard(cutList);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCutListCard(CutList cutList) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showCutListDetails(cutList),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AdaptiveIcons.map,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cutList.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (cutList.description?.isNotEmpty == true)
                          Text(
                            cutList.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(AdaptiveIcons.edit, size: 20),
                            const SizedBox(width: 8),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(AdaptiveIcons.personAdd, size: 20),
                            const SizedBox(width: 8),
                            const Text('Assign Users'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(AdaptiveIcons.deleteOutlined, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCutList(cutList);
                          break;
                        case 'assign':
                          _showAssignmentDialog(cutList);
                          break;
                        case 'delete':
                          _deleteCutList(cutList);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCutListStat(
                    AdaptiveIcons.people,
                    '${cutList.voterCount} voters',
                  ),
                  const SizedBox(width: 16),
                  _buildCutListStat(
                    AdaptiveIcons.calendarToday,
                    DateFormat('MMM d, y').format(cutList.createdAt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCutListStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Future<void> _createCutList() async {
    final result = await Navigator.push<CutList>(
      context,
      platformPageRoute(
        context: context,
        builder: (_) => const CutListCreatorScreen(),
      ),
    );

    if (result != null) {
      _loadData();
    }
  }

  Future<void> _editCutList(CutList cutList) async {
    final result = await Navigator.push<CutList>(
      context,
      platformPageRoute(
        context: context,
        builder: (_) => CutListCreatorScreen(existingCutList: cutList),
      ),
    );

    if (result != null) {
      _loadData();
    }
  }

  Future<void> _showCutListDetails(CutList cutList) async {
    // Load assignments for this cut list
    final assignments = await SupabaseService.instance.fetchCutListAssignments(cutList.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cutList.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(AdaptiveIcons.close),
                      ),
                    ],
                  ),
                  if (cutList.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      cutList.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCutListStat(AdaptiveIcons.people, '${cutList.voterCount} voters'),
                      const SizedBox(width: 16),
                      _buildCutListStat(
                        AdaptiveIcons.personOutlined,
                        '${assignments.length} assigned',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Assigned Canvassers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAssignmentDialog(cutList);
                    },
                    icon: Icon(AdaptiveIcons.personAdd, size: 18),
                    label: const Text('Assign'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: assignments.isEmpty
                  ? Center(
                      child: Text(
                        'No canvassers assigned yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = assignments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (assignment.userName ?? assignment.userEmail ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(assignment.userName ?? assignment.userEmail ?? 'Unknown'),
                          subtitle: assignment.userName != null
                              ? Text(assignment.userEmail ?? '')
                              : null,
                          trailing: IconButton(
                            icon: Icon(AdaptiveIcons.removeCircleOutline, color: Colors.red),
                            onPressed: () async {
                              await SupabaseService.instance.unassignCutListFromUser(
                                cutList.id,
                                assignment.userId,
                              );
                              Navigator.pop(context);
                              _showCutListDetails(cutList);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignmentDialog(CutList cutList) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get all approved users who can be assigned (canvassers and team_leads)
      final assignableUsers = _allUsers.where((u) =>
        u.role == 'canvasser' || u.role == 'team_lead'
      ).toList();

      // Get existing assignments
      final assignments = await SupabaseService.instance.fetchCutListAssignments(cutList.id);
      final assignedUserIds = assignments.map((a) => a.userId).toSet();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Return format: "add:userId" or "remove:userId"
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Assign "${cutList.name}" to'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: assignableUsers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No canvassers or team leads available.\nApprove users first in the Users tab.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: assignableUsers.length,
                    itemBuilder: (context, index) {
                      final user = assignableUsers[index];
                      final isAssigned = assignedUserIds.contains(user.id);

                      return ListTile(
                        leading: Builder(
                          builder: (context) {
                            final colors = AdaptiveColors.of(context);
                            return CircleAvatar(
                              backgroundColor: isAssigned
                                  ? colors.successLight
                                  : Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                isAssigned ? AdaptiveIcons.check : AdaptiveIcons.person,
                                color: isAssigned
                                    ? colors.success
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                        title: Text(user.displayName ?? user.email),
                        subtitle: Row(
                          children: [
                            Expanded(child: Text(user.email)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role, forBackground: true),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isAssigned
                            ? Icon(AdaptiveIcons.removeCircle, color: Colors.red)
                            : Icon(AdaptiveIcons.addCircleOutline),
                        onTap: () => Navigator.pop(
                          context,
                          isAssigned ? 'remove:${user.id}' : 'add:${user.id}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result != null) {
        final parts = result.split(':');
        final action = parts[0];
        final userId = parts[1];

        bool success;
        String message;

        if (action == 'remove') {
          success = await SupabaseService.instance.unassignCutListFromUser(cutList.id, userId);
          message = success ? 'User removed from cut list' : 'Failed to remove user';
        } else {
          success = await SupabaseService.instance.assignCutListToUser(cutList.id, userId);
          message = success ? 'User assigned to cut list' : 'Failed to assign user';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          if (success) {
            _loadData(); // Refresh data
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteCutList(CutList cutList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cut List'),
        content: Text(
          'Are you sure you want to delete "${cutList.name}"? '
          'This will remove all voter assignments for this cut list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteCutList(cutList.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cut list "${cutList.name}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting cut list: $e')),
          );
        }
      }
    }
  }
}
