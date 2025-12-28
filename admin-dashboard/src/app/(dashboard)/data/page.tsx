"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Upload, Download, FileSpreadsheet, Users, History, FileDown } from "lucide-react";
import { ImportDialog } from "@/components/voters/import-dialog";
import { ExportDialog } from "@/components/voters/export-dialog";
import { createClient } from "@/lib/supabase/client";

interface CutList {
  id: string;
  name: string;
}

// Template fields matching the database schema
const TEMPLATE_FIELDS = [
  // Required
  "unique_id",
  // Contact Info
  "owner_name",
  // Property Address
  "street_num",
  "street_dir",
  "street_name",
  "city",
  "zip",
  // Voter Data
  "voter_id",
  "first_name",
  "middle_name",
  "last_name",
  "phone",
  "cell_phone",
  "party",
  "voter_age",
  "gender",
  "registration_date",
  "residence_address",
  // Location
  "latitude",
  "longitude",
  // Voter Metrics
  "is_mail_voter",
  // Mailing Address
  "mail_address",
  "mail_city",
  "mail_state",
  "mail_zip",
  "lives_elsewhere",
  // Canvass Data (optional - usually set by app)
  "canvass_result",
  "canvass_notes",
  "canvass_date",
  // Contact Tracking (optional - usually set by app)
  "contact_attempts",
  "last_contact_attempt",
  "last_contact_method",
  "last_contact_date",
  "voicemail_left",
  // SMS Data (optional)
  "last_sms_response",
  "last_sms_response_date",
];

// Sample data row for the template
const SAMPLE_ROW = [
  // Required
  "VOTER-001",
  // Contact Info
  "John Smith",
  // Property Address
  "123",
  "N",
  "Main St",
  "Phoenix",
  "85001",
  // Voter Data
  "V12345",
  "John",
  "Robert",
  "Smith",
  "602-555-1234",
  "602-555-5678",
  "REP",
  "45",
  "M",
  "2010-01-15",
  "123 N Main St",
  // Location
  "33.4484",
  "-112.0740",
  // Voter Metrics
  "true",
  // Mailing Address
  "PO Box 123",
  "Phoenix",
  "AZ",
  "85001",
  "false",
  // Canvass Data (leave empty for new imports)
  "",
  "",
  "",
  // Contact Tracking (leave empty for new imports)
  "",
  "",
  "",
  "",
  "",
  // SMS Data (leave empty for new imports)
  "",
  "",
];

export default function DataPage() {
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [exportDialogOpen, setExportDialogOpen] = useState(false);
  const [cutLists, setCutLists] = useState<CutList[]>([]);
  const [stats, setStats] = useState({
    totalVoters: 0,
    totalContacts: 0,
    lastImport: null as string | null,
  });

  useEffect(() => {
    const fetchData = async () => {
      const supabase = createClient();

      // Fetch cut lists for export dialog
      const { data: cutListData } = await supabase
        .from("cut_lists")
        .select("id, name")
        .order("name");

      if (cutListData) {
        setCutLists(cutListData);
      }

      // Fetch stats
      const { count: voterCount } = await supabase
        .from("voters")
        .select("*", { count: "exact", head: true });

      const { count: contactCount } = await supabase
        .from("contact_history")
        .select("*", { count: "exact", head: true });

      setStats({
        totalVoters: voterCount || 0,
        totalContacts: contactCount || 0,
        lastImport: null,
      });
    };

    fetchData();
  }, []);

  const downloadTemplate = () => {
    const csvContent = [
      TEMPLATE_FIELDS.join(","),
      SAMPLE_ROW.join(","),
    ].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "voter-import-template.csv";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Import / Export</h1>
        <p className="text-muted-foreground">
          Import voter data from CSV files or export data for analysis
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Voters</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalVoters.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">in database</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Contact Records</CardTitle>
            <History className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalContacts.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">contact history entries</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Cut Lists</CardTitle>
            <FileSpreadsheet className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{cutLists.length}</div>
            <p className="text-xs text-muted-foreground">available for export filtering</p>
          </CardContent>
        </Card>
      </div>

      {/* Import / Export Cards */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Import Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Upload className="h-5 w-5" />
              Import Voters
            </CardTitle>
            <CardDescription>
              Upload a CSV file to add or update voter records in the database
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="rounded-lg border bg-muted/50 p-4 space-y-2">
              <h4 className="font-medium text-sm">Supported Fields</h4>
              <p className="text-sm text-muted-foreground">
                unique_id (required), first_name, last_name, phone, cell_phone,
                street_num, street_dir, street_name, city, zip, party,
                latitude, longitude, and more.
              </p>
            </div>
            <div className="rounded-lg border bg-muted/50 p-4 space-y-2">
              <h4 className="font-medium text-sm">Import Behavior</h4>
              <p className="text-sm text-muted-foreground">
                Records are matched by unique_id. Existing records will be updated,
                new records will be created.
              </p>
            </div>
            <div className="flex gap-2">
              <Button variant="outline" className="flex-1" onClick={downloadTemplate}>
                <FileDown className="mr-2 h-4 w-4" />
                Download Template
              </Button>
              <Button className="flex-1" onClick={() => setImportDialogOpen(true)}>
                <Upload className="mr-2 h-4 w-4" />
                Import CSV
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Export Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Download className="h-5 w-5" />
              Export Data
            </CardTitle>
            <CardDescription>
              Download voter data or contact history as CSV files
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="rounded-lg border bg-muted/50 p-4 space-y-2">
              <h4 className="font-medium text-sm">Export Options</h4>
              <ul className="text-sm text-muted-foreground list-disc list-inside space-y-1">
                <li>Export all voters or filter by cut list</li>
                <li>Filter by canvass result (positive/negative/not contacted)</li>
                <li>Export contact history with timestamps</li>
                <li>Select which fields to include</li>
              </ul>
            </div>
            <div className="rounded-lg border bg-muted/50 p-4 space-y-2">
              <h4 className="font-medium text-sm">File Format</h4>
              <p className="text-sm text-muted-foreground">
                Data is exported as CSV files compatible with Excel and Google Sheets.
              </p>
            </div>
            <Button className="w-full" onClick={() => setExportDialogOpen(true)}>
              <Download className="mr-2 h-4 w-4" />
              Export to CSV
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Dialogs */}
      <ImportDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
      <ExportDialog
        open={exportDialogOpen}
        onOpenChange={setExportDialogOpen}
        cutLists={cutLists}
      />
    </div>
  );
}
