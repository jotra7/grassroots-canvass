import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/voter.dart';
import '../../models/cut_list.dart';
import '../../services/supabase_service.dart';

class CutListCreatorScreen extends ConsumerStatefulWidget {
  final CutList? existingCutList; // For editing existing cut lists

  const CutListCreatorScreen({super.key, this.existingCutList});

  @override
  ConsumerState<CutListCreatorScreen> createState() => _CutListCreatorScreenState();
}

class _CutListCreatorScreenState extends ConsumerState<CutListCreatorScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<LatLng> _polygonPoints = [];
  List<Voter> _allVoters = [];
  List<Voter> _selectedVoters = [];
  bool _isDrawing = true;
  bool _isLoading = false;
  bool _isSaving = false;
  int? _originalVoterCount; // Stored count when editing existing cut list

  // Filter options
  Set<String> _selectedParties = {}; // Multiple parties can be selected
  bool _livesAtPropertyOnly = false;
  bool _mailVotersOnly = false;
  bool _filtersExpanded = false;

  static const LatLng _defaultCenter = LatLng(33.4484, -112.0740); // Phoenix, AZ
  static const List<String> _partyOptions = [
    'All Parties',
    'Democratic',
    'Republican',
    'Libertarian',
    'Green',
    'Registered Independent',
    'Non-Partisan',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // If editing existing cut list, populate fields BEFORE loading voters
    if (widget.existingCutList != null) {
      _nameController.text = widget.existingCutList!.name;
      _descriptionController.text = widget.existingCutList!.description ?? '';
      _originalVoterCount = widget.existingCutList!.voterCount;
      if (widget.existingCutList!.boundaryPolygon != null) {
        _polygonPoints = List.from(widget.existingCutList!.boundaryPolygon!);
        _isDrawing = false;
        print('[CutListCreator] Loaded polygon with ${_polygonPoints.length} points:');
        for (int i = 0; i < _polygonPoints.length; i++) {
          print('[CutListCreator]   Point $i: lat=${_polygonPoints[i].latitude}, lng=${_polygonPoints[i].longitude}');
        }
      }
    }

    // Load voters after polygon is set (so it can find voters in existing polygon)
    _loadVoters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);

    try {
      // Always fetch voters with valid coordinates for cut list creation
      // This ensures consistent counts between web admin and mobile app
      // The query filters: NOT NULL latitude AND NOT NULL longitude
      _allVoters = await SupabaseService.instance.fetchVotersForCutListCreation(
        onProgress: (count) {
          print('[CutListCreator] Loading voters: $count');
        },
      );

      print('[CutListCreator] Loaded ${_allVoters.length} total voters');

      // If editing, find voters in the existing polygon
      if (_polygonPoints.isNotEmpty) {
        print('[CutListCreator] Polygon has ${_polygonPoints.length} points, updating selected voters');
        _updateSelectedVoters();
        print('[CutListCreator] Selected ${_selectedVoters.length} voters in polygon');
      }
    } catch (e) {
      print('[CutListCreator] Error loading voters: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voters: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isDrawing) return;

    setState(() {
      _polygonPoints.add(point);
      if (_polygonPoints.length >= 3) {
        _updateSelectedVoters();
      }
    });
  }

  void _updateSelectedVoters() {
    if (_polygonPoints.length < 3) {
      setState(() {
        _selectedVoters = [];
      });
      return;
    }

    // Debug: Show polygon bounds
    double minPolyLat = double.infinity, maxPolyLat = -double.infinity;
    double minPolyLng = double.infinity, maxPolyLng = -double.infinity;
    for (final p in _polygonPoints) {
      if (p.latitude < minPolyLat) minPolyLat = p.latitude;
      if (p.latitude > maxPolyLat) maxPolyLat = p.latitude;
      if (p.longitude < minPolyLng) minPolyLng = p.longitude;
      if (p.longitude > maxPolyLng) maxPolyLng = p.longitude;
    }
    print('[CutList] Polygon bounds: lat($minPolyLat to $maxPolyLat), lng($minPolyLng to $maxPolyLng)');

    // Debug: Show voter bounds
    final votersWithCoords = _allVoters.where((v) => v.latitude != 0 && v.longitude != 0).toList();
    print('[CutList] Voters with valid coords: ${votersWithCoords.length} of ${_allVoters.length}');

    if (votersWithCoords.isNotEmpty) {
      double minVoterLat = double.infinity, maxVoterLat = -double.infinity;
      double minVoterLng = double.infinity, maxVoterLng = -double.infinity;
      for (final v in votersWithCoords) {
        if (v.latitude < minVoterLat) minVoterLat = v.latitude;
        if (v.latitude > maxVoterLat) maxVoterLat = v.latitude;
        if (v.longitude < minVoterLng) minVoterLng = v.longitude;
        if (v.longitude > maxVoterLng) maxVoterLng = v.longitude;
      }
      print('[CutList] Voter bounds: lat($minVoterLat to $maxVoterLat), lng($minVoterLng to $maxVoterLng)');
    }

    // First, get all voters in the polygon
    var votersInPolygon = _allVoters.where((voter) {
      if (voter.latitude == 0 || voter.longitude == 0) return false;
      return _isPointInPolygon(LatLng(voter.latitude, voter.longitude), _polygonPoints);
    }).toList();

    print('[CutList] Voters in polygon (before filters): ${votersInPolygon.length}');

    // Apply party filter (if any parties selected)
    if (_selectedParties.isNotEmpty) {
      votersInPolygon = votersInPolygon.where((v) {
        final party = v.partyDescription;

        // Check if voter matches any selected party
        for (final selectedParty in _selectedParties) {
          if (selectedParty == 'Other') {
            final partyLower = party.toLowerCase();
            if (!partyLower.contains('democrat') &&
                !partyLower.contains('republic') &&
                !partyLower.contains('libertarian') &&
                !partyLower.contains('green') &&
                !partyLower.contains('independent') &&
                !partyLower.contains('non-partisan')) {
              return true;
            }
          } else if (party == selectedParty) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    if (_livesAtPropertyOnly) {
      votersInPolygon = votersInPolygon.where((v) => !v.livesElsewhere).toList();
    }

    if (_mailVotersOnly) {
      votersInPolygon = votersInPolygon.where((v) => v.isMailVoter).toList();
    }

    setState(() {
      _selectedVoters = votersInPolygon;
    });
  }

  /// Ray casting algorithm to check if point is inside polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _updateSelectedVoters();
      });
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _selectedVoters.clear();
      _isDrawing = true;
    });
  }

  void _finishDrawing() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 3 points to create a polygon')),
      );
      return;
    }
    setState(() => _isDrawing = false);
  }

  Future<void> _saveCutList() async {
    // Prevent multiple simultaneous saves
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the cut list')),
      );
      return;
    }

    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a polygon with at least 3 points')),
      );
      return;
    }

    // Set saving state immediately before any async work
    _isSaving = true;
    setState(() {});

    try {
      CutList? cutList;

      if (widget.existingCutList != null) {
        // Update existing cut list
        final updatedCutList = widget.existingCutList!.copyWith(
          name: name,
          description: _descriptionController.text.trim(),
          boundaryPolygon: _polygonPoints,
          voterCount: _selectedVoters.length,
          updatedAt: DateTime.now(),
        );

        final success = await SupabaseService.instance.updateCutList(updatedCutList);
        if (success) {
          cutList = updatedCutList;
          // Clear existing voters and add new ones (in case polygon changed)
          await SupabaseService.instance.clearCutListVoters(cutList.id);
          final voterIds = _selectedVoters.map((v) => v.uniqueId).toList();
          await SupabaseService.instance.addVotersToCutList(cutList.id, voterIds);
        }
      } else {
        // Create new cut list (set voterCount to 0 initially, update after adding voters)
        final newCutList = CutList(
          id: '', // Will be generated by Supabase
          name: name,
          description: _descriptionController.text.trim(),
          boundaryPolygon: _polygonPoints,
          voterCount: 0, // Will be updated after adding voters
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        cutList = await SupabaseService.instance.createCutList(newCutList);

        if (cutList != null) {
          // Add voters to the cut list
          final voterIds = _selectedVoters.map((v) => v.uniqueId).toList();
          await SupabaseService.instance.addVotersToCutList(cutList.id, voterIds);

          // Update voter count after adding voters to avoid double counting
          cutList = cutList.copyWith(voterCount: voterIds.length);
          await SupabaseService.instance.updateCutList(cutList);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingCutList != null
                ? 'Cut list updated with ${_selectedVoters.length} voters'
                : 'Cut list created with ${_selectedVoters.length} voters'
            ),
          ),
        );
        Navigator.pop(context, cutList);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving cut list: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCutList != null;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(isEditing ? 'Edit Cut List' : 'Create Cut List'),
        trailingActions: [
          if (!_isDrawing && _polygonPoints.length >= 3)
            PlatformTextButton(
              onPressed: _isSaving ? null : _saveCutList,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Material(
        child: Column(
        children: [
          // Map area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _polygonPoints.isNotEmpty
                        ? _polygonPoints.first
                        : _defaultCenter,
                    initialZoom: 12,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoiam90cmE3IiwiYSI6ImNtamFyNnN4bzAwNjQzam9kcnY5dTZuam0ifQ.UDdH9lU6cQKUXqU4L2HqpQ',
                      tileDimension: 512,
                      zoomOffset: -1,
                    ),

                    // Draw polygon
                    if (_polygonPoints.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _polygonPoints,
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                    // Draw polygon vertices and lines
                    if (_polygonPoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [..._polygonPoints, if (_polygonPoints.length >= 3) _polygonPoints.first],
                            color: Colors.blue,
                            strokeWidth: 2,
                          ),
                        ],
                      ),

                    // Polygon vertex markers
                    MarkerLayer(
                      markers: _polygonPoints.asMap().entries.map((entry) {
                        final index = entry.key;
                        final point = entry.value;
                        return Marker(
                          point: point,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: index == 0 ? Colors.green : Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Voter markers (show selected voters)
                    MarkerLayer(
                      markers: _selectedVoters.map((voter) {
                        return Marker(
                          point: LatLng(voter.latitude, voter.longitude),
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getPartyColor(voter.partyDescription),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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

                // Drawing instructions
                if (_isDrawing)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _polygonPoints.isEmpty
                                    ? 'Tap on the map to draw a polygon around the area you want to include'
                                    : 'Added ${_polygonPoints.length} point${_polygonPoints.length == 1 ? '' : 's'}. Tap to add more.',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Selected voter count
                Positioned(
                  top: _isDrawing ? 80 : 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show change indicator when editing and count differs
                          if (_originalVoterCount != null && _originalVoterCount != _selectedVoters.length)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_originalVoterCount',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: _selectedVoters.length > _originalVoterCount!
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedVoters.length}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedVoters.length > _originalVoterCount!
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '${_selectedVoters.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          const Text(
                            'voters',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Drawing controls
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDrawing && _polygonPoints.length >= 3)
                        FloatingActionButton.small(
                          heroTag: 'finish',
                          onPressed: _finishDrawing,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.check),
                        ),
                      // Only show undo button when actively drawing/editing
                      if (_polygonPoints.isNotEmpty && _isDrawing) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'undo',
                          onPressed: _undoLastPoint,
                          child: const Icon(Icons.undo),
                        ),
                      ],
                      // Only show clear button when editing existing cut list
                      if (_polygonPoints.isNotEmpty && widget.existingCutList != null) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'clear',
                          onPressed: _clearPolygon,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.delete),
                        ),
                      ],
                      if (!_isDrawing) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'edit',
                          onPressed: () => setState(() => _isDrawing = true),
                          child: const Icon(Icons.edit),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cut list details form - collapsible bottom panel
          Container(
            constraints: BoxConstraints(
              maxHeight: _filtersExpanded ? 400 : 180,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Cut List Name *',
                        hintText: 'e.g., North Phoenix Area',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Collapsible filter section
                    _buildCollapsibleFilters(),
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

  Widget _buildCollapsibleFilters() {
    final hasActiveFilters = _selectedParties.isNotEmpty ||
        _livesAtPropertyOnly ||
        _mailVotersOnly;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row - always visible, tappable to expand
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Voter count badge with change indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_originalVoterCount != null && _originalVoterCount != _selectedVoters.length)
                          ? (_selectedVoters.length > _originalVoterCount! ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2))
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _originalVoterCount != null && _originalVoterCount != _selectedVoters.length
                          ? '$_originalVoterCount → ${_selectedVoters.length} voters'
                          : '${_selectedVoters.length} voters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (_originalVoterCount != null && _originalVoterCount != _selectedVoters.length)
                            ? (_selectedVoters.length > _originalVoterCount! ? Colors.green.shade700 : Colors.orange.shade700)
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description field
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Brief description of this area',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  // Party filter chips (multi-select)
                  Text(
                    'Parties',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _partyOptions.where((p) => p != 'All Parties').map((party) {
                      final isSelected = _selectedParties.contains(party);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(party, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedParties.add(party);
                            } else {
                              _selectedParties.remove(party);
                            }
                            _updateSelectedVoters();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Other filter chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _livesAtPropertyOnly,
                        label: const Text('Lives Here'),
                        onSelected: (selected) {
                          setState(() {
                            _livesAtPropertyOnly = selected;
                            _updateSelectedVoters();
                          });
                        },
                      ),
                      FilterChip(
                        selected: _mailVotersOnly,
                        label: const Text('Mail Voters'),
                        onSelected: (selected) {
                          setState(() {
                            _mailVotersOnly = selected;
                            _updateSelectedVoters();
                          });
                        },
                      ),
                    ],
                  ),
                  if (_selectedVoters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildVoterSummary(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoterSummary() {
    // Count by party
    final partyCount = <String, int>{};
    for (final voter in _selectedVoters) {
      final party = voter.partyDescription.isEmpty ? 'Unknown' : voter.partyDescription;
      partyCount[party] = (partyCount[party] ?? 0) + 1;
    }

    // Sort by count
    final sortedParties = partyCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voter Breakdown',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sortedParties.take(5).map((entry) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  avatar: CircleAvatar(
                    backgroundColor: _getPartyColor(entry.key),
                    radius: 8,
                  ),
                  label: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
