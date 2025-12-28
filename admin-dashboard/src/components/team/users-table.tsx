"use client";

import { useState, useMemo } from "react";
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  ArrowUpDown,
  Search,
  UserCog,
  ClipboardList,
} from "lucide-react";
import { RoleDialog } from "./role-dialog";
import { AssignmentsDialog } from "./assignments-dialog";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

interface CutList {
  id: string;
  name: string;
  voter_count: number;
}

interface UserAssignment {
  user_id: string;
  cut_list_id: string;
}

interface UsersTableProps {
  users: UserProfile[];
  cutLists: CutList[];
  assignments: UserAssignment[];
  activityStats: Record<string, { contacts: number; lastActive: string | null }>;
  onUserUpdate: (user: UserProfile) => void;
}

export function UsersTable({
  users,
  cutLists,
  assignments,
  activityStats,
  onUserUpdate,
}: UsersTableProps) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [roleDialogOpen, setRoleDialogOpen] = useState(false);
  const [assignmentsDialogOpen, setAssignmentsDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);

  // Build a map of user assignments
  const userAssignmentsMap = useMemo(() => {
    const map: Record<string, string[]> = {};
    assignments.forEach((a) => {
      if (!map[a.user_id]) map[a.user_id] = [];
      map[a.user_id].push(a.cut_list_id);
    });
    return map;
  }, [assignments]);

  const columns: ColumnDef<UserProfile>[] = [
    {
      accessorKey: "full_name",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Name
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const name = row.getValue("full_name") as string | null;
        return (
          <div>
            <div className="font-medium">{name || "No name"}</div>
            <div className="text-sm text-muted-foreground">
              {row.original.email}
            </div>
          </div>
        );
      },
    },
    {
      accessorKey: "role",
      header: "Role",
      cell: ({ row }) => {
        const role = row.getValue("role") as string;
        const variant =
          role === "admin"
            ? "default"
            : role === "team_lead"
            ? "secondary"
            : "outline";
        return (
          <Badge variant={variant} className="capitalize">
            {role.replace("_", " ")}
          </Badge>
        );
      },
      filterFn: (row, id, value) => {
        if (value === "all") return true;
        return row.getValue(id) === value;
      },
    },
    {
      id: "assignments",
      header: "Cut Lists",
      cell: ({ row }) => {
        const userCutLists = userAssignmentsMap[row.original.id] || [];
        if (userCutLists.length === 0) {
          return <span className="text-muted-foreground">None</span>;
        }
        return (
          <Badge variant="outline">
            {userCutLists.length} assigned
          </Badge>
        );
      },
    },
    {
      id: "activity",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Activity (7d)
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const stats = activityStats[row.original.id];
        if (!stats || stats.contacts === 0) {
          return <span className="text-muted-foreground">No activity</span>;
        }
        return (
          <div>
            <div className="font-medium">{stats.contacts} contacts</div>
            {stats.lastActive && (
              <div className="text-sm text-muted-foreground">
                Last: {new Date(stats.lastActive).toLocaleDateString()}
              </div>
            )}
          </div>
        );
      },
      sortingFn: (rowA, rowB) => {
        const aContacts = activityStats[rowA.original.id]?.contacts || 0;
        const bContacts = activityStats[rowB.original.id]?.contacts || 0;
        return aContacts - bContacts;
      },
    },
    {
      accessorKey: "created_at",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Joined
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const date = new Date(row.getValue("created_at"));
        return date.toLocaleDateString();
      },
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const user = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <span className="sr-only">Open menu</span>
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Actions</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                onClick={() => {
                  setSelectedUser(user);
                  setRoleDialogOpen(true);
                }}
              >
                <UserCog className="mr-2 h-4 w-4" />
                Change Role
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => {
                  setSelectedUser(user);
                  setAssignmentsDialogOpen(true);
                }}
              >
                <ClipboardList className="mr-2 h-4 w-4" />
                Manage Cut Lists
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const filteredUsers = useMemo(() => {
    if (roleFilter === "all") return users;
    return users.filter((u) => u.role === roleFilter);
  }, [users, roleFilter]);

  const table = useReactTable({
    data: filteredUsers,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    state: {
      sorting,
      columnFilters,
    },
  });

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Team Members</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4 py-4">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by name or email..."
                value={(table.getColumn("full_name")?.getFilterValue() as string) ?? ""}
                onChange={(event) =>
                  table.getColumn("full_name")?.setFilterValue(event.target.value)
                }
                className="pl-8"
              />
            </div>
            <Select value={roleFilter} onValueChange={setRoleFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Filter by role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="team_lead">Team Lead</SelectItem>
                <SelectItem value="canvasser">Canvasser</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="rounded-md border">
            <Table>
              <TableHeader>
                {table.getHeaderGroups().map((headerGroup) => (
                  <TableRow key={headerGroup.id}>
                    {headerGroup.headers.map((header) => (
                      <TableHead key={header.id}>
                        {header.isPlaceholder
                          ? null
                          : flexRender(
                              header.column.columnDef.header,
                              header.getContext()
                            )}
                      </TableHead>
                    ))}
                  </TableRow>
                ))}
              </TableHeader>
              <TableBody>
                {table.getRowModel().rows?.length ? (
                  table.getRowModel().rows.map((row) => (
                    <TableRow
                      key={row.id}
                      data-state={row.getIsSelected() && "selected"}
                    >
                      {row.getVisibleCells().map((cell) => (
                        <TableCell key={cell.id}>
                          {flexRender(
                            cell.column.columnDef.cell,
                            cell.getContext()
                          )}
                        </TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell
                      colSpan={columns.length}
                      className="h-24 text-center"
                    >
                      No users found.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>

          <div className="flex items-center justify-between py-4">
            <div className="text-sm text-muted-foreground">
              Showing {table.getRowModel().rows.length} of {filteredUsers.length} users
            </div>
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
              >
                <ChevronLeft className="h-4 w-4" />
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {selectedUser && (
        <>
          <RoleDialog
            open={roleDialogOpen}
            onOpenChange={setRoleDialogOpen}
            user={selectedUser}
            onUpdate={(updatedUser) => {
              onUserUpdate(updatedUser);
              setSelectedUser(null);
            }}
          />
          <AssignmentsDialog
            open={assignmentsDialogOpen}
            onOpenChange={setAssignmentsDialogOpen}
            user={selectedUser}
            cutLists={cutLists}
            currentAssignments={userAssignmentsMap[selectedUser.id] || []}
          />
        </>
      )}
    </>
  );
}
