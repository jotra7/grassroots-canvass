"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Calendar } from "lucide-react";

interface DateRangePickerProps {
  onChange: (range: { startDate: Date; endDate: Date; label: string }) => void;
  defaultValue?: string;
}

export function DateRangePicker({
  onChange,
  defaultValue = "7d",
}: DateRangePickerProps) {
  const [selectedRange, setSelectedRange] = useState(defaultValue);

  const ranges = [
    { value: "7d", label: "Last 7 days" },
    { value: "14d", label: "Last 14 days" },
    { value: "30d", label: "Last 30 days" },
    { value: "90d", label: "Last 90 days" },
    { value: "all", label: "All time" },
  ];

  const handleChange = (value: string) => {
    setSelectedRange(value);

    const endDate = new Date();
    let startDate = new Date();

    switch (value) {
      case "7d":
        startDate.setDate(endDate.getDate() - 7);
        break;
      case "14d":
        startDate.setDate(endDate.getDate() - 14);
        break;
      case "30d":
        startDate.setDate(endDate.getDate() - 30);
        break;
      case "90d":
        startDate.setDate(endDate.getDate() - 90);
        break;
      case "all":
        startDate = new Date(2020, 0, 1);
        break;
    }

    const label = ranges.find((r) => r.value === value)?.label || "Custom";
    onChange({ startDate, endDate, label });
  };

  return (
    <div className="flex items-center gap-2">
      <Calendar className="h-4 w-4 text-muted-foreground" />
      <Select value={selectedRange} onValueChange={handleChange}>
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Select range" />
        </SelectTrigger>
        <SelectContent>
          {ranges.map((range) => (
            <SelectItem key={range.value} value={range.value}>
              {range.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
