"use client";

import { useState } from "react";
import { VotersTable } from "@/components/voters/voters-table";
import { ImportDialog } from "@/components/voters/import-dialog";
import { ExportDialog } from "@/components/voters/export-dialog";
import { Button } from "@/components/ui/button";
import { Upload, Download } from "lucide-react";
import type { Voter } from "./page";

interface CutList {
  id: string;
  name: string;
}

interface VotersClientProps {
  data: {
    voters: Voter[];
    totalCount: number;
    cutLists: CutList[];
  };
}

export function VotersClient({ data }: VotersClientProps) {
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [exportDialogOpen, setExportDialogOpen] = useState(false);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Voters</h1>
          <p className="text-muted-foreground">
            {data.totalCount.toLocaleString()} voters in database
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setExportDialogOpen(true)}>
            <Download className="mr-2 h-4 w-4" />
            Export
          </Button>
          <Button onClick={() => setImportDialogOpen(true)}>
            <Upload className="mr-2 h-4 w-4" />
            Import CSV
          </Button>
        </div>
      </div>

      <VotersTable
        initialVoters={data.voters}
        totalCount={data.totalCount}
        cutLists={data.cutLists}
      />

      <ImportDialog
        open={importDialogOpen}
        onOpenChange={setImportDialogOpen}
      />

      <ExportDialog
        open={exportDialogOpen}
        onOpenChange={setExportDialogOpen}
        cutLists={data.cutLists}
      />
    </div>
  );
}
