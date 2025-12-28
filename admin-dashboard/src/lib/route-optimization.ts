import type { Voter } from "@/types/database";

export interface LatLng {
  lat: number;
  lng: number;
}

// Haversine formula to calculate distance between two points
export function calculateDistance(point1: LatLng, point2: LatLng): number {
  const R = 6371000; // Earth's radius in meters
  const dLat = toRad(point2.lat - point1.lat);
  const dLng = toRad(point2.lng - point1.lng);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(point1.lat)) *
      Math.cos(toRad(point2.lat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

// Nearest-neighbor algorithm to optimize route (matches Flutter implementation)
export function optimizeRoute(voters: Voter[], startPoint: LatLng): Voter[] {
  if (voters.length <= 1) return [...voters];

  // Filter to only voters with valid coordinates
  const votersWithCoords = voters.filter(
    (v) => v.latitude && v.longitude && v.latitude !== 0 && v.longitude !== 0
  );

  if (votersWithCoords.length === 0) return [...voters];

  const remaining = [...votersWithCoords];
  const result: Voter[] = [];
  let currentPoint = startPoint;

  while (remaining.length > 0) {
    // Find the nearest voter to the current point
    let nearestIndex = 0;
    let nearestDistance = Infinity;

    for (let i = 0; i < remaining.length; i++) {
      const voter = remaining[i];
      const distance = calculateDistance(currentPoint, {
        lat: voter.latitude,
        lng: voter.longitude,
      });
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    // Add the nearest voter to the result and remove from remaining
    const nearest = remaining.splice(nearestIndex, 1)[0];
    result.push(nearest);
    currentPoint = { lat: nearest.latitude, lng: nearest.longitude };
  }

  // Add voters without coordinates at the end
  const votersWithoutCoords = voters.filter(
    (v) => !v.latitude || !v.longitude || v.latitude === 0 || v.longitude === 0
  );

  return [...result, ...votersWithoutCoords];
}

// Calculate total route distance
export function calculateRouteDistance(voters: Voter[]): number {
  let total = 0;
  const votersWithCoords = voters.filter(
    (v) => v.latitude && v.longitude && v.latitude !== 0 && v.longitude !== 0
  );

  for (let i = 0; i < votersWithCoords.length - 1; i++) {
    const current = votersWithCoords[i];
    const next = votersWithCoords[i + 1];
    total += calculateDistance(
      { lat: current.latitude, lng: current.longitude },
      { lat: next.latitude, lng: next.longitude }
    );
  }

  return total;
}

// Estimate walk time (assuming 5 km/h walking speed + 3 minutes per stop)
export function estimateWalkTime(distanceMeters: number, stops: number): number {
  const walkingSpeedMps = 5000 / 3600; // 5 km/h in m/s
  const walkTimeSeconds = distanceMeters / walkingSpeedMps;
  const stopTimeSeconds = stops * 180; // 3 minutes per stop
  return Math.round((walkTimeSeconds + stopTimeSeconds) / 60); // Return in minutes
}

// Format distance for display
export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.round(meters)} m`;
  }
  return `${(meters / 1000).toFixed(1)} km`;
}

// Format duration for display
export function formatDuration(minutes: number): string {
  if (minutes < 60) {
    return `${minutes} min`;
  }
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${hours}h ${mins}m`;
}

// Get voter display name
export function getVoterDisplayName(voter: Voter): string {
  if (voter.first_name || voter.last_name) {
    return `${voter.first_name ?? ""} ${voter.last_name ?? ""}`.trim();
  }
  return voter.owner_name ?? "Unknown";
}

// Get voter full address
export function getVoterAddress(voter: Voter): string {
  const parts = [
    voter.street_num,
    voter.street_dir,
    voter.street_name,
    voter.city,
  ].filter(Boolean);
  return parts.join(" ");
}
