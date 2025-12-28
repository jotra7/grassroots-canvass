import 'package:latlong2/latlong.dart';
import 'voter.dart';

/// Model representing an optimized walking route
class WalkingRoute {
  /// Ordered list of voters to visit
  final List<Voter> voters;

  /// Starting point of the route
  final LatLng startPoint;

  /// Current position in the route (0-indexed)
  int currentIndex;

  /// Set of completed voter IDs
  final Set<String> completedIds;

  WalkingRoute({
    required this.voters,
    required this.startPoint,
    this.currentIndex = 0,
    Set<String>? completedIds,
  }) : completedIds = completedIds ?? {};

  /// Current voter being visited
  Voter? get currentVoter =>
      voters.isNotEmpty && currentIndex < voters.length ? voters[currentIndex] : null;

  /// Next voter in the route
  Voter? get nextVoter =>
      currentIndex + 1 < voters.length ? voters[currentIndex + 1] : null;

  /// Previous voter in the route
  Voter? get previousVoter => currentIndex > 0 ? voters[currentIndex - 1] : null;

  /// Total number of voters in the route
  int get totalCount => voters.length;

  /// Number of completed voters
  int get completedCount => completedIds.length;

  /// Number of remaining voters
  int get remainingCount => totalCount - completedCount;

  /// Progress as a percentage (0.0 - 1.0)
  double get progress => totalCount > 0 ? completedCount / totalCount : 0.0;

  /// Check if current voter is completed
  bool get isCurrentCompleted =>
      currentVoter != null && completedIds.contains(currentVoter!.uniqueId);

  /// Check if a specific voter is completed
  bool isCompleted(Voter voter) => completedIds.contains(voter.uniqueId);

  /// Mark current voter as completed
  void markCurrentCompleted() {
    if (currentVoter != null) {
      completedIds.add(currentVoter!.uniqueId);
    }
  }

  /// Move to next voter
  bool moveToNext() {
    if (currentIndex < voters.length - 1) {
      currentIndex++;
      return true;
    }
    return false;
  }

  /// Move to previous voter
  bool moveToPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      return true;
    }
    return false;
  }

  /// Jump to a specific index
  void jumpTo(int index) {
    if (index >= 0 && index < voters.length) {
      currentIndex = index;
    }
  }

  /// Get remaining voters (not completed)
  List<Voter> get remainingVoters =>
      voters.where((v) => !completedIds.contains(v.uniqueId)).toList();

  /// Check if route is complete
  bool get isComplete => completedCount == totalCount;

  /// Check if at the start of route
  bool get isAtStart => currentIndex == 0;

  /// Check if at the end of route
  bool get isAtEnd => currentIndex == voters.length - 1;
}
