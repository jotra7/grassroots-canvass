"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Progress } from "@/components/ui/progress";
import { Download, FileSpreadsheet, CheckCircle } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { POSITIVE_RESULTS, NEGATIVE_RESULTS } from "@/types/database";

interface CutList {
  id: string;
  name: string;
}

interface ExportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cutLists: CutList[];
}

type ExportType = "voters" | "contacts";

const VOTER_EXPORT_FIELDS = [
  { key: "unique_id", label: "Unique ID", default: true },
  { key: "first_name", label: "First Name", default: true },
  { key: "last_name", label: "Last Name", default: true },
  { key: "owner_name", label: "Owner Name", default: false },
  { key: "phone", label: "Phone", default: true },
  { key: "cell_phone", label: "Cell Phone", default: true },
  { key: "street_num", label: "Street Number", default: true },
  { key: "street_name", label: "Street Name", default: true },
  { key: "city", label: "City", default: true },
  { key: "zip", label: "ZIP Code", default: true },
  { key: "party", label: "Party", default: true },
  { key: "canvass_result", label: "Canvass Result", default: true },
  { key: "canvass_date", label: "Last Contact Date", default: true },
  { key: "voter_age", label: "Voter Age", default: false },
  { key: "is_mail_voter", label: "Mail/Early Voter", default: false },
  { key: "latitude", label: "Latitude", default: false },
  { key: "longitude", label: "Longitude", default: false },
  { key: "mail_address", label: "Mail Address", default: false },
  { key: "mail_city", label: "Mail City", default: false },
  { key: "mail_state", label: "Mail State", default: false },
  { key: "mail_zip", label: "Mail ZIP", default: false },
];

export function ExportDialog({
  open,
  onOpenChange,
  cutLists,
}: ExportDialogProps) {
  const [exportType, setExportType] = useState<ExportType>("voters");
  const [resultFilter, setResultFilter] = useState("all");
  const [cutListFilter, setCutListFilter] = useState("all");
  const [selectedFields, setSelectedFields] = useState<Set<string>>(
    new Set(VOTER_EXPORT_FIELDS.filter((f) => f.default).map((f) => f.key))
  );
  const [exporting, setExporting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [complete, setComplete] = useState(false);
  const [exportedCount, setExportedCount] = useState(0);

  const toggleField = (fieldKey: string) => {
    setSelectedFields((prev) => {
      const next = new Set(prev);
      if (next.has(fieldKey)) {
        next.delete(fieldKey);
      } else {
        next.add(fieldKey);
      }
      return next;
    });
  };

  const handleExport = async () => {
    setExporting(true);
    setProgress(0);
    setComplete(false);

    try {
      const supabase = createClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const allData: any[] = [];
      const pageSize = 1000;
      let page = 0;
      let hasMore = true;

      // Build query based on export type
      if (exportType === "voters") {
        while (hasMore) {
          let query = supabase
            .from("voters")
            .select([...selectedFields].join(", "))
            .range(page * pageSize, (page + 1) * pageSize - 1);

          // Apply filters
          if (resultFilter === "positive") {
            query = query.in("canvass_result", POSITIVE_RESULTS);
          } else if (resultFilter === "negative") {
            query = query.in("canvass_result", NEGATIVE_RESULTS);
          } else if (resultFilter === "not_contacted") {
            query = query.or("canvass_result.is.null,canvass_result.eq.Not Contacted");
          }

          if (cutListFilter !== "all") {
            // Get voters from specific cut list
            const { data: cutListVoters } = await supabase
              .from("cut_list_voters")
              .select("voter_unique_id")
              .eq("cut_list_id", cutListFilter);

            if (cutListVoters) {
              const voterIds = cutListVoters.map((v) => v.voter_unique_id);
              query = query.in("unique_id", voterIds);
            }
          }

          const { data, error } = await query;

          if (error) throw error;

          if (data && data.length > 0) {
            allData.push(...data);
            setProgress(Math.min(90, allData.length / 10));
          }

          hasMore = data !== null && data.length === pageSize;
          page++;
        }
      } else {
        // Export contact history
        while (hasMore) {
          const { data, error } = await supabase
            .from("contact_history")
            .select(
              "voter_unique_id, contacted_at, result, method, notes, contacted_by"
            )
            .range(page * pageSize, (page + 1) * pageSize - 1)
            .order("contacted_at", { ascending: false });

          if (error) throw error;

          if (data && data.length > 0) {
            allData.push(...data);
            setProgress(Math.min(90, allData.length / 10));
          }

          hasMore = data !== null && data.length === pageSize;
          page++;
        }
      }

      // Generate CSV
      if (allData.length > 0) {
        const headers = Object.keys(allData[0]);
        const csvContent = [
          headers.join(","),
          ...allData.map((row) =>
            headers
              .map((header) => {
                const value = row[header];
                if (value === null || value === undefined) return "";
                const stringValue = String(value);
                // Escape quotes and wrap in quotes if contains comma
                if (stringValue.includes(",") || stringValue.includes('"')) {
                  return `"${stringValue.replace(/"/g, '""')}"`;
                }
                return stringValue;
              })
              .join(",")
          ),
        ].join("\n");

        // Download file
        const blob = new Blob([csvContent], { type: "text/csv" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${exportType}-export-${new Date().toISOString().split("T")[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        setExportedCount(allData.length);
      }

      setProgress(100);
      setComplete(true);
    } catch (error) {
      console.error("Export failed:", error);
    } finally {
      setExporting(false);
    }
  };

  const handleClose = () => {
    setComplete(false);
    setProgress(0);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Download className="h-5 w-5" />
            Export Data
          </DialogTitle>
          <DialogDescription>
            Export voters or contact history to CSV
          </DialogDescription>
        </DialogHeader>

        {!complete ? (
          <div className="space-y-6 py-4">
            <div className="space-y-3">
              <Label>Export Type</Label>
              <RadioGroup
                value={exportType}
                onValueChange={(v) => setExportType(v as ExportType)}
                className="flex gap-4"
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="voters" id="voters" />
                  <Label htmlFor="voters">Voters</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="contacts" id="contacts" />
                  <Label htmlFor="contacts">Contact History</Label>
                </div>
              </RadioGroup>
            </div>

            {exportType === "voters" && (
              <>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Result Filter</Label>
                    <Select value={resultFilter} onValueChange={setResultFilter}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Results</SelectItem>
                        <SelectItem value="positive">Positive Only</SelectItem>
                        <SelectItem value="negative">Negative Only</SelectItem>
                        <SelectItem value="not_contacted">
                          Not Contacted
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label>Cut List</Label>
                    <Select value={cutListFilter} onValueChange={setCutListFilter}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Voters</SelectItem>
                        {cutLists.map((list) => (
                          <SelectItem key={list.id} value={list.id}>
                            {list.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-3">
                  <Label>Fields to Include</Label>
                  <div className="grid grid-cols-2 gap-2">
                    {VOTER_EXPORT_FIELDS.map((field) => (
                      <div
                        key={field.key}
                        className="flex items-center space-x-2"
                      >
                        <Checkbox
                          id={field.key}
                          checked={selectedFields.has(field.key)}
                          onCheckedChange={() => toggleField(field.key)}
                        />
                        <Label htmlFor={field.key} className="text-sm">
                          {field.label}
                        </Label>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            )}

            {exporting && (
              <div className="space-y-2">
                <Progress value={progress} className="h-2" />
                <p className="text-sm text-center text-muted-foreground">
                  Exporting data...
                </p>
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center py-8">
            <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
            <h3 className="text-lg font-medium">Export Complete</h3>
            <p className="text-muted-foreground">
              Exported {exportedCount.toLocaleString()} records
            </p>
          </div>
        )}

        <DialogFooter>
          {!complete ? (
            <>
              <Button variant="outline" onClick={handleClose}>
                Cancel
              </Button>
              <Button onClick={handleExport} disabled={exporting}>
                <FileSpreadsheet className="mr-2 h-4 w-4" />
                {exporting ? "Exporting..." : "Export CSV"}
              </Button>
            </>
          ) : (
            <Button onClick={handleClose}>Done</Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
