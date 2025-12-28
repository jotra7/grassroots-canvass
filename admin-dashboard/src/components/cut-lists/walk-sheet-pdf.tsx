"use client";

import { useState } from "react";
import {
  Document,
  Page,
  Text,
  View,
  StyleSheet,
  PDFDownloadLink,
  Font,
} from "@react-pdf/renderer";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Download, FileText, Loader2 } from "lucide-react";
import {
  getVoterDisplayName,
  getVoterAddress,
} from "@/lib/route-optimization";
import type { Voter, CutList } from "@/types/database";

// PDF Styles
const styles = StyleSheet.create({
  page: {
    padding: 30,
    fontSize: 10,
    fontFamily: "Helvetica",
  },
  header: {
    marginBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: "#ccc",
    paddingBottom: 10,
  },
  title: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 10,
    color: "#666",
  },
  dateInfo: {
    fontSize: 9,
    color: "#666",
    marginTop: 4,
  },
  table: {
    width: "100%",
  },
  tableHeader: {
    flexDirection: "row",
    backgroundColor: "#f3f4f6",
    borderBottomWidth: 1,
    borderBottomColor: "#ccc",
    paddingVertical: 6,
    paddingHorizontal: 4,
  },
  tableRow: {
    flexDirection: "row",
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
    paddingVertical: 6,
    paddingHorizontal: 4,
    minHeight: 30,
  },
  tableRowAlt: {
    backgroundColor: "#fafafa",
  },
  colNum: {
    width: "5%",
    textAlign: "center",
  },
  colName: {
    width: "20%",
  },
  colAddress: {
    width: "30%",
  },
  colPhone: {
    width: "15%",
  },
  colParty: {
    width: "10%",
    textAlign: "center",
  },
  colStatus: {
    width: "10%",
    textAlign: "center",
  },
  colCheckbox: {
    width: "10%",
    textAlign: "center",
  },
  headerText: {
    fontWeight: "bold",
    fontSize: 9,
  },
  cellText: {
    fontSize: 9,
  },
  checkbox: {
    width: 14,
    height: 14,
    borderWidth: 1,
    borderColor: "#333",
    marginHorizontal: "auto",
  },
  footer: {
    position: "absolute",
    bottom: 30,
    left: 30,
    right: 30,
    borderTopWidth: 1,
    borderTopColor: "#ccc",
    paddingTop: 10,
    flexDirection: "row",
    justifyContent: "space-between",
    fontSize: 8,
    color: "#666",
  },
  notesSection: {
    marginTop: 20,
    borderTopWidth: 1,
    borderTopColor: "#ccc",
    paddingTop: 10,
  },
  notesTitle: {
    fontSize: 10,
    fontWeight: "bold",
    marginBottom: 6,
  },
  notesLines: {
    height: 60,
    borderWidth: 1,
    borderColor: "#ddd",
  },
  pageNumber: {
    position: "absolute",
    bottom: 15,
    right: 30,
    fontSize: 8,
    color: "#666",
  },
});

interface WalkSheetDocumentProps {
  cutList: CutList;
  voters: Voter[];
  includePhone: boolean;
  includeNotes: boolean;
}

function WalkSheetDocument({
  cutList,
  voters,
  includePhone,
  includeNotes,
}: WalkSheetDocumentProps) {
  const votersPerPage = includeNotes ? 18 : 25;
  const totalPages = Math.ceil(voters.length / votersPerPage);
  const pages: Voter[][] = [];

  for (let i = 0; i < voters.length; i += votersPerPage) {
    pages.push(voters.slice(i, i + votersPerPage));
  }

  const formatDate = () => {
    return new Date().toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  return (
    <Document>
      {pages.map((pageVoters, pageIndex) => (
        <Page key={pageIndex} size="LETTER" style={styles.page}>
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.title}>{cutList.name}</Text>
            <Text style={styles.subtitle}>
              Walk Sheet - {voters.length} Voters
            </Text>
            <Text style={styles.dateInfo}>
              Generated: {formatDate()}
            </Text>
          </View>

          {/* Table */}
          <View style={styles.table}>
            {/* Table Header */}
            <View style={styles.tableHeader}>
              <Text style={[styles.colNum, styles.headerText]}>#</Text>
              <Text style={[styles.colName, styles.headerText]}>Name</Text>
              <Text style={[styles.colAddress, styles.headerText]}>Address</Text>
              {includePhone && (
                <Text style={[styles.colPhone, styles.headerText]}>Phone</Text>
              )}
              <Text style={[styles.colParty, styles.headerText]}>Party</Text>
              <Text style={[styles.colStatus, styles.headerText]}>Status</Text>
              <Text style={[styles.colCheckbox, styles.headerText]}>Done</Text>
            </View>

            {/* Table Rows */}
            {pageVoters.map((voter, index) => {
              const globalIndex = pageIndex * votersPerPage + index + 1;
              const isAlt = index % 2 === 1;
              return (
                <View
                  key={voter.unique_id}
                  style={isAlt ? [styles.tableRow, styles.tableRowAlt] : styles.tableRow}
                >
                  <Text style={[styles.colNum, styles.cellText]}>
                    {globalIndex}
                  </Text>
                  <Text style={[styles.colName, styles.cellText]}>
                    {getVoterDisplayName(voter)}
                  </Text>
                  <Text style={[styles.colAddress, styles.cellText]}>
                    {getVoterAddress(voter)}
                  </Text>
                  {includePhone && (
                    <Text style={[styles.colPhone, styles.cellText]}>
                      {voter.phone || voter.cell_phone || "-"}
                    </Text>
                  )}
                  <Text style={[styles.colParty, styles.cellText]}>
                    {(voter.party_description || "?").substring(0, 3)}
                  </Text>
                  <Text style={[styles.colStatus, styles.cellText]}>
                    {voter.canvass_result === "Not Contacted" || !voter.canvass_result
                      ? "-"
                      : voter.canvass_result.substring(0, 6)}
                  </Text>
                  <View style={styles.colCheckbox}>
                    <View style={styles.checkbox} />
                  </View>
                </View>
              );
            })}
          </View>

          {/* Notes Section */}
          {includeNotes && (
            <View style={styles.notesSection}>
              <Text style={styles.notesTitle}>Notes:</Text>
              <View style={styles.notesLines} />
            </View>
          )}

          {/* Page Number */}
          <Text style={styles.pageNumber}>
            Page {pageIndex + 1} of {totalPages}
          </Text>
        </Page>
      ))}
    </Document>
  );
}

interface WalkSheetPDFProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cutList: CutList;
  voters: Voter[];
  onGenerating: (generating: boolean) => void;
}

export function WalkSheetPDF({
  open,
  onOpenChange,
  cutList,
  voters,
  onGenerating,
}: WalkSheetPDFProps) {
  const [includePhone, setIncludePhone] = useState(true);
  const [includeNotes, setIncludeNotes] = useState(true);

  const fileName = `${cutList.name.replace(/[^a-zA-Z0-9]/g, "_")}_walk_sheet.pdf`;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Export Walk Sheet
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="flex items-center justify-between">
            <Label htmlFor="include-phone">Include Phone Numbers</Label>
            <Switch
              id="include-phone"
              checked={includePhone}
              onCheckedChange={setIncludePhone}
            />
          </div>

          <div className="flex items-center justify-between">
            <Label htmlFor="include-notes">Include Notes Section</Label>
            <Switch
              id="include-notes"
              checked={includeNotes}
              onCheckedChange={setIncludeNotes}
            />
          </div>

          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm font-medium">{cutList.name}</p>
            <p className="text-sm text-muted-foreground">
              {voters.length} voters in optimized order
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <PDFDownloadLink
            document={
              <WalkSheetDocument
                cutList={cutList}
                voters={voters}
                includePhone={includePhone}
                includeNotes={includeNotes}
              />
            }
            fileName={fileName}
          >
            {({ loading }) => (
              <Button disabled={loading}>
                {loading ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Download className="h-4 w-4 mr-2" />
                )}
                {loading ? "Generating..." : "Download PDF"}
              </Button>
            )}
          </PDFDownloadLink>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
