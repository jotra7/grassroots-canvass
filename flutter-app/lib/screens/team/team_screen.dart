import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/cut_list.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/adaptive_icons.dart';
import '../../utils/adaptive_colors.dart';
import '../admin/cut_list_creator_screen.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  List<CutList> _cutLists = [];
  List<UserProfile> _canvassers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('team');
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final cutLists = await SupabaseService.instance.fetchCutLists();
    final allUsers = await SupabaseService.instance.getAllUsers();
    final canvassers = allUsers.where((u) => u.role == 'canvasser').toList();

    setState(() {
      _cutLists = cutLists;
      _canvassers = canvassers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Team Management'),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(AdaptiveIcons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Material(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Create cut list button
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
            ),
      ),
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
      // Load all users and get existing assignments
      final allUsers = await SupabaseService.instance.getAllUsers();
      final assignableUsers = allUsers.where((u) =>
        u.role == 'canvasser' || u.role == 'team_lead'
      ).toList();

      final assignments = await SupabaseService.instance.fetchCutListAssignments(cutList.id);
      final assignedUserIds = assignments.map((a) => a.userId).toSet();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      final selectedUserId = await showDialog<String>(
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
                      child: Text('No canvassers or team leads available.\nApprove users first.'),
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
                            Builder(
                              builder: (context) {
                                final colors = AdaptiveColors.of(context);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: user.role == 'team_lead'
                                        ? colors.teamLeadLight
                                        : colors.canvasserLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: user.role == 'team_lead'
                                          ? colors.teamLeadColor
                                          : colors.canvasserColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: Builder(
                          builder: (context) {
                            final colors = AdaptiveColors.of(context);
                            return isAssigned
                                ? Icon(AdaptiveIcons.checkCircle, color: colors.success)
                                : Icon(AdaptiveIcons.addCircleOutline);
                          },
                        ),
                        onTap: isAssigned ? null : () => Navigator.pop(context, user.id),
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

      if (selectedUserId != null) {
        final success = await SupabaseService.instance.assignCutListToUser(cutList.id, selectedUserId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User assigned to cut list')),
            );
            _loadData(); // Refresh data
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to assign user')),
            );
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
