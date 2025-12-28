"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  ColumnDef,
  SortingState,
  flexRender,
  getCoreRowModel,
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
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
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
  MoreHorizontal,
  ArrowUpDown,
  Users,
  UserPlus,
  ClipboardList,
  Pencil,
  Eye,
  FileText,
  Map,
} from "lucide-react";
import { AssignUsersDialog } from "./assign-users-dialog";

interface CutListWithStats {
  id: string;
  name: string;
  description: string | null;
  voter_count: number;
  created_at: string;
  contactedCount: number;
  positiveCount: number;
  assignedUsers: number;
}

interface User {
  id: string;
  full_name: string | null;
  email: string;
  role: string;
}

interface CutListsTableProps {
  cutLists: CutListWithStats[];
  users: User[];
}

export function CutListsTable({ cutLists, users }: CutListsTableProps) {
  const router = useRouter();
  const [sorting, setSorting] = useState<SortingState>([]);
  const [assignDialogOpen, setAssignDialogOpen] = useState(false);
  const [selectedCutList, setSelectedCutList] = useState<CutListWithStats | null>(null);

  const handleAssignUsers = (cutList: CutListWithStats) => {
    setSelectedCutList(cutList);
    setAssignDialogOpen(true);
  };

  const handleEdit = (cutList: CutListWithStats) => {
    router.push(`/cut-lists/create?edit=${cutList.id}`);
  };

  const columns: ColumnDef<CutListWithStats>[] = [
    {
      accessorKey: "name",
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
        const cutList = row.original;
        return (
          <div>
            <div className="font-medium">{cutList.name}</div>
            {cutList.description && (
              <div className="text-sm text-muted-foreground truncate max-w-[200px]">
                {cutList.description}
              </div>
            )}
          </div>
        );
      },
    },
    {
      accessorKey: "voter_count",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Voters
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => (
        <Badge variant="outline">
          <Users className="mr-1 h-3 w-3" />
          {row.original.voter_count.toLocaleString()}
        </Badge>
      ),
    },
    {
      id: "progress",
      header: "Progress",
      cell: ({ row }) => {
        const cutList = row.original;
        const contactRate =
          cutList.voter_count > 0
            ? (cutList.contactedCount / cutList.voter_count) * 100
            : 0;

        return (
          <div className="w-[150px]">
            <div className="flex items-center justify-between text-sm mb-1">
              <span>{cutList.contactedCount.toLocaleString()}</span>
              <span className="text-muted-foreground">
                / {cutList.voter_count.toLocaleString()}
              </span>
            </div>
            <Progress value={contactRate} className="h-2" />
            <div className="text-xs text-muted-foreground mt-1">
              {contactRate.toFixed(0)}% contacted
            </div>
          </div>
        );
      },
    },
    {
      id: "positiveRate",
      header: "Positive Rate",
      cell: ({ row }) => {
        const cutList = row.original;
        const positiveRate =
          cutList.contactedCount > 0
            ? (cutList.positiveCount / cutList.contactedCount) * 100
            : 0;

        if (cutList.contactedCount === 0) {
          return <span className="text-muted-foreground">-</span>;
        }

        return (
          <div className="text-sm">
            <span className="font-medium text-green-600">
              {cutList.positiveCount.toLocaleString()}
            </span>
            <span className="text-muted-foreground">
              {" "}
              ({positiveRate.toFixed(0)}%)
            </span>
          </div>
        );
      },
    },
    {
      accessorKey: "assignedUsers",
      header: "Assigned",
      cell: ({ row }) => {
        const count = row.original.assignedUsers;
        if (count === 0) {
          return <span className="text-muted-foreground">No users</span>;
        }
        return (
          <Badge variant="secondary">
            {count} user{count !== 1 ? "s" : ""}
          </Badge>
        );
      },
    },
    {
      accessorKey: "created_at",
      header: "Created",
      cell: ({ row }) => {
        return new Date(row.original.created_at).toLocaleDateString();
      },
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const cutList = row.original;
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
              <DropdownMenuItem onClick={() => router.push(`/cut-lists/${cutList.id}`)}>
                <Eye className="mr-2 h-4 w-4" />
                View Details
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => router.push(`/cut-lists/${cutList.id}`)}>
                <FileText className="mr-2 h-4 w-4" />
                Export Walk Sheet
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => router.push(`/cut-lists/${cutList.id}`)}>
                <Map className="mr-2 h-4 w-4" />
                Preview Route
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => handleEdit(cutList)}>
                <Pencil className="mr-2 h-4 w-4" />
                Edit Cut List
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleAssignUsers(cutList)}>
                <UserPlus className="mr-2 h-4 w-4" />
                Assign Users
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const table = useReactTable({
    data: cutLists,
    columns,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    state: {
      sorting,
    },
  });

  if (cutLists.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <ClipboardList className="h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium mb-2">No cut lists yet</h3>
          <p className="text-muted-foreground text-center max-w-sm">
            Cut lists are created from the mobile app. Import voters and create
            cut lists to get started.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>All Cut Lists ({cutLists.length})</CardTitle>
        </CardHeader>
        <CardContent>
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
                    <TableRow key={row.id}>
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
                      No cut lists found.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {selectedCutList && (
        <AssignUsersDialog
          open={assignDialogOpen}
          onOpenChange={setAssignDialogOpen}
          cutList={selectedCutList}
          users={users}
        />
      )}
    </>
  );
}
