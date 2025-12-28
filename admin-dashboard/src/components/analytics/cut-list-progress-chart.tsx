"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface CutListProgressData {
  name: string;
  total: number;
  contacted: number;
  positive: number;
}

interface CutListProgressChartProps {
  data: CutListProgressData[];
}

export function CutListProgressChart({ data }: CutListProgressChartProps) {
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Cut List Progress</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex h-[250px] items-center justify-center text-muted-foreground">
            No cut lists found
          </div>
        </CardContent>
      </Card>
    );
  }

  // Calculate percentages
  const chartData = data.map((item) => ({
    name: item.name.length > 15 ? item.name.slice(0, 15) + "..." : item.name,
    fullName: item.name,
    total: item.total,
    contacted: item.contacted,
    positive: item.positive,
    contactRate: item.total > 0 ? Math.round((item.contacted / item.total) * 100) : 0,
    positiveRate: item.contacted > 0 ? Math.round((item.positive / item.contacted) * 100) : 0,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle>Cut List Progress</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis dataKey="name" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "hsl(var(--card))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "8px",
                }}
                formatter={(value, name) => {
                  if (name === "contactRate") return [`${value}%`, "Contact Rate"];
                  if (name === "positiveRate") return [`${value}%`, "Positive Rate"];
                  return [value, name];
                }}
                labelFormatter={(label, payload) => {
                  if (payload && payload[0]) {
                    return payload[0].payload.fullName;
                  }
                  return label;
                }}
              />
              <Legend />
              <Bar
                dataKey="contactRate"
                fill="#DE6D48"
                name="Contact Rate %"
                radius={[4, 4, 0, 0]}
              />
              <Bar
                dataKey="positiveRate"
                fill="#587758"
                name="Positive Rate %"
                radius={[4, 4, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
