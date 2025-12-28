import { createClient } from "@/lib/supabase/server";
import { StatsCard } from "@/components/dashboard/stats-card";
import {
  Users,
  Phone,
  ThumbsUp,
  ThumbsDown,
  UserCheck,
  Clock,
  Bell,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import {
  POSITIVE_RESULTS,
  NEGATIVE_RESULTS,
} from "@/types/database";

async function getStats() {
  const supabase = await createClient();

  // Get total voters
  const { count: totalVoters } = await supabase
    .from("voters")
    .select("*", { count: "exact", head: true });

  // Get contacted voters (canvass_result not null and not 'Not Contacted')
  const { count: contactedVoters } = await supabase
    .from("voters")
    .select("*", { count: "exact", head: true })
    .not("canvass_result", "is", null)
    .neq("canvass_result", "Not Contacted");

  // Get positive responses
  const { count: positiveResponses } = await supabase
    .from("voters")
    .select("*", { count: "exact", head: true })
    .in("canvass_result", POSITIVE_RESULTS);

  // Get negative responses
  const { count: negativeResponses } = await supabase
    .from("voters")
    .select("*", { count: "exact", head: true })
    .in("canvass_result", NEGATIVE_RESULTS);

  // Get pending users
  const { count: pendingUsers } = await supabase
    .from("user_profiles")
    .select("*", { count: "exact", head: true })
    .eq("role", "pending");

  // Get active canvassers
  const { count: activeCanvassers } = await supabase
    .from("user_profiles")
    .select("*", { count: "exact", head: true })
    .in("role", ["canvasser", "team_lead", "admin"]);

  // Get contacts this week
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

  const { count: weeklyContacts } = await supabase
    .from("contact_history")
    .select("*", { count: "exact", head: true })
    .gte("contacted_at", oneWeekAgo.toISOString());

  return {
    totalVoters: totalVoters ?? 0,
    contactedVoters: contactedVoters ?? 0,
    positiveResponses: positiveResponses ?? 0,
    negativeResponses: negativeResponses ?? 0,
    pendingUsers: pendingUsers ?? 0,
    activeCanvassers: activeCanvassers ?? 0,
    weeklyContacts: weeklyContacts ?? 0,
  };
}

async function getRecentActivity() {
  const supabase = await createClient();

  const { data: recentContacts } = await supabase
    .from("contact_history")
    .select(
      `
      id,
      unique_id,
      method,
      result,
      contacted_at,
      contacted_by,
      user_profiles!contacted_by(full_name, email)
    `
    )
    .order("contacted_at", { ascending: false })
    .limit(5);

  return recentContacts ?? [];
}

async function getPendingUsers() {
  const supabase = await createClient();

  const { data: pending } = await supabase
    .from("user_profiles")
    .select("*")
    .eq("role", "pending")
    .order("created_at", { ascending: false })
    .limit(5);

  return pending ?? [];
}

async function getUpcomingReminders() {
  const supabase = await createClient();
  const now = new Date();
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  // Get today's pending reminders count
  const { count: todayCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", false)
    .gte("reminder_at", startOfToday.toISOString())
    .lt("reminder_at", endOfToday.toISOString());

  // Get overdue reminders count
  const { count: overdueCount } = await supabase
    .from("callback_reminders")
    .select("*", { count: "exact", head: true })
    .eq("sent", false)
    .lt("reminder_at", startOfToday.toISOString());

  // Get upcoming reminders with voter info
  const { data: reminders } = await supabase
    .from("callback_reminders")
    .select(`
      id,
      reminder_at,
      voter_unique_id,
      voters!voter_unique_id(first_name, last_name, owner_name)
    `)
    .eq("sent", false)
    .gte("reminder_at", startOfToday.toISOString())
    .order("reminder_at", { ascending: true })
    .limit(5);

  return {
    todayCount: todayCount ?? 0,
    overdueCount: overdueCount ?? 0,
    reminders: reminders ?? [],
  };
}

export default async function DashboardPage() {
  const [stats, recentActivity, pendingUsers, reminderData] = await Promise.all([
    getStats(),
    getRecentActivity(),
    getPendingUsers(),
    getUpcomingReminders(),
  ]);

  const contactRate =
    stats.totalVoters > 0
      ? ((stats.contactedVoters / stats.totalVoters) * 100).toFixed(1)
      : "0";

  const positiveRate =
    stats.contactedVoters > 0
      ? ((stats.positiveResponses / stats.contactedVoters) * 100).toFixed(1)
      : "0";

  const getVoterName = (reminder: typeof reminderData.reminders[0]) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const votersData = reminder.voters as any;
    if (!votersData) return "Unknown";
    // Handle both array and object forms from Supabase join
    const voter = Array.isArray(votersData) ? votersData[0] : votersData;
    if (!voter) return "Unknown";
    if (voter.first_name || voter.last_name) {
      return `${voter.first_name ?? ""} ${voter.last_name ?? ""}`.trim();
    }
    return voter.owner_name ?? "Unknown";
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Overview of your canvassing campaign
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="Total Voters"
          value={stats.totalVoters.toLocaleString()}
          description="In database"
          icon={Users}
        />
        <StatsCard
          title="Contacted"
          value={stats.contactedVoters.toLocaleString()}
          description={`${contactRate}% contact rate`}
          icon={Phone}
        />
        <StatsCard
          title="Positive Responses"
          value={stats.positiveResponses.toLocaleString()}
          description={`${positiveRate}% of contacts`}
          icon={ThumbsUp}
        />
        <StatsCard
          title="This Week"
          value={stats.weeklyContacts.toLocaleString()}
          description="Contacts made"
          icon={Clock}
        />
      </div>

      {/* Secondary Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <StatsCard
          title="Active Team Members"
          value={stats.activeCanvassers}
          icon={UserCheck}
        />
        <StatsCard
          title="Pending Approvals"
          value={stats.pendingUsers}
          description={stats.pendingUsers > 0 ? "Awaiting review" : "All caught up!"}
          icon={Clock}
        />
        <StatsCard
          title="Negative Responses"
          value={stats.negativeResponses.toLocaleString()}
          icon={ThumbsDown}
        />
      </div>

      {/* Recent Activity, Pending Users, and Reminders */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
          </CardHeader>
          <CardContent>
            {recentActivity.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No recent activity
              </p>
            ) : (
              <div className="space-y-4">
                {recentActivity.map((activity) => (
                  <div
                    key={activity.id}
                    className="flex items-center justify-between border-b pb-2 last:border-0"
                  >
                    <div className="space-y-1">
                      <p className="text-sm font-medium">
                        {activity.result}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {activity.method} • Voter {activity.unique_id.slice(0, 8)}...
                      </p>
                    </div>
                    <div className="text-right">
                      <Badge variant="outline" className="mb-1">
                        {activity.method}
                      </Badge>
                      <p className="text-xs text-muted-foreground">
                        {new Date(activity.contacted_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Pending Users */}
        <Card>
          <CardHeader>
            <CardTitle>Pending Approvals</CardTitle>
          </CardHeader>
          <CardContent>
            {pendingUsers.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No pending user approvals
              </p>
            ) : (
              <div className="space-y-4">
                {pendingUsers.map((user) => (
                  <div
                    key={user.id}
                    className="flex items-center justify-between border-b pb-2 last:border-0"
                  >
                    <div className="space-y-1">
                      <p className="text-sm font-medium">
                        {user.full_name || user.email}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {user.email}
                      </p>
                    </div>
                    <Badge variant="secondary">Pending</Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Callback Reminders */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Callback Reminders
            </CardTitle>
            {(reminderData.todayCount > 0 || reminderData.overdueCount > 0) && (
              <Link href="/reminders">
                <Button variant="ghost" size="sm">View All</Button>
              </Link>
            )}
          </CardHeader>
          <CardContent>
            {/* Summary badges */}
            <div className="flex gap-2 mb-4">
              {reminderData.overdueCount > 0 && (
                <Badge variant="destructive">
                  {reminderData.overdueCount} overdue
                </Badge>
              )}
              {reminderData.todayCount > 0 && (
                <Badge variant="secondary">
                  {reminderData.todayCount} due today
                </Badge>
              )}
              {reminderData.overdueCount === 0 && reminderData.todayCount === 0 && (
                <Badge variant="outline">All caught up!</Badge>
              )}
            </div>

            {reminderData.reminders.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No upcoming reminders
              </p>
            ) : (
              <div className="space-y-3">
                {reminderData.reminders.map((reminder) => (
                  <div
                    key={reminder.id}
                    className="flex items-center justify-between border-b pb-2 last:border-0"
                  >
                    <div className="space-y-1">
                      <p className="text-sm font-medium">
                        {getVoterName(reminder)}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(reminder.reminder_at).toLocaleTimeString([], {
                          hour: "numeric",
                          minute: "2-digit",
                        })}
                      </p>
                    </div>
                    <Link href={`/voters/${reminder.voter_unique_id}`}>
                      <Button variant="ghost" size="sm">View</Button>
                    </Link>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
