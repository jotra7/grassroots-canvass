import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/voter.dart';
import '../../models/walking_route.dart';
import '../../models/enums/canvass_result.dart';
import '../../services/route_service.dart';
import '../../services/location_service.dart';
import '../../providers/voter_provider.dart';
import '../../widgets/party_badge.dart';
import '../voters/voter_detail_screen.dart';

class WalkingListScreen extends ConsumerStatefulWidget {
  final List<Voter> voters;
  final String? cutListName;

  const WalkingListScreen({
    super.key,
    required this.voters,
    this.cutListName,
  });

  @override
  ConsumerState<WalkingListScreen> createState() => _WalkingListScreenState();
}

class _WalkingListScreenState extends ConsumerState<WalkingListScreen> {
  late WalkingRoute _route;
  final RouteService _routeService = RouteService();
  bool _isLoading = true;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }

  Future<void> _initializeRoute() async {
    setState(() => _isLoading = true);

    // Get current location
    try {
      final position = await LocationService.instance.getCurrentLocation();
      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      // Default to first voter's location or Phoenix center
      if (widget.voters.isNotEmpty && widget.voters.first.hasValidLocation) {
        _currentLocation = LatLng(
          widget.voters.first.latitude,
          widget.voters.first.longitude,
        );
      } else {
        _currentLocation = const LatLng(33.4484, -112.0740); // Phoenix
      }
    }

    // Filter to only uncontacted voters
    final uncontactedVoters = widget.voters
        .where((v) => v.canvassResult == CanvassResult.notContacted)
        .toList();

    // Optimize route
    final optimizedVoters = _routeService.optimizeRoute(
      uncontactedVoters.isEmpty ? widget.voters : uncontactedVoters,
      _currentLocation!,
    );

    setState(() {
      _route = WalkingRoute(
        voters: optimizedVoters,
        startPoint: _currentLocation!,
      );
      _isLoading = false;
    });
  }

  void _navigateToCurrentVoter() {
    final voter = _route.currentVoter;
    if (voter != null && voter.hasValidLocation) {
      _routeService.openInMaps(
        LatLng(voter.latitude, voter.longitude),
        label: voter.displayName,
      );
    }
  }

  void _openVoterDetail() {
    final voter = _route.currentVoter;
    if (voter != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoterDetailScreen(voter: voter),
        ),
      ).then((_) {
        // Refresh voter data when returning
        _refreshCurrentVoter();
      });
    }
  }

  Future<void> _refreshCurrentVoter() async {
    // Refresh voter data from provider
    final voterState = ref.read(voterProvider);
    final currentVoter = _route.currentVoter;
    if (currentVoter != null) {
      final updatedVoter = voterState.voters.firstWhere(
        (v) => v.uniqueId == currentVoter.uniqueId,
        orElse: () => currentVoter,
      );

      // Check if voter was contacted
      if (updatedVoter.canvassResult != CanvassResult.notContacted) {
        setState(() {
          _route.markCurrentCompleted();
        });
      }
    }
  }

  void _markCompletedAndNext() {
    setState(() {
      _route.markCurrentCompleted();
      _route.moveToNext();
    });
  }

  void _goToNext() {
    setState(() {
      _route.moveToNext();
    });
  }

  void _goToPrevious() {
    setState(() {
      _route.moveToPrevious();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Walking Route')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_route.voters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Walking Route')),
        body: const Center(
          child: Text('No voters to visit'),
        ),
      );
    }

    final currentVoter = _route.currentVoter!;
    final totalDistance = _routeService.calculateTotalDistance(_route.voters);
    final walkTime = _routeService.estimateWalkTime(totalDistance);

    // Calculate distance to current voter
    double? distanceToCurrent;
    if (_currentLocation != null && currentVoter.hasValidLocation) {
      distanceToCurrent = _routeService.calculateDistance(
        _currentLocation!,
        LatLng(currentVoter.latitude, currentVoter.longitude),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cutListName ?? 'Walking Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _routeService.openRouteInMaps(
              _route.remainingVoters,
              startPoint: _currentLocation,
            ),
            tooltip: 'Open full route in Maps',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_route.completedCount} of ${_route.totalCount} completed',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${_routeService.formatDistance(totalDistance)} · ${_routeService.formatDuration(walkTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _route.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          // Current voter card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Position indicator
                  Text(
                    'Stop ${_route.currentIndex + 1} of ${_route.totalCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main voter card
                  Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: _openVoterDetail,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and party
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentVoter.displayName,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                PartyBadge(party: currentVoter.partyDescription),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Address
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentVoter.fullAddress,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),

                            if (distanceToCurrent != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    size: 20,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_routeService.formatDistance(distanceToCurrent)} away',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Status badge if completed
                            if (_route.isCurrentCompleted) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openVoterDetail,
                                    icon: const Icon(Icons.person),
                                    label: const Text('Details'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: currentVoter.hasValidLocation
                                        ? _navigateToCurrentVoter
                                        : null,
                                    icon: const Icon(Icons.navigation),
                                    label: const Text('Navigate'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick action - Mark complete and move to next
                  if (!_route.isCurrentCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _markCompletedAndNext,
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Complete & Next'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Next voter preview
                  if (_route.nextVoter != null) ...[
                    Text(
                      'Next: ${_route.nextVoter!.displayName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _route.nextVoter!.fullAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _route.isAtStart ? null : _goToPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _route.isAtEnd ? null : _goToNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
