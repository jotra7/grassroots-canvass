"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Check, Trash2, Phone, ExternalLink } from "lucide-react";
import { toast } from "sonner";
import type { CallbackReminder } from "@/types/database";

interface RemindersTableProps {
  reminders: CallbackReminder[];
}

type StatusFilter = "all" | "pending" | "overdue" | "completed";

export function RemindersTable({ reminders: initialReminders }: RemindersTableProps) {
  const router = useRouter();
  const [reminders, setReminders] = useState(initialReminders);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("pending");
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const filteredReminders = reminders.filter((reminder) => {
    const reminderDate = new Date(reminder.reminder_at);

    switch (statusFilter) {
      case "pending":
        return !reminder.sent && reminderDate >= startOfToday;
      case "overdue":
        return !reminder.sent && reminderDate < startOfToday;
      case "completed":
        return reminder.sent;
      default:
        return true;
    }
  });

  const getVoterName = (reminder: CallbackReminder) => {
    const voter = reminder.voters;
    if (!voter) return "Unknown";
    if (voter.first_name || voter.last_name) {
      return `${voter.first_name ?? ""} ${voter.last_name ?? ""}`.trim();
    }
    return voter.owner_name ?? "Unknown";
  };

  const getVoterAddress = (reminder: CallbackReminder) => {
    const voter = reminder.voters;
    if (!voter) return "";
    const parts = [voter.street_num, voter.street_name, voter.city].filter(Boolean);
    return parts.join(" ");
  };

  const getCanvasserName = (reminder: CallbackReminder) => {
    return reminder.user_profiles?.full_name ?? reminder.user_profiles?.email ?? "Unknown";
  };

  const getStatus = (reminder: CallbackReminder): "pending" | "overdue" | "completed" => {
    if (reminder.sent) return "completed";
    const reminderDate = new Date(reminder.reminder_at);
    return reminderDate < startOfToday ? "overdue" : "pending";
  };

  const getStatusBadge = (reminder: CallbackReminder) => {
    const status = getStatus(reminder);
    switch (status) {
      case "completed":
        return <Badge variant="secondary" className="bg-green-100 text-green-800">Completed</Badge>;
      case "overdue":
        return <Badge variant="destructive">Overdue</Badge>;
      default:
        return <Badge variant="outline">Pending</Badge>;
    }
  };

  const handleMarkComplete = async (id: string) => {
    setIsLoading(true);
    const { error } = await supabase
      .from("callback_reminders")
      .update({ sent: true })
      .eq("id", id);

    if (error) {
      toast.error("Failed to mark reminder as complete");
      console.error(error);
    } else {
      setReminders(reminders.map(r =>
        r.id === id ? { ...r, sent: true } : r
      ));
      toast.success("Reminder marked as complete");
    }
    setIsLoading(false);
  };

  const handleDelete = async () => {
    if (!deleteId) return;

    setIsLoading(true);
    const { error } = await supabase
      .from("callback_reminders")
      .delete()
      .eq("id", deleteId);

    if (error) {
      toast.error("Failed to delete reminder");
      console.error(error);
    } else {
      setReminders(reminders.filter(r => r.id !== deleteId));
      toast.success("Reminder deleted");
    }
    setDeleteId(null);
    setIsLoading(false);
  };

  const formatDateTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleString("en-US", {
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    });
  };

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Reminders</CardTitle>
          <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as StatusFilter)}>
            <SelectTrigger className="w-[150px]">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="overdue">Overdue</SelectItem>
              <SelectItem value="completed">Completed</SelectItem>
            </SelectContent>
          </Select>
        </CardHeader>
        <CardContent>
          {filteredReminders.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">
              No {statusFilter === "all" ? "" : statusFilter} reminders found
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Voter</TableHead>
                  <TableHead>Address</TableHead>
                  <TableHead>Canvasser</TableHead>
                  <TableHead>Scheduled</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredReminders.map((reminder) => (
                  <TableRow key={reminder.id}>
                    <TableCell className="font-medium">
                      {getVoterName(reminder)}
                      {reminder.voters?.phone && (
                        <div className="flex items-center gap-1 text-sm text-muted-foreground">
                          <Phone className="h-3 w-3" />
                          {reminder.voters.phone}
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="max-w-[200px] truncate">
                      {getVoterAddress(reminder)}
                    </TableCell>
                    <TableCell>{getCanvasserName(reminder)}</TableCell>
                    <TableCell>{formatDateTime(reminder.reminder_at)}</TableCell>
                    <TableCell>{getStatusBadge(reminder)}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => router.push(`/voters/${reminder.voter_unique_id}`)}
                          title="View voter"
                        >
                          <ExternalLink className="h-4 w-4" />
                        </Button>
                        {!reminder.sent && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleMarkComplete(reminder.id)}
                            disabled={isLoading}
                            title="Mark as complete"
                          >
                            <Check className="h-4 w-4 text-green-600" />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setDeleteId(reminder.id)}
                          disabled={isLoading}
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4 text-red-600" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Reminder</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this reminder? This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-red-600 hover:bg-red-700">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
