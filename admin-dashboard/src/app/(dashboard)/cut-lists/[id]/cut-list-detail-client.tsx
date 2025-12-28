"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  ArrowLeft,
  FileText,
  Map,
  Users,
  Phone,
  CheckCircle,
  XCircle,
  Loader2,
} from "lucide-react";
import {
  optimizeRoute,
  calculateRouteDistance,
  estimateWalkTime,
  formatDistance,
  formatDuration,
  getVoterDisplayName,
  getVoterAddress,
} from "@/lib/route-optimization";
import { POSITIVE_RESULTS, NEGATIVE_RESULTS } from "@/types/database";
import type { Voter, CutList } from "@/types/database";

// Dynamic import for the route preview modal (uses Leaflet which needs browser)
const RoutePreviewModal = dynamic(
  () => import("@/components/cut-lists/route-preview-modal").then((m) => m.RoutePreviewModal),
  { ssr: false }
);

// Dynamic import for PDF generation
const WalkSheetPDF = dynamic(
  () => import("@/components/cut-lists/walk-sheet-pdf").then((m) => m.WalkSheetPDF),
  { ssr: false }
);

interface CutListDetailClientProps {
  data: {
    cutList: CutList;
    voters: Voter[];
  };
}

export function CutListDetailClient({ data }: CutListDetailClientProps) {
  const router = useRouter();
  const { cutList, voters } = data;
  const [showRoutePreview, setShowRoutePreview] = useState(false);
  const [showPdfExport, setShowPdfExport] = useState(false);
  const [isGeneratingPdf, setIsGeneratingPdf] = useState(false);

  // Calculate stats
  const contactedVoters = voters.filter(
    (v) => v.canvass_result && v.canvass_result !== "Not Contacted"
  );
  const positiveVoters = voters.filter((v) =>
    POSITIVE_RESULTS.includes(v.canvass_result ?? "")
  );
  const negativeVoters = voters.filter((v) =>
    NEGATIVE_RESULTS.includes(v.canvass_result ?? "")
  );

  // Get default start point (Phoenix, AZ)
  const defaultStartPoint = { lat: 33.4484, lng: -112.074 };

  // Optimize route for display
  const optimizedVoters = optimizeRoute(voters, defaultStartPoint);
  const routeDistance = calculateRouteDistance(optimizedVoters);
  const walkTime = estimateWalkTime(routeDistance, optimizedVoters.length);

  const getResultBadge = (result: string | null) => {
    if (!result || result === "Not Contacted") {
      return <Badge variant="outline">Not Contacted</Badge>;
    }
    if (POSITIVE_RESULTS.includes(result)) {
      return <Badge className="bg-green-500">{result}</Badge>;
    }
    if (NEGATIVE_RESULTS.includes(result)) {
      return <Badge variant="destructive">{result}</Badge>;
    }
    return <Badge variant="secondary">{result}</Badge>;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => router.push("/cut-lists")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <div>
            <h1 className="text-2xl font-bold">{cutList.name}</h1>
            {cutList.description && (
              <p className="text-muted-foreground">{cutList.description}</p>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={() => setShowRoutePreview(true)}>
            <Map className="h-4 w-4 mr-2" />
            Preview Route
          </Button>
          <Button onClick={() => setShowPdfExport(true)} disabled={isGeneratingPdf}>
            {isGeneratingPdf ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <FileText className="h-4 w-4 mr-2" />
            )}
            Export Walk Sheet
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <Users className="h-5 w-5 text-muted-foreground" />
              <div>
                <p className="text-2xl font-bold">{voters.length}</p>
                <p className="text-sm text-muted-foreground">Total Voters</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <Phone className="h-5 w-5 text-blue-500" />
              <div>
                <p className="text-2xl font-bold">{contactedVoters.length}</p>
                <p className="text-sm text-muted-foreground">
                  Contacted ({((contactedVoters.length / voters.length) * 100 || 0).toFixed(0)}%)
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-500" />
              <div>
                <p className="text-2xl font-bold">{positiveVoters.length}</p>
                <p className="text-sm text-muted-foreground">Positive</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <XCircle className="h-5 w-5 text-red-500" />
              <div>
                <p className="text-2xl font-bold">{negativeVoters.length}</p>
                <p className="text-sm text-muted-foreground">Negative</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Route Info */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-lg font-medium">Optimized Walking Route</p>
              <p className="text-sm text-muted-foreground">
                Uses nearest-neighbor algorithm for efficient routing
              </p>
            </div>
            <div className="text-right">
              <p className="text-lg font-bold">{formatDistance(routeDistance)}</p>
              <p className="text-sm text-muted-foreground">
                Est. {formatDuration(walkTime)} walking time
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Voters Table */}
      <Card>
        <CardHeader>
          <CardTitle>Voters ({voters.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {voters.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">
              No voters in this cut list
            </p>
          ) : (
            <div className="rounded-md border max-h-[500px] overflow-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>Name</TableHead>
                    <TableHead>Address</TableHead>
                    <TableHead>Phone</TableHead>
                    <TableHead>Party</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {optimizedVoters.map((voter, index) => (
                    <TableRow
                      key={voter.unique_id}
                      className="cursor-pointer hover:bg-muted/50"
                      onClick={() => router.push(`/voters/${voter.unique_id}`)}
                    >
                      <TableCell className="font-mono text-muted-foreground">
                        {index + 1}
                      </TableCell>
                      <TableCell className="font-medium">
                        {getVoterDisplayName(voter)}
                      </TableCell>
                      <TableCell className="max-w-[200px] truncate">
                        {getVoterAddress(voter)}
                      </TableCell>
                      <TableCell>{voter.phone || voter.cell_phone || "-"}</TableCell>
                      <TableCell>
                        <Badge variant="outline">
                          {voter.party_description || "Unknown"}
                        </Badge>
                      </TableCell>
                      <TableCell>{getResultBadge(voter.canvass_result)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Route Preview Modal */}
      {showRoutePreview && (
        <RoutePreviewModal
          open={showRoutePreview}
          onOpenChange={setShowRoutePreview}
          cutList={cutList}
          voters={optimizedVoters}
          routeDistance={routeDistance}
          walkTime={walkTime}
        />
      )}

      {/* PDF Export Modal */}
      {showPdfExport && (
        <WalkSheetPDF
          open={showPdfExport}
          onOpenChange={setShowPdfExport}
          cutList={cutList}
          voters={optimizedVoters}
          onGenerating={setIsGeneratingPdf}
        />
      )}
    </div>
  );
}
