import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voter.dart';

/// Service for route optimization and navigation
class RouteService {
  static final RouteService _instance = RouteService._();
  factory RouteService() => _instance;
  RouteService._();

  /// Optimize route using nearest neighbor algorithm
  /// Returns voters ordered by proximity, starting from startPoint
  List<Voter> optimizeRoute(List<Voter> voters, LatLng startPoint) {
    if (voters.isEmpty) return [];
    if (voters.length == 1) return voters;

    // Filter voters with valid locations
    final validVoters = voters.where((v) => v.hasValidLocation).toList();
    if (validVoters.isEmpty) return voters;

    final result = <Voter>[];
    final remaining = List<Voter>.from(validVoters);
    var currentPoint = startPoint;

    while (remaining.isNotEmpty) {
      // Find nearest unvisited voter
      Voter? nearest;
      double minDistance = double.infinity;

      for (final voter in remaining) {
        final voterPoint = LatLng(voter.latitude, voter.longitude);
        final distance = calculateDistance(currentPoint, voterPoint);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = voter;
        }
      }

      if (nearest != null) {
        result.add(nearest);
        remaining.remove(nearest);
        currentPoint = LatLng(nearest.latitude, nearest.longitude);
      } else {
        break;
      }
    }

    // Add any voters without valid locations at the end
    final invalidVoters = voters.where((v) => !v.hasValidLocation);
    result.addAll(invalidVoters);

    return result;
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  double calculateDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0; // meters

    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final deltaLat = (b.latitude - a.latitude) * pi / 180;
    final deltaLon = (b.longitude - a.longitude) * pi / 180;

    final haversine = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));

    return earthRadius * c;
  }

  /// Calculate total route distance in meters
  double calculateTotalDistance(List<Voter> route) {
    if (route.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < route.length - 1; i++) {
      if (route[i].hasValidLocation && route[i + 1].hasValidLocation) {
        total += calculateDistance(
          LatLng(route[i].latitude, route[i].longitude),
          LatLng(route[i + 1].latitude, route[i + 1].longitude),
        );
      }
    }
    return total;
  }

  /// Estimate walking time based on distance
  /// Assumes average walking speed of ~5 km/h (1.4 m/s)
  Duration estimateWalkTime(double distanceMeters) {
    const walkingSpeed = 1.4; // meters per second
    return Duration(seconds: (distanceMeters / walkingSpeed).round());
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Open native maps app with walking directions to destination
  Future<bool> openInMaps(LatLng destination, {String? label}) async {
    // Try Google Maps first (works on both platforms)
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=walking',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }

    // Fallback to generic geo URL
    final geoUrl = Uri.parse(
      'geo:${destination.latitude},${destination.longitude}?q=${destination.latitude},${destination.longitude}(${label ?? "Destination"})',
    );

    if (await canLaunchUrl(geoUrl)) {
      return await launchUrl(geoUrl);
    }

    return false;
  }

  /// Open native maps app with multi-stop directions
  Future<bool> openRouteInMaps(List<Voter> route, {LatLng? startPoint}) async {
    if (route.isEmpty) return false;

    // Google Maps supports multiple waypoints
    final waypoints = route
        .where((v) => v.hasValidLocation)
        .take(10) // Google Maps limit
        .map((v) => '${v.latitude},${v.longitude}')
        .toList();

    if (waypoints.isEmpty) return false;

    final origin = startPoint != null
        ? '${startPoint.latitude},${startPoint.longitude}'
        : waypoints.removeAt(0);

    final destination = waypoints.removeLast();
    final waypointsParam = waypoints.isNotEmpty ? '&waypoints=${waypoints.join('|')}' : '';

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination$waypointsParam&travelmode=walking',
    );

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
