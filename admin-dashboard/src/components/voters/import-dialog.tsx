"use client";

import { useState, useCallback } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Upload,
  FileSpreadsheet,
  AlertCircle,
  CheckCircle,
  X,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import Papa from "papaparse";

interface ImportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

type ImportStep = "upload" | "mapping" | "preview" | "importing" | "complete";

const VOTER_FIELDS = [
  // Required
  { key: "unique_id", label: "Unique ID", required: true },
  // Contact Info
  { key: "owner_name", label: "Owner Name", required: false },
  // Property Address
  { key: "street_num", label: "Street Number", required: false },
  { key: "street_dir", label: "Street Direction", required: false },
  { key: "street_name", label: "Street Name", required: false },
  { key: "city", label: "City", required: false },
  { key: "zip", label: "ZIP Code", required: false },
  // Voter Data
  { key: "voter_id", label: "Voter ID", required: false },
  { key: "first_name", label: "First Name", required: false },
  { key: "middle_name", label: "Middle Name", required: false },
  { key: "last_name", label: "Last Name", required: false },
  { key: "phone", label: "Phone", required: false },
  { key: "cell_phone", label: "Cell Phone", required: false },
  { key: "party", label: "Party", required: false },
  { key: "voter_age", label: "Voter Age", required: false },
  { key: "gender", label: "Gender", required: false },
  { key: "registration_date", label: "Registration Date", required: false },
  { key: "residence_address", label: "Residence Address", required: false },
  // Location
  { key: "latitude", label: "Latitude", required: false },
  { key: "longitude", label: "Longitude", required: false },
  // Voter Metrics
  { key: "is_mail_voter", label: "Mail/Early Voter", required: false },
  // Mailing Address
  { key: "mail_address", label: "Mail Address", required: false },
  { key: "mail_city", label: "Mail City", required: false },
  { key: "mail_state", label: "Mail State", required: false },
  { key: "mail_zip", label: "Mail ZIP", required: false },
  { key: "lives_elsewhere", label: "Lives Elsewhere", required: false },
  // Canvass Data
  { key: "canvass_result", label: "Canvass Result", required: false },
  { key: "canvass_notes", label: "Canvass Notes", required: false },
  { key: "canvass_date", label: "Canvass Date", required: false },
  // Contact Tracking
  { key: "contact_attempts", label: "Contact Attempts", required: false },
  { key: "last_contact_attempt", label: "Last Contact Attempt", required: false },
  { key: "last_contact_method", label: "Last Contact Method", required: false },
  { key: "last_contact_date", label: "Last Contact Date", required: false },
  { key: "voicemail_left", label: "Voicemail Left", required: false },
  // SMS Data
  { key: "last_sms_response", label: "Last SMS Response", required: false },
  { key: "last_sms_response_date", label: "Last SMS Response Date", required: false },
];

export function ImportDialog({ open, onOpenChange }: ImportDialogProps) {
  const [step, setStep] = useState<ImportStep>("upload");
  const [csvData, setCsvData] = useState<string[][]>([]);
  const [headers, setHeaders] = useState<string[]>([]);
  const [columnMapping, setColumnMapping] = useState<Record<string, string>>({});
  const [importProgress, setImportProgress] = useState(0);
  const [importResults, setImportResults] = useState({ success: 0, errors: 0 });
  const [errors, setErrors] = useState<string[]>([]);

  const resetState = () => {
    setStep("upload");
    setCsvData([]);
    setHeaders([]);
    setColumnMapping({});
    setImportProgress(0);
    setImportResults({ success: 0, errors: 0 });
    setErrors([]);
  };

  const handleFileUpload = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0];
      if (!file) return;

      Papa.parse(file, {
        complete: (results) => {
          const data = results.data as string[][];
          if (data.length < 2) {
            setErrors(["CSV file must have at least a header row and one data row"]);
            return;
          }

          setHeaders(data[0]);
          setCsvData(data.slice(1).filter((row) => row.some((cell) => cell)));

          // Auto-map columns by name similarity
          const autoMapping: Record<string, string> = {};
          data[0].forEach((header, index) => {
            const normalizedHeader = header.toLowerCase().replace(/[^a-z]/g, "");
            VOTER_FIELDS.forEach((field) => {
              const normalizedField = field.key.replace(/_/g, "");
              if (
                normalizedHeader.includes(normalizedField) ||
                normalizedField.includes(normalizedHeader)
              ) {
                autoMapping[field.key] = index.toString();
              }
            });
          });
          setColumnMapping(autoMapping);

          setStep("mapping");
        },
        error: (error) => {
          setErrors([`Failed to parse CSV: ${error.message}`]);
        },
      });
    },
    []
  );

  const handleMappingChange = (fieldKey: string, columnIndex: string) => {
    setColumnMapping((prev) => ({
      ...prev,
      [fieldKey]: columnIndex,
    }));
  };

  const getMappedPreviewData = () => {
    return csvData.slice(0, 5).map((row) => {
      const mappedRow: Record<string, string> = {};
      Object.entries(columnMapping).forEach(([fieldKey, colIndex]) => {
        if (colIndex && colIndex !== "skip") {
          mappedRow[fieldKey] = row[parseInt(colIndex)] || "";
        }
      });
      return mappedRow;
    });
  };

  const validateMapping = () => {
    const newErrors: string[] = [];

    // Check required fields
    if (!columnMapping.unique_id || columnMapping.unique_id === "skip") {
      newErrors.push("Unique ID is required");
    }

    setErrors(newErrors);
    return newErrors.length === 0;
  };

  const handleStartImport = async () => {
    if (!validateMapping()) return;

    setStep("importing");
    setImportProgress(0);

    const supabase = createClient();
    let successCount = 0;
    let errorCount = 0;
    const batchSize = 100;
    const importErrors: string[] = [];

    for (let i = 0; i < csvData.length; i += batchSize) {
      const batch = csvData.slice(i, i + batchSize);

      const votersToInsert = batch.map((row) => {
        const voter: Record<string, string | number | boolean | null> = {};
        Object.entries(columnMapping).forEach(([fieldKey, colIndex]) => {
          if (colIndex && colIndex !== "skip") {
            const value = row[parseInt(colIndex)]?.trim() || null;

            // Skip empty values
            if (!value) {
              return;
            }

            // Numeric fields
            if (["latitude", "longitude"].includes(fieldKey)) {
              voter[fieldKey] = parseFloat(value) || null;
            // Integer fields
            } else if (["voter_age", "contact_attempts"].includes(fieldKey)) {
              voter[fieldKey] = parseInt(value) || null;
            // Boolean fields
            } else if (["lives_elsewhere", "is_mail_voter", "voicemail_left"].includes(fieldKey)) {
              voter[fieldKey] = ["true", "1", "yes", "y"].includes(value.toLowerCase());
            // Timestamp fields - pass as-is, Supabase will parse
            } else if (["canvass_date", "last_contact_attempt", "last_contact_date", "last_sms_response_date"].includes(fieldKey)) {
              voter[fieldKey] = value;
            } else {
              voter[fieldKey] = value;
            }
          }
        });
        return voter;
      });

      const { error } = await supabase.from("voters").upsert(votersToInsert, {
        onConflict: "unique_id",
      });

      if (error) {
        errorCount += batch.length;
        importErrors.push(`Batch ${Math.floor(i / batchSize) + 1}: ${error.message}`);
      } else {
        successCount += batch.length;
      }

      setImportProgress(Math.round(((i + batch.length) / csvData.length) * 100));
    }

    setImportResults({ success: successCount, errors: errorCount });
    setErrors(importErrors);
    setStep("complete");
  };

  const handleClose = () => {
    resetState();
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[700px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileSpreadsheet className="h-5 w-5" />
            Import Voters from CSV
          </DialogTitle>
          <DialogDescription>
            {step === "upload" && "Upload a CSV file to import voters"}
            {step === "mapping" && "Map CSV columns to voter fields"}
            {step === "preview" && "Review the data before importing"}
            {step === "importing" && "Importing voters..."}
            {step === "complete" && "Import complete"}
          </DialogDescription>
        </DialogHeader>

        {step === "upload" && (
          <div className="space-y-4 py-4">
            <div className="flex items-center justify-center w-full">
              <label
                htmlFor="csv-upload"
                className="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed rounded-lg cursor-pointer bg-muted/50 hover:bg-muted"
              >
                <div className="flex flex-col items-center justify-center pt-5 pb-6">
                  <Upload className="w-10 h-10 mb-3 text-muted-foreground" />
                  <p className="mb-2 text-sm text-muted-foreground">
                    <span className="font-semibold">Click to upload</span> or
                    drag and drop
                  </p>
                  <p className="text-xs text-muted-foreground">
                    CSV files only
                  </p>
                </div>
                <Input
                  id="csv-upload"
                  type="file"
                  accept=".csv"
                  className="hidden"
                  onChange={handleFileUpload}
                />
              </label>
            </div>

            {errors.length > 0 && (
              <div className="rounded-lg border border-destructive bg-destructive/10 p-4">
                <div className="flex items-center gap-2 text-destructive">
                  <AlertCircle className="h-4 w-4" />
                  <span className="font-medium">Error</span>
                </div>
                <ul className="mt-2 text-sm">
                  {errors.map((error, i) => (
                    <li key={i}>{error}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        {step === "mapping" && (
          <div className="space-y-4 py-4">
            <div className="text-sm text-muted-foreground mb-4">
              Found {csvData.length.toLocaleString()} rows with {headers.length}{" "}
              columns
            </div>

            <ScrollArea className="h-[300px] rounded-md border p-4">
              <div className="space-y-4">
                {VOTER_FIELDS.map((field) => (
                  <div
                    key={field.key}
                    className="grid grid-cols-2 gap-4 items-center"
                  >
                    <Label className="flex items-center gap-2">
                      {field.label}
                      {field.required && (
                        <Badge variant="destructive" className="text-xs">
                          Required
                        </Badge>
                      )}
                    </Label>
                    <Select
                      value={columnMapping[field.key] || "skip"}
                      onValueChange={(v) => handleMappingChange(field.key, v)}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Skip" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="skip">-- Skip --</SelectItem>
                        {headers.map((header, index) => (
                          <SelectItem key={index} value={index.toString()}>
                            {header}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                ))}
              </div>
            </ScrollArea>

            {errors.length > 0 && (
              <div className="rounded-lg border border-destructive bg-destructive/10 p-4">
                <ul className="text-sm text-destructive">
                  {errors.map((error, i) => (
                    <li key={i}>{error}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        {step === "preview" && (
          <div className="space-y-4 py-4">
            <div className="text-sm text-muted-foreground">
              Preview of first 5 rows:
            </div>

            <ScrollArea className="h-[300px] rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    {VOTER_FIELDS.filter(
                      (f) => columnMapping[f.key] && columnMapping[f.key] !== "skip"
                    ).map((field) => (
                      <TableHead key={field.key}>{field.label}</TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {getMappedPreviewData().map((row, i) => (
                    <TableRow key={i}>
                      {VOTER_FIELDS.filter(
                        (f) =>
                          columnMapping[f.key] && columnMapping[f.key] !== "skip"
                      ).map((field) => (
                        <TableCell key={field.key}>
                          {row[field.key] || "-"}
                        </TableCell>
                      ))}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </ScrollArea>
          </div>
        )}

        {step === "importing" && (
          <div className="space-y-4 py-8">
            <div className="text-center">
              <div className="text-2xl font-bold mb-2">{importProgress}%</div>
              <Progress value={importProgress} className="h-2" />
              <p className="text-sm text-muted-foreground mt-2">
                Importing {csvData.length.toLocaleString()} voters...
              </p>
            </div>
          </div>
        )}

        {step === "complete" && (
          <div className="space-y-4 py-4">
            <div className="flex flex-col items-center text-center py-4">
              <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
              <h3 className="text-lg font-medium">Import Complete</h3>
              <p className="text-muted-foreground">
                Successfully imported {importResults.success.toLocaleString()}{" "}
                voters
              </p>
              {importResults.errors > 0 && (
                <p className="text-destructive">
                  {importResults.errors.toLocaleString()} errors
                </p>
              )}
            </div>

            {errors.length > 0 && (
              <ScrollArea className="h-[150px] rounded-md border p-4">
                <ul className="text-sm text-destructive space-y-1">
                  {errors.map((error, i) => (
                    <li key={i}>{error}</li>
                  ))}
                </ul>
              </ScrollArea>
            )}
          </div>
        )}

        <DialogFooter>
          {step === "upload" && (
            <Button variant="outline" onClick={handleClose}>
              Cancel
            </Button>
          )}

          {step === "mapping" && (
            <>
              <Button variant="outline" onClick={() => setStep("upload")}>
                Back
              </Button>
              <Button onClick={() => validateMapping() && setStep("preview")}>
                Preview Data
              </Button>
            </>
          )}

          {step === "preview" && (
            <>
              <Button variant="outline" onClick={() => setStep("mapping")}>
                Back
              </Button>
              <Button onClick={handleStartImport}>
                Import {csvData.length.toLocaleString()} Voters
              </Button>
            </>
          )}

          {step === "complete" && (
            <Button onClick={handleClose}>Done</Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
