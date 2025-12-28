import { createClient } from "@/lib/supabase/server";
import { RemindersTable } from "@/components/reminders/reminders-table";
import { StatsCard } from "@/components/dashboard/stats-card";
import { Bell, Clock, AlertTriangle, CalendarCheck } from "lucide-react";
import type { CallbackReminder } from "@/types/database";

async function getReminders(): Promise<CallbackReminder[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("callback_reminders")
    .select(`
      id,
      user_id,
      voter_unique_id,
      reminder_at,
      sent,
      created_at,
      user_profiles!user_id(full_name, email),
      voters!voter_unique_id(first_name, last_name, owner_name, street_num, street_name, city, phone)
    `)
    .order("reminder_at", { ascending: true });

  if (error) {
    console.error("Error fetching reminders:", error);
    return [];
  }

  // Transform Supabase array joins to single objects
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return ((data ?? []) as any[]).map((item) => ({
    ...item,
    user_profiles: Array.isArray(item.user_profiles) ? item.user_profiles[0] : item.user_profiles,
    voters: Array.isArray(item.voters) ? item.voters[0] : item.voters,
  })) as CallbackReminder[];
}

async function getReminderStats() {
  const supabase = await createClient();
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(startOfToday.getTime() + 24 * 60 * 60 * 1000);
  const endOfWeek = new Date(startOfToday.getTime() + 7 * 24 * 60 * 60 * 1000);

  // Pending today
  const { count: todayCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", false)
    .gte("reminder_at", startOfToday.toISOString())
    .lt("reminder_at", endOfToday.toISOString());

  // Overdue (past and not sent)
  const { count: overdueCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", false)
    .lt("reminder_at", startOfToday.toISOString());

  // Upcoming this week
  const { count: weekCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", false)
    .gte("reminder_at", endOfToday.toISOString())
    .lt("reminder_at", endOfWeek.toISOString());

  // Completed
  const { count: completedCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", true);

  return {
    today: todayCount ?? 0,
    overdue: overdueCount ?? 0,
    upcoming: weekCount ?? 0,
    completed: completedCount ?? 0,
  };
}

export default async function RemindersPage() {
  const [reminders, stats] = await Promise.all([
    getReminders(),
    getReminderStats(),
  ]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Callback Reminders</h1>
        <p className="text-muted-foreground">
          Manage scheduled follow-up reminders for voters
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-4">
        <StatsCard
          title="Due Today"
          value={stats.today}
          description="Reminders for today"
          icon={Bell}
        />
        <StatsCard
          title="Overdue"
          value={stats.overdue}
          description={stats.overdue > 0 ? "Needs attention" : "All caught up!"}
          icon={AlertTriangle}
        />
        <StatsCard
          title="This Week"
          value={stats.upcoming}
          description="Upcoming reminders"
          icon={Clock}
        />
        <StatsCard
          title="Completed"
          value={stats.completed}
          description="Reminders sent"
          icon={CalendarCheck}
        />
      </div>

      {/* Reminders Table */}
      <RemindersTable reminders={reminders} />
    </div>
  );
}
