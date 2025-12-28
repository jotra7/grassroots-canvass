import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voter_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/adaptive_icons.dart';

class VoterLoadScreen extends ConsumerStatefulWidget {
  const VoterLoadScreen({super.key});

  @override
  ConsumerState<VoterLoadScreen> createState() => _VoterLoadScreenState();
}

class _VoterLoadScreenState extends ConsumerState<VoterLoadScreen> {
  final _minVotesController = TextEditingController(text: '0');
  final _maxVotesController = TextEditingController(text: '100');
  String _selectedParty = 'All';
  int _minVoterScore = 0;
  bool _isLoading = false;
  int? _estimatedCount;

  double get _minVotes => double.tryParse(_minVotesController.text) ?? 0;
  double get _maxVotes => double.tryParse(_maxVotesController.text) ?? 100;

  final List<String> _partyOptions = [
    'All',
    'Democratic',
    'Republican',
    'Non-Partisan',
    'Registered Independent',
    'Libertarian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _estimateCount();
  }

  @override
  void dispose() {
    _minVotesController.dispose();
    _maxVotesController.dispose();
    super.dispose();
  }

  Future<void> _estimateCount() async {
    // This could be optimized with a count query
    setState(() => _estimatedCount = null);
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);

    try {
      final voters = await SupabaseService.instance.fetchVotersFiltered(
        minVotes: _minVotes,
        maxVotes: _maxVotes,
        party: _selectedParty == 'All' ? null : _selectedParty,
        minVoterScore: _minVoterScore > 0 ? _minVoterScore : null,
      );

      ref.read(voterProvider.notifier).setVoters(voters);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${voters.length} voters')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voters: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllVoters() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(voterProvider.notifier).loadVoters();

      if (mounted) {
        final count = ref.read(voterProvider).voters.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded $count voters')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voters: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Only admins and team leads can access this screen
    if (!authState.canManageCutLists) {
      return PlatformScaffold(
        appBar: PlatformAppBar(title: const Text('Access Denied')),
        body: Material(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AdaptiveIcons.lock, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Team Lead or Admin access required'),
                const SizedBox(height: 8),
                PlatformTextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Load Voters'),
      ),
      body: Material(
        child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading voters...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick load option
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.flash_on, color: Colors.orange),
                      title: const Text('Load All Voters'),
                      subtitle: const Text('Load entire voter database'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _loadAllVoters,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Or Filter By:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Votes/Acres Range
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.landscape, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Acres (Votes)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minVotesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Min',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('to'),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _maxVotesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Max',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('0.1+'),
                                onPressed: () {
                                  setState(() {
                                    _minVotesController.text = '0.1';
                                    _maxVotesController.text = '100';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('0.5+'),
                                onPressed: () {
                                  setState(() {
                                    _minVotesController.text = '0.5';
                                    _maxVotesController.text = '100';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('1+'),
                                onPressed: () {
                                  setState(() {
                                    _minVotesController.text = '1';
                                    _maxVotesController.text = '100';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('5+'),
                                onPressed: () {
                                  setState(() {
                                    _minVotesController.text = '5';
                                    _maxVotesController.text = '100';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('All'),
                                onPressed: () {
                                  setState(() {
                                    _minVotesController.text = '0';
                                    _maxVotesController.text = '100';
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Party Filter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.how_to_vote, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Party',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _partyOptions.map((party) {
                              final isSelected = party == _selectedParty;
                              return FilterChip(
                                label: Text(party),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedParty = party);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Voter Score
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Minimum Voter Score',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _minVoterScore == 0
                                ? 'Any score'
                                : '$_minVoterScore+',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            value: _minVoterScore.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _minVoterScore == 0
                                ? 'Any'
                                : _minVoterScore.toString(),
                            onChanged: (value) {
                              setState(() => _minVoterScore = value.toInt());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Load Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loadVoters,
                      icon: const Icon(Icons.download),
                      label: const Text('Load Filtered Voters'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }
}
