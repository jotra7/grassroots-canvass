"use client";

import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { MapPin, Navigation, ExternalLink, Printer } from "lucide-react";
import { MapContainer, TileLayer, Marker, Polyline, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  formatDistance,
  formatDuration,
  getVoterDisplayName,
  getVoterAddress,
} from "@/lib/route-optimization";
import type { Voter, CutList } from "@/types/database";

// Fix Leaflet default marker icon issue
delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: () => string })._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

// Create numbered marker icon
function createNumberedIcon(number: number) {
  return L.divIcon({
    className: "custom-numbered-marker",
    html: `<div style="
      background-color: #3b82f6;
      color: white;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 12px;
      border: 2px solid white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    ">${number}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });
}

interface RoutePreviewModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cutList: CutList;
  voters: Voter[];
  routeDistance: number;
  walkTime: number;
}

export function RoutePreviewModal({
  open,
  onOpenChange,
  cutList,
  voters,
  routeDistance,
  walkTime,
}: RoutePreviewModalProps) {
  const [mapReady, setMapReady] = useState(false);

  useEffect(() => {
    // Small delay to ensure DOM is ready
    const timer = setTimeout(() => setMapReady(true), 100);
    return () => clearTimeout(timer);
  }, []);

  // Filter voters with valid coordinates
  const votersWithCoords = voters.filter(
    (v) => v.latitude && v.longitude && v.latitude !== 0 && v.longitude !== 0
  );

  // Calculate map bounds
  const bounds = votersWithCoords.length > 0
    ? L.latLngBounds(votersWithCoords.map((v) => [v.latitude, v.longitude]))
    : L.latLngBounds([[33.4484, -112.074]]); // Default to Phoenix

  // Create polyline coordinates
  const routeCoordinates: [number, number][] = votersWithCoords.map((v) => [
    v.latitude,
    v.longitude,
  ]);

  // Generate Google Maps URL for full route
  const generateGoogleMapsUrl = () => {
    if (votersWithCoords.length === 0) return "";

    const waypoints = votersWithCoords
      .slice(0, 25) // Google Maps limits waypoints
      .map((v) => `${v.latitude},${v.longitude}`)
      .join("|");

    const origin = `${votersWithCoords[0].latitude},${votersWithCoords[0].longitude}`;
    const destination =
      votersWithCoords.length > 1
        ? `${votersWithCoords[votersWithCoords.length - 1].latitude},${
            votersWithCoords[votersWithCoords.length - 1].longitude
          }`
        : origin;

    return `https://www.google.com/maps/dir/?api=1&origin=${origin}&destination=${destination}&waypoints=${waypoints}&travelmode=walking`;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-6xl h-[85vh] flex flex-col">
        <DialogHeader>
          <DialogTitle className="flex items-center justify-between">
            <span>Walking Route - {cutList.name}</span>
            <div className="flex items-center gap-2">
              <Badge variant="outline">
                {formatDistance(routeDistance)}
              </Badge>
              <Badge variant="outline">
                ~{formatDuration(walkTime)}
              </Badge>
            </div>
          </DialogTitle>
        </DialogHeader>

        <div className="flex-1 flex gap-4 min-h-0">
          {/* Map */}
          <div className="flex-1 rounded-lg overflow-hidden border">
            {mapReady && votersWithCoords.length > 0 && (
              <MapContainer
                bounds={bounds}
                style={{ height: "100%", width: "100%" }}
                scrollWheelZoom={true}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />

                {/* Route line */}
                <Polyline
                  positions={routeCoordinates}
                  color="#3b82f6"
                  weight={3}
                  opacity={0.7}
                />

                {/* Numbered markers */}
                {votersWithCoords.map((voter, index) => (
                  <Marker
                    key={voter.unique_id}
                    position={[voter.latitude, voter.longitude]}
                    icon={createNumberedIcon(index + 1)}
                  >
                    <Popup>
                      <div className="font-medium">{getVoterDisplayName(voter)}</div>
                      <div className="text-sm text-muted-foreground">
                        {getVoterAddress(voter)}
                      </div>
                      {voter.phone && (
                        <div className="text-sm">{voter.phone}</div>
                      )}
                    </Popup>
                  </Marker>
                ))}
              </MapContainer>
            )}
            {votersWithCoords.length === 0 && (
              <div className="h-full flex items-center justify-center text-muted-foreground">
                No voters with valid coordinates
              </div>
            )}
          </div>

          {/* Stop List */}
          <div className="w-80 flex flex-col">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-medium">Stops ({votersWithCoords.length})</h3>
              <div className="flex gap-1">
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => window.open(generateGoogleMapsUrl(), "_blank")}
                  disabled={votersWithCoords.length === 0}
                  title="Open in Google Maps"
                >
                  <ExternalLink className="h-4 w-4" />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => window.print()}
                  title="Print"
                >
                  <Printer className="h-4 w-4" />
                </Button>
              </div>
            </div>

            <ScrollArea className="flex-1 border rounded-lg">
              <div className="p-2 space-y-2">
                {votersWithCoords.map((voter, index) => (
                  <div
                    key={voter.unique_id}
                    className="flex items-start gap-2 p-2 rounded hover:bg-muted/50"
                  >
                    <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-xs font-bold">
                      {index + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate">
                        {getVoterDisplayName(voter)}
                      </p>
                      <p className="text-xs text-muted-foreground truncate">
                        {getVoterAddress(voter)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </ScrollArea>
          </div>
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
          <Button onClick={() => window.open(generateGoogleMapsUrl(), "_blank")}>
            <Navigation className="h-4 w-4 mr-2" />
            Open in Google Maps
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
