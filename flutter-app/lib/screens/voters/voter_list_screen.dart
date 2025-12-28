import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voter_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums/filter_option.dart';
import '../../models/enums/sort_option.dart';
import '../../widgets/voter_row.dart';
import '../../widgets/stat_badge.dart';
import '../../services/csv_service.dart';
import '../../utils/adaptive_icons.dart';
import '../../utils/adaptive_colors.dart';
import 'voter_detail_screen.dart';
import 'voter_load_screen.dart';
import '../route/walking_list_screen.dart';
import '../export/pdf_preview_screen.dart';

class VoterListScreen extends ConsumerStatefulWidget {
  const VoterListScreen({super.key});

  @override
  ConsumerState<VoterListScreen> createState() => _VoterListScreenState();
}

class _VoterListScreenState extends ConsumerState<VoterListScreen> {
  final _searchController = TextEditingController();
  final _minVotesController = TextEditingController();
  final _maxVotesController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _minVotesController.dispose();
    _maxVotesController.dispose();
    super.dispose();
  }

  void _showLoadScreen(BuildContext context) {
    Navigator.push(
      context,
      platformPageRoute(context: context, builder: (_) => const VoterLoadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voterState = ref.watch(voterProvider);
    final voterNotifier = ref.read(voterProvider.notifier);
    final authState = ref.watch(authProvider);
    final canManageCutLists = authState.canManageCutLists;

    return Scaffold(
      appBar: AppBar(
        title: Text(canManageCutLists ? 'Voters' : 'My Assigned Voters'),
        actions: [
          // Only show load voters button for admins and team leads
          if (canManageCutLists)
            IconButton(
              icon: Icon(AdaptiveIcons.download),
              onPressed: () => _showLoadScreen(context),
              tooltip: 'Load Voters',
            ),
          // Refresh button for canvassers
          if (!canManageCutLists)
            IconButton(
              icon: Icon(AdaptiveIcons.refresh),
              onPressed: () => voterNotifier.loadVoters(forceRefresh: true),
              tooltip: 'Refresh',
            ),
          if (voterState.isSelectMode)
            IconButton(
              icon: Icon(AdaptiveIcons.close),
              onPressed: () => voterNotifier.toggleSelectMode(),
            )
          else
            IconButton(
              icon: Icon(AdaptiveIcons.checklist),
              onPressed: () => voterNotifier.toggleSelectMode(),
              tooltip: 'Select Mode',
            ),
        ],
      ),
      // Only show route button for reasonable walking distances (50 or fewer voters)
      floatingActionButton: voterState.filteredVoters.isNotEmpty &&
              voterState.filteredVoters.length <= 50 &&
              !voterState.isSelectMode
          ? FloatingActionButton.extended(
              onPressed: () => _startWalkingRoute(context),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Start Route'),
            )
          : null,
      body: Material(
        child: Column(
          children: [
            // Offline indicator
            if (voterState.isOffline)
            Builder(
              builder: (context) {
                final colors = AdaptiveColors.of(context);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: colors.warningLight,
                  child: Row(
                    children: [
                      Icon(AdaptiveIcons.cloudOff, size: 16, color: colors.warningText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline mode - viewing cached data',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.warningText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => voterNotifier.loadVoters(forceRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatBadge(
                  value: voterState.totalVoters.toString(),
                  label: 'Total',
                  color: Colors.blue,
                ),
                StatBadge(
                  value: voterState.contactedCount.toString(),
                  label: 'Contacted',
                  color: Colors.orange,
                ),
                StatBadge(
                  value: voterState.supportiveCount.toString(),
                  label: 'Supportive',
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // Filter and Sort row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SortOption>(
                    value: voterState.sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) voterNotifier.setSort(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<FilterOption>(
                    value: voterState.filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: FilterOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) voterNotifier.setFilter(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Min/Max Votes filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minVotesController,
                    decoration: InputDecoration(
                      labelText: 'Min Acres',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: _minVotesController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(AdaptiveIcons.clear, size: 16),
                              onPressed: () {
                                _minVotesController.clear();
                                voterNotifier.setMinVotes(null);
                              },
                            )
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      voterNotifier.setMinVotes(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxVotesController,
                    decoration: InputDecoration(
                      labelText: 'Max Acres',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: _maxVotesController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(AdaptiveIcons.clear, size: 16),
                              onPressed: () {
                                _maxVotesController.clear();
                                voterNotifier.setMaxVotes(null);
                              },
                            )
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      voterNotifier.setMaxVotes(parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or address...',
                prefixIcon: Icon(AdaptiveIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(AdaptiveIcons.clear),
                        onPressed: () {
                          _searchController.clear();
                          voterNotifier.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (value) => voterNotifier.setSearchQuery(value),
            ),
          ),
          const SizedBox(height: 8),

          // Bulk actions toolbar
          if (voterState.isSelectMode && voterState.selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Text(
                    '${voterState.selectedIds.length} selected',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => voterNotifier.selectAll(),
                    child: const Text('All'),
                  ),
                  TextButton(
                    onPressed: () => voterNotifier.clearSelection(),
                    child: const Text('Clear'),
                  ),
                  IconButton(
                    icon: Icon(AdaptiveIcons.phone),
                    onPressed: () => _copyPhoneNumbers(context),
                    tooltip: 'Copy Phone Numbers',
                  ),
                  IconButton(
                    icon: Icon(AdaptiveIcons.download),
                    onPressed: () => _exportCSV(context),
                    tooltip: 'Export CSV',
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: () => _exportPDF(context),
                    tooltip: 'Export PDF Walk Sheet',
                  ),
                ],
              ),
            ),

          // Voter list
          Expanded(
            child: voterState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Loading... ${voterState.loadingProgress} voters'),
                      ],
                    ),
                  )
                : voterState.voters.isEmpty
                    ? _buildEmptyState(context, voterNotifier, ref.watch(authProvider).isDemoMode)
                    : RefreshIndicator(
                        onRefresh: () => voterNotifier.loadVoters(),
                        child: ListView.builder(
                          itemCount: voterState.filteredVoters.length,
                          itemBuilder: (context, index) {
                            final voter = voterState.filteredVoters[index];
                            return VoterRow(
                              voter: voter,
                              isSelected: voterState.selectedIds.contains(voter.uniqueId),
                              isSelectMode: voterState.isSelectMode,
                              onTap: () {
                                if (voterState.isSelectMode) {
                                  voterNotifier.toggleSelection(voter.uniqueId);
                                } else {
                                  Navigator.push(
                                    context,
                                    platformPageRoute(
                                      context: context,
                                      builder: (_) => VoterDetailScreen(voter: voter),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                if (!voterState.isSelectMode) {
                                  voterNotifier.toggleSelectMode();
                                  voterNotifier.toggleSelection(voter.uniqueId);
                                }
                              },
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, VoterNotifier notifier, bool isDemoMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AdaptiveIcons.peopleOutlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Voters Loaded',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isDemoMode
                ? 'Tap below to load demo voters'
                : 'Choose how to load voters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          if (isDemoMode)
            FilledButton.icon(
              onPressed: () => notifier.loadVoters(),
              icon: Icon(AdaptiveIcons.cloudDownload),
              label: const Text('Load Demo Voters'),
            )
          else ...[
            FilledButton.icon(
              onPressed: () => _showLoadScreen(context),
              icon: Icon(AdaptiveIcons.filter),
              label: const Text('Load Filtered Voters'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => notifier.loadVoters(),
              icon: Icon(AdaptiveIcons.cloudDownload),
              label: const Text('Load All Voters'),
            ),
          ],
        ],
      ),
    );
  }

  void _copyPhoneNumbers(BuildContext context) {
    final voterNotifier = ref.read(voterProvider.notifier);
    final selected = voterNotifier.getSelectedVoters();
    final numbers = CSVService.exportPhoneNumbers(selected);

    Clipboard.setData(ClipboardData(text: numbers));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selected.length} phone numbers copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportCSV(BuildContext context) {
    final voterNotifier = ref.read(voterProvider.notifier);
    final selected = voterNotifier.getSelectedVoters();
    final csv = CSVService.exportResults(selected);

    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selected.length} voters exported to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportPDF(BuildContext context) {
    final voterNotifier = ref.read(voterProvider.notifier);
    final selected = voterNotifier.getSelectedVoters();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select voters to export')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          cutListName: 'Selected Voters',
          voters: selected,
        ),
      ),
    );
  }

  void _startWalkingRoute(BuildContext context) {
    final voterState = ref.read(voterProvider);
    final voters = voterState.filteredVoters;

    if (voters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No voters available for route')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkingListScreen(
          voters: voters,
          cutListName: 'Walking Route',
        ),
      ),
    );
  }
}
