"use client";

import { useState } from "react";
import { ContactTrendChart } from "@/components/analytics/contact-trend-chart";
import { ResultBreakdownChart } from "@/components/analytics/result-breakdown-chart";
import { TeamPerformanceChart } from "@/components/analytics/team-performance-chart";
import { ContactMethodChart } from "@/components/analytics/contact-method-chart";
import { CutListProgressChart } from "@/components/analytics/cut-list-progress-chart";
import { Button } from "@/components/ui/button";
import { Download } from "lucide-react";

interface AnalyticsData {
  trendData: Array<{
    date: string;
    contacts: number;
    positive: number;
    negative: number;
  }>;
  resultBreakdown: Array<{
    name: string;
    value: number;
    color: string;
  }>;
  methodData: Array<{
    method: string;
    count: number;
    color: string;
  }>;
  teamPerformance: Array<{
    name: string;
    contacts: number;
    positive: number;
    negative: number;
  }>;
  cutListProgress: Array<{
    name: string;
    total: number;
    contacted: number;
    positive: number;
  }>;
}

interface AnalyticsClientProps {
  data: AnalyticsData;
}

export function AnalyticsClient({ data }: AnalyticsClientProps) {
  const [isExporting, setIsExporting] = useState(false);

  async function handleExport() {
    setIsExporting(true);

    try {
      // Create CSV content
      const lines = [
        "Date,Total Contacts,Positive,Negative",
        ...data.trendData.map(
          (d) => `${d.date},${d.contacts},${d.positive},${d.negative}`
        ),
      ];

      const csv = lines.join("\n");
      const blob = new Blob([csv], { type: "text/csv" });
      const url = URL.createObjectURL(blob);

      const a = document.createElement("a");
      a.href = url;
      a.download = `analytics-report-${new Date().toISOString().split("T")[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } finally {
      setIsExporting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Analytics</h1>
          <p className="text-muted-foreground">
            Campaign performance and insights
          </p>
        </div>
        <Button onClick={handleExport} disabled={isExporting}>
          <Download className="mr-2 h-4 w-4" />
          {isExporting ? "Exporting..." : "Export CSV"}
        </Button>
      </div>

      {/* Top Row - Trend and Results */}
      <div className="grid gap-6 lg:grid-cols-2">
        <ContactTrendChart data={data.trendData} />
        <ResultBreakdownChart data={data.resultBreakdown} />
      </div>

      {/* Middle Row - Method and Cut List Progress */}
      <div className="grid gap-6 lg:grid-cols-2">
        <ContactMethodChart data={data.methodData} />
        <CutListProgressChart data={data.cutListProgress} />
      </div>

      {/* Full Width - Team Performance */}
      <TeamPerformanceChart data={data.teamPerformance} />
    </div>
  );
}
