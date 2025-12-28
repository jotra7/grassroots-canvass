"use client";

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface ContactTrendData {
  date: string;
  contacts: number;
  positive: number;
  negative: number;
}

interface ContactTrendChartProps {
  data: ContactTrendData[];
}

export function ContactTrendChart({ data }: ContactTrendChartProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Contact Trends</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-[350px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis
                dataKey="date"
                tick={{ fontSize: 12 }}
                tickLine={false}
                axisLine={false}
              />
              <YAxis tick={{ fontSize: 12 }} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "hsl(var(--card))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "8px",
                }}
              />
              <Legend />
              <Line
                type="monotone"
                dataKey="contacts"
                stroke="#DE6D48"
                strokeWidth={2}
                dot={false}
                name="Total Contacts"
              />
              <Line
                type="monotone"
                dataKey="positive"
                stroke="#587758"
                strokeWidth={2}
                dot={false}
                name="Positive"
              />
              <Line
                type="monotone"
                dataKey="negative"
                stroke="#C9512D"
                strokeWidth={2}
                dot={false}
                name="Negative"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
