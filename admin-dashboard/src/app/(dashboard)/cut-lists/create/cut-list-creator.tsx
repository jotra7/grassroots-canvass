"use client";

import { useState, useCallback, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import dynamic from "next/dynamic";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  ChevronDown,
  ChevronUp,
  Check,
  Undo,
  Trash2,
  Pencil,
  Filter,
  MapPin,
  Loader2,
  ArrowLeft,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import "leaflet/dist/leaflet.css";

// Dynamically import Leaflet components
const MapContainer = dynamic(
  () => import("react-leaflet").then((mod) => mod.MapContainer),
  { ssr: false }
);
const TileLayer = dynamic(
  () => import("react-leaflet").then((mod) => mod.TileLayer),
  { ssr: false }
);
const Polygon = dynamic(
  () => import("react-leaflet").then((mod) => mod.Polygon),
  { ssr: false }
);
const CircleMarker = dynamic(
  () => import("react-leaflet").then((mod) => mod.CircleMarker),
  { ssr: false }
);
const Polyline = dynamic(
  () => import("react-leaflet").then((mod) => mod.Polyline),
  { ssr: false }
);
const MapClickHandler = dynamic(
  () => import("@/components/cut-lists/map-events").then((mod) => mod.MapClickHandler),
  { ssr: false }
);

interface LatLng {
  lat: number;
  lng: number;
}

interface Voter {
  unique_id: string;
  first_name: string | null;
  last_name: string | null;
  latitude: number | null;
  longitude: number | null;
  party: string | null;
  lives_elsewhere: boolean | null;
  is_mail_voter: boolean | null;
  canvass_result: string | null;
}

interface ExistingCutList {
  id: string;
  name: string;
  description: string | null;
  boundary_polygon: LatLng[] | null;
}

const PARTY_OPTIONS = [
  "Democratic",
  "Republican",
  "Libertarian",
  "Green",
  "Registered Independent",
  "Non-Partisan",
  "Other",
];

const DEFAULT_CENTER: LatLng = { lat: 33.4484, lng: -112.074 };
const MAPBOX_TOKEN = "pk.eyJ1Ijoiam90cmE3IiwiYSI6ImNtamFyNnN4bzAwNjQzam9kcnY5dTZuam0ifQ.UDdH9lU6cQKUXqU4L2HqpQ";

function getPartyColor(party: string | null): string {
  switch (party) {
    case "Democratic":
      return "#3b82f6";
    case "Republican":
      return "#ef4444";
    case "Libertarian":
      return "#f59e0b";
    case "Green":
      return "#22c55e";
    case "Registered Independent":
      return "#a855f7";
    case "Non-Partisan":
      return "#14b8a6";
    default:
      return "#6b7280";
  }
}

function isPointInPolygon(point: LatLng, polygon: LatLng[]): boolean {
  if (polygon.length < 3) return false;
  let inside = false;
  let j = polygon.length - 1;
  for (let i = 0; i < polygon.length; i++) {
    const xi = polygon[i].lat;
    const yi = polygon[i].lng;
    const xj = polygon[j].lat;
    const yj = polygon[j].lng;
    if (
      yi > point.lng !== yj > point.lng &&
      point.lat < ((xj - xi) * (point.lng - yi)) / (yj - yi) + xi
    ) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

export function CutListCreator() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const editId = searchParams.get("edit");

  const [mounted, setMounted] = useState(false);
  const [existingCutList, setExistingCutList] = useState<ExistingCutList | null>(null);
  const [polygonPoints, setPolygonPoints] = useState<LatLng[]>([]);
  const [allVoters, setAllVoters] = useState<Voter[]>([]);
  const [selectedVoters, setSelectedVoters] = useState<Voter[]>([]);
  const [isDrawing, setIsDrawing] = useState(true);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [filtersExpanded, setFiltersExpanded] = useState(false);

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  const [selectedParties, setSelectedParties] = useState<Set<string>>(new Set());
  const [livesAtPropertyOnly, setLivesAtPropertyOnly] = useState(false);
  const [mailVotersOnly, setMailVotersOnly] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Load existing cut list if editing
  useEffect(() => {
    async function loadExistingCutList() {
      if (!editId) return;

      try {
        const supabase = createClient();
        const { data } = await supabase
          .from("cut_lists")
          .select("id, name, description, boundary_polygon")
          .eq("id", editId)
          .single();

        if (data) {
          setExistingCutList(data);
          setName(data.name);
          setDescription(data.description || "");
          if (data.boundary_polygon) {
            setPolygonPoints(data.boundary_polygon);
            setIsDrawing(false);
          }
        }
      } catch (error) {
        console.error("Error loading cut list:", error);
      }
    }

    loadExistingCutList();
  }, [editId]);

  // Load voters
  useEffect(() => {
    async function loadVoters() {
      try {
        const supabase = createClient();
        const { data } = await supabase
          .from("voters")
          .select(
            "unique_id, first_name, last_name, latitude, longitude, party, lives_elsewhere, is_mail_voter, canvass_result"
          )
          .not("latitude", "is", null)
          .not("longitude", "is", null);

        if (data) {
          setAllVoters(data);
        }
      } catch (error) {
        console.error("Error loading voters:", error);
      } finally {
        setIsLoading(false);
      }
    }

    loadVoters();
  }, []);

  const updateSelectedVoters = useCallback(() => {
    if (polygonPoints.length < 3) {
      setSelectedVoters([]);
      return;
    }

    let votersInPolygon = allVoters.filter((voter) => {
      if (!voter.latitude || !voter.longitude) return false;
      if (voter.latitude === 0 || voter.longitude === 0) return false;
      return isPointInPolygon(
        { lat: voter.latitude, lng: voter.longitude },
        polygonPoints
      );
    });

    if (selectedParties.size > 0) {
      votersInPolygon = votersInPolygon.filter((v) => {
        const party = v.party || "";
        for (const selectedParty of selectedParties) {
          if (selectedParty === "Other") {
            const partyLower = party.toLowerCase();
            if (
              !partyLower.includes("democrat") &&
              !partyLower.includes("republic") &&
              !partyLower.includes("libertarian") &&
              !partyLower.includes("green") &&
              !partyLower.includes("independent") &&
              !partyLower.includes("non-partisan")
            ) {
              return true;
            }
          } else if (party === selectedParty) {
            return true;
          }
        }
        return false;
      });
    }

    if (livesAtPropertyOnly) {
      votersInPolygon = votersInPolygon.filter((v) => !v.lives_elsewhere);
    }
    if (mailVotersOnly) {
      votersInPolygon = votersInPolygon.filter((v) => v.is_mail_voter);
    }

    setSelectedVoters(votersInPolygon);
  }, [
    allVoters,
    polygonPoints,
    selectedParties,
    livesAtPropertyOnly,
    mailVotersOnly,
  ]);

  useEffect(() => {
    updateSelectedVoters();
  }, [updateSelectedVoters]);

  const handleMapClick = useCallback((latlng: LatLng) => {
    setPolygonPoints((prev) => [...prev, latlng]);
  }, []);

  const undoLastPoint = () => {
    setPolygonPoints((prev) => prev.slice(0, -1));
  };

  const clearPolygon = () => {
    setPolygonPoints([]);
    setSelectedVoters([]);
    setIsDrawing(true);
  };

  const finishDrawing = () => {
    if (polygonPoints.length < 3) {
      alert("Please add at least 3 points to create a polygon");
      return;
    }
    setIsDrawing(false);
  };

  const toggleParty = (party: string) => {
    setSelectedParties((prev) => {
      const next = new Set(prev);
      if (next.has(party)) {
        next.delete(party);
      } else {
        next.add(party);
      }
      return next;
    });
  };

  const handleSave = async () => {
    if (!name.trim()) {
      alert("Please enter a name for the cut list");
      return;
    }
    if (polygonPoints.length < 3) {
      alert("Please draw a polygon with at least 3 points");
      return;
    }

    setIsSaving(true);

    try {
      const supabase = createClient();
      const voterIds = selectedVoters.map((v) => v.unique_id);

      if (existingCutList) {
        // Update existing
        const { error: updateError } = await supabase
          .from("cut_lists")
          .update({
            name: name.trim(),
            description: description.trim() || null,
            boundary_polygon: polygonPoints,
            voter_count: voterIds.length,
            updated_at: new Date().toISOString(),
          })
          .eq("id", existingCutList.id);

        if (updateError) throw updateError;

        // Clear and re-add voters
        await supabase
          .from("cut_list_voters")
          .delete()
          .eq("cut_list_id", existingCutList.id);

        if (voterIds.length > 0) {
          const cutListVoters = voterIds.map((voterId) => ({
            cut_list_id: existingCutList.id,
            voter_unique_id: voterId,
          }));
          await supabase.from("cut_list_voters").insert(cutListVoters);
        }
      } else {
        // Create new
        const { data: newCutList, error: createError } = await supabase
          .from("cut_lists")
          .insert({
            name: name.trim(),
            description: description.trim() || null,
            boundary_polygon: polygonPoints,
            voter_count: voterIds.length,
          })
          .select()
          .single();

        if (createError) throw createError;

        if (voterIds.length > 0 && newCutList) {
          const cutListVoters = voterIds.map((voterId) => ({
            cut_list_id: newCutList.id,
            voter_unique_id: voterId,
          }));
          await supabase.from("cut_list_voters").insert(cutListVoters);
        }
      }

      router.push("/cut-lists");
    } catch (error) {
      console.error("Error saving cut list:", error);
      alert("Error saving cut list. Please try again.");
    } finally {
      setIsSaving(false);
    }
  };

  const partyBreakdown = selectedVoters.reduce((acc, voter) => {
    const party = voter.party || "Unknown";
    acc[party] = (acc[party] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const sortedParties = Object.entries(partyBreakdown)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  const hasActiveFilters =
    selectedParties.size > 0 ||
    livesAtPropertyOnly ||
    mailVotersOnly;

  if (!mounted) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-100px)]">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-100px)]">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => router.push("/cut-lists")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <div>
            <h1 className="text-2xl font-bold">
              {existingCutList ? "Edit Cut List" : "Create Cut List"}
            </h1>
            <p className="text-muted-foreground text-sm">
              Draw a polygon on the map to select voters
            </p>
          </div>
        </div>
        <Button
          onClick={handleSave}
          disabled={isSaving || !name.trim() || polygonPoints.length < 3 || isDrawing}
        >
          {isSaving ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Saving...
            </>
          ) : (
            `Save Cut List (${selectedVoters.length} voters)`
          )}
        </Button>
      </div>

      {/* Main content */}
      <div className="flex flex-1 gap-4 min-h-0">
        {/* Map */}
        <div className="flex-1 relative rounded-lg overflow-hidden border">
          <MapContainer
            center={[DEFAULT_CENTER.lat, DEFAULT_CENTER.lng]}
            zoom={12}
            style={{ height: "100%", width: "100%" }}
          >
            <TileLayer
              url={`https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${MAPBOX_TOKEN}`}
              tileSize={512}
              zoomOffset={-1}
              attribution='&copy; <a href="https://www.mapbox.com/">Mapbox</a>'
            />

            <MapClickHandler isDrawing={isDrawing} onMapClick={handleMapClick} />

            {polygonPoints.length >= 3 && (
              <Polygon
                positions={polygonPoints.map((p) => [p.lat, p.lng])}
                pathOptions={{
                  color: "#3b82f6",
                  fillColor: "#3b82f6",
                  fillOpacity: 0.2,
                  weight: 2,
                }}
              />
            )}

            {polygonPoints.length > 0 && polygonPoints.length < 3 && (
              <Polyline
                positions={polygonPoints.map((p) => [p.lat, p.lng])}
                pathOptions={{ color: "#3b82f6", weight: 2 }}
              />
            )}

            {polygonPoints.map((point, index) => (
              <CircleMarker
                key={`vertex-${index}`}
                center={[point.lat, point.lng]}
                radius={8}
                pathOptions={{
                  color: "#fff",
                  fillColor: index === 0 ? "#22c55e" : "#3b82f6",
                  fillOpacity: 1,
                  weight: 2,
                }}
              />
            ))}

            {selectedVoters.map((voter) => (
              <CircleMarker
                key={voter.unique_id}
                center={[voter.latitude!, voter.longitude!]}
                radius={5}
                pathOptions={{
                  color: "#fff",
                  fillColor: getPartyColor(voter.party),
                  fillOpacity: 1,
                  weight: 1,
                }}
              />
            ))}
          </MapContainer>

          {isLoading && (
            <div className="absolute inset-0 bg-black/30 flex items-center justify-center z-[1000]">
              <Loader2 className="h-8 w-8 animate-spin text-white" />
            </div>
          )}

          {isDrawing && (
            <div className="absolute top-4 left-4 right-4 z-[1000]">
              <Card className="bg-blue-50 border-blue-200">
                <CardContent className="flex items-center gap-3 py-3">
                  <MapPin className="h-5 w-5 text-blue-600" />
                  <p className="text-blue-700 text-sm">
                    {polygonPoints.length === 0
                      ? "Click on the map to draw a polygon around the area"
                      : `Added ${polygonPoints.length} point${polygonPoints.length === 1 ? "" : "s"}. Click to add more.`}
                  </p>
                </CardContent>
              </Card>
            </div>
          )}

          <Card className="absolute top-4 right-4 z-[1000]">
            <CardContent className="py-3 px-4 text-right">
              <div className="text-2xl font-bold text-primary">
                {selectedVoters.length}
              </div>
              <div className="text-xs text-muted-foreground">voters</div>
            </CardContent>
          </Card>

          <div className="absolute bottom-4 right-4 z-[1000] flex flex-col gap-2">
            {isDrawing && polygonPoints.length >= 3 && (
              <Button
                size="sm"
                className="bg-green-600 hover:bg-green-700"
                onClick={finishDrawing}
              >
                <Check className="h-4 w-4" />
              </Button>
            )}
            {isDrawing && polygonPoints.length > 0 && (
              <Button size="sm" variant="secondary" onClick={undoLastPoint}>
                <Undo className="h-4 w-4" />
              </Button>
            )}
            {polygonPoints.length > 0 && (
              <Button size="sm" variant="destructive" onClick={clearPolygon}>
                <Trash2 className="h-4 w-4" />
              </Button>
            )}
            {!isDrawing && (
              <Button
                size="sm"
                variant="secondary"
                onClick={() => setIsDrawing(true)}
              >
                <Pencil className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>

        {/* Sidebar */}
        <Card className="w-80 flex-shrink-0 overflow-auto">
          <CardContent className="pt-4 space-y-4">
            <div>
              <Label htmlFor="name">Cut List Name *</Label>
              <Input
                id="name"
                placeholder="e.g., North Phoenix Area"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>

            <div>
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                placeholder="Brief description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>

            <Collapsible open={filtersExpanded} onOpenChange={setFiltersExpanded}>
              <CollapsibleTrigger asChild>
                <Button variant="ghost" className="w-full justify-between p-3 h-auto">
                  <div className="flex items-center gap-2">
                    <Filter className="h-4 w-4 text-primary" />
                    <span className="font-medium">Filters</span>
                    {hasActiveFilters && (
                      <Badge variant="default" className="text-xs">
                        Active
                      </Badge>
                    )}
                  </div>
                  {filtersExpanded ? (
                    <ChevronUp className="h-4 w-4" />
                  ) : (
                    <ChevronDown className="h-4 w-4" />
                  )}
                </Button>
              </CollapsibleTrigger>

              <CollapsibleContent className="space-y-4 pt-2">
                <div>
                  <Label className="mb-2 block text-sm">Parties</Label>
                  <div className="flex flex-wrap gap-1">
                    {PARTY_OPTIONS.map((party) => (
                      <Badge
                        key={party}
                        variant={selectedParties.has(party) ? "default" : "outline"}
                        className="cursor-pointer text-xs"
                        onClick={() => toggleParty(party)}
                      >
                        {party}
                      </Badge>
                    ))}
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="livesHere"
                      checked={livesAtPropertyOnly}
                      onCheckedChange={(checked) =>
                        setLivesAtPropertyOnly(!!checked)
                      }
                    />
                    <Label htmlFor="livesHere" className="text-sm cursor-pointer">
                      Lives at Property
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="mailVoter"
                      checked={mailVotersOnly}
                      onCheckedChange={(checked) => setMailVotersOnly(!!checked)}
                    />
                    <Label htmlFor="mailVoter" className="text-sm cursor-pointer">
                      Mail/Early Voters
                    </Label>
                  </div>
                </div>
              </CollapsibleContent>
            </Collapsible>

            {sortedParties.length > 0 && (
              <div>
                <Label className="mb-2 block text-sm">Voter Breakdown</Label>
                <div className="space-y-1">
                  {sortedParties.map(([party, count]) => (
                    <div
                      key={party}
                      className="flex items-center justify-between text-sm"
                    >
                      <div className="flex items-center gap-2">
                        <div
                          className="w-3 h-3 rounded-full"
                          style={{ backgroundColor: getPartyColor(party) }}
                        />
                        <span>{party}</span>
                      </div>
                      <span className="font-medium">{count}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
