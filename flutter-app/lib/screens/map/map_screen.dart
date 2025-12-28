import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/voter.dart';
import '../../models/enums/map_filter_option.dart';
import '../../models/enums/canvass_result.dart';
import '../../providers/voter_provider.dart';
import '../../services/location_service.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/adaptive_icons.dart';
import '../voters/voter_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  MapFilterOption _filter = MapFilterOption.notContacted;
  List<Marker> _markers = [];
  bool _isLoading = true;
  LatLng? _currentLocation;

  static const LatLng _defaultCenter = LatLng(33.4484, -112.0740); // Phoenix, AZ - will be configurable
  static const int _maxPins = 500;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('map');
    _initLocation();
  }

  Future<void> _initLocation() async {
    final location = await LocationService.instance.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = LatLng(location.latitude, location.longitude);
      });
    }
    _updateMarkers();
  }

  void _updateMarkers() {
    final voterState = ref.read(voterProvider);
    _updateMarkersFromVoters(voterState.voters);
  }

  void _updateMarkersFromVoters(List<Voter> voters) {
    final filteredVoters = _filterVoters(voters);
    final limitedVoters = filteredVoters.take(_maxPins).toList();

    setState(() {
      _markers = limitedVoters.map((voter) => _createMarker(voter)).toList();
      _isLoading = false;
    });

    AnalyticsService.instance.trackFilter(_filter.displayName, 'map');
  }

  List<Voter> _filterVoters(List<Voter> voters) {
    switch (_filter) {
      case MapFilterOption.notContacted:
        return voters.where((v) => v.canvassResult == CanvassResult.notContacted).toList();
      case MapFilterOption.contacted:
        return voters.where((v) => v.canvassResult != CanvassResult.notContacted).toList();
      case MapFilterOption.supportive:
        return voters.where((v) => v.canvassResult.isSupportive).toList();
      case MapFilterOption.opposed:
        return voters.where((v) => v.canvassResult.isNegative).toList();
      case MapFilterOption.democrats:
        return voters.where((v) => v.partyDescription.toLowerCase().contains('democrat')).toList();
      case MapFilterOption.republicans:
        return voters.where((v) => v.partyDescription.toLowerCase().contains('republic')).toList();
      case MapFilterOption.independents:
        return voters.where((v) {
          final party = v.partyDescription.toLowerCase();
          return !party.contains('democrat') && !party.contains('republic');
        }).toList();
      case MapFilterOption.livesAtProperty:
        return voters.where((v) => !v.livesElsewhere).toList();
      case MapFilterOption.absenteeOwners:
        return voters.where((v) => v.livesElsewhere).toList();
      case MapFilterOption.mailVoters:
        return voters.where((v) => v.isMailVoter).toList();
      case MapFilterOption.nearby:
        if (_currentLocation == null) return voters;
        final sorted = List<Voter>.from(voters)
          ..sort((a, b) {
            final distA = _calculateDistance(a);
            final distB = _calculateDistance(b);
            return distA.compareTo(distB);
          });
        return sorted.take(100).toList();
      case MapFilterOption.all:
        return voters;
    }
  }

  double _calculateDistance(Voter voter) {
    if (_currentLocation == null || voter.latitude == 0) return double.infinity;
    final lat1 = _currentLocation!.latitude;
    final lon1 = _currentLocation!.longitude;
    final lat2 = voter.latitude;
    final lon2 = voter.longitude;
    return ((lat2 - lat1) * (lat2 - lat1) + (lon2 - lon1) * (lon2 - lon1));
  }

  Marker _createMarker(Voter voter) {
    return Marker(
      point: LatLng(voter.latitude, voter.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showVoterQuickInfo(voter),
        child: Container(
          decoration: BoxDecoration(
            color: _getPartyColor(voter.partyDescription),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000), // 0.3 alpha black
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            AdaptiveIcons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _openVoterDetail(Voter voter) {
    Navigator.push(
      context,
      platformPageRoute(context: context, builder: (_) => VoterDetailScreen(voter: voter)),
    );
  }

  void _showVoterQuickInfo(Voter voter) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(voter.canvassResult),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    voter.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              voter.fullAddress,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickInfoChip(
                  voter.canvassResult.displayName,
                  _getStatusColor(voter.canvassResult),
                ),
                if (voter.partyDescription.isNotEmpty)
                  _buildQuickInfoChip(
                    voter.partyDescription,
                    _getPartyColor(voter.partyDescription),
                  ),
                if (voter.isMailVoter)
                  _buildQuickInfoChip(
                    'Mail Voter',
                    Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openVoterDetail(voter);
                },
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(CanvassResult result) {
    switch (result) {
      case CanvassResult.supportive:
      case CanvassResult.strongSupport:
        return Colors.green;
      case CanvassResult.undecided:
      case CanvassResult.leaning:
        return Colors.orange;
      case CanvassResult.opposed:
      case CanvassResult.stronglyOpposed:
        return Colors.red;
      case CanvassResult.contacted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPartyColor(String party) {
    switch (party) {
      case 'Democratic':
        return Colors.blue;
      case 'Republican':
        return Colors.red;
      case 'Libertarian':
        return Colors.amber.shade700;
      case 'Green':
        return Colors.green;
      case 'Registered Independent':
        return Colors.purple;
      case 'Non-Partisan':
        return Colors.teal;
      case 'Liberal':
        return Colors.lightBlue;
      case 'Other':
        return Colors.orange;
      default: // empty string or unknown
        return Colors.grey;
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14);
    }
  }

  Future<void> _loadVotersInVisibleArea() async {
    setState(() => _isLoading = true);

    try {
      final bounds = _mapController.camera.visibleBounds;
      final voters = await SupabaseService.instance.fetchVotersByRegion(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLon: bounds.west,
        maxLon: bounds.east,
        limit: _maxPins,
      );

      final filteredVoters = _filterVoters(voters);

      setState(() {
        _markers = filteredVoters.map((voter) => _createMarker(voter)).toList();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${_markers.length} voters in this area'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voters: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for voter changes and update markers
    ref.listen<VoterState>(voterProvider, (previous, next) {
      if (previous?.voters != next.voters) {
        _updateMarkersFromVoters(next.voters);
      }
    });

    return PlatformScaffold(
      body: Material(
        child: Stack(
        children: [
          // Map - Use OpenStreetMap for web compatibility
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoiam90cmE3IiwiYSI6ImNtamFyNnN4bzAwNjQzam9kcnY5dTZuam0ifQ.UDdH9lU6cQKUXqU4L2HqpQ',
                tileSize: 512,
                zoomOffset: -1,
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Filter dropdown
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 80,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MapFilterOption>(
                    value: _filter,
                    isExpanded: true,
                    items: MapFilterOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filter = value;
                          _isLoading = true;
                        });
                        _updateMarkers();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // Pin count
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${_markers.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
          ),

          // Location and Load buttons
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'load',
                  onPressed: _loadVotersInVisibleArea,
                  child: Icon(AdaptiveIcons.refresh),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _centerOnLocation,
                  child: Icon(AdaptiveIcons.myLocation),
                ),
              ],
            ),
          ),

          // Legend
          Positioned(
            bottom: 24,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(Colors.blue, 'Democrat'),
                    _buildLegendItem(Colors.red, 'Republican'),
                    _buildLegendItem(Colors.teal, 'Non-Partisan'),
                    _buildLegendItem(Colors.purple, 'Independent'),
                    _buildLegendItem(Colors.grey, 'Unknown'),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
