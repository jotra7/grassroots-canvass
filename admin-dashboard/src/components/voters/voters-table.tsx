"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  ColumnDef,
  SortingState,
  flexRender,
  getCoreRowModel,
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
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  Search,
  Filter,
  ChevronDown,
  X,
  RotateCcw,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { POSITIVE_RESULTS, NEGATIVE_RESULTS } from "@/types/database";

interface Voter {
  unique_id: string;
  first_name: string | null;
  last_name: string | null;
  owner_name: string | null;
  phone: string | null;
  cell_phone: string | null;
  street_num: string | null;
  street_name: string | null;
  city: string | null;
  zip: string | null;
  canvass_result: string | null;
  canvass_date: string | null;
  party: string | null;
  latitude: number | null;
  longitude: number | null;
  voter_age: number | null;
  is_mail_voter: boolean | null;
  contact_attempts: number | null;
}

interface CutList {
  id: string;
  name: string;
}

interface VotersTableProps {
  initialVoters: Voter[];
  totalCount: number;
  cutLists: CutList[];
}

interface Filters {
  search: string;
  resultFilter: string;
  cutListFilter: string;
  partyFilter: string[];
  cityFilter: string;
  zipFilter: string;
  hasPhoneFilter: string;
  hasCellFilter: string;
  isMailVoterFilter: string;
  hasLocationFilter: string;
  ageMin: string;
  ageMax: string;
  contactAttemptsMin: string;
  contactAttemptsMax: string;
}

const defaultFilters: Filters = {
  search: "",
  resultFilter: "all",
  cutListFilter: "all",
  partyFilter: [],
  cityFilter: "",
  zipFilter: "",
  hasPhoneFilter: "all",
  hasCellFilter: "all",
  isMailVoterFilter: "all",
  hasLocationFilter: "all",
  ageMin: "",
  ageMax: "",
  contactAttemptsMin: "",
  contactAttemptsMax: "",
};

const PARTY_OPTIONS = [
  "Republican",
  "Democratic",
  "Non-Partisan",
  "Registered Independent",
  "Libertarian",
  "Other",
  "Green",
];

export function VotersTable({
  initialVoters,
  totalCount,
  cutLists,
}: VotersTableProps) {
  const router = useRouter();
  const [voters, setVoters] = useState(initialVoters);
  const [sorting, setSorting] = useState<SortingState>([]);
  const [filters, setFilters] = useState<Filters>(defaultFilters);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(false);
  const [totalVoters, setTotalVoters] = useState(totalCount);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [cities, setCities] = useState<string[]>([]);
  const [zips, setZips] = useState<string[]>([]);
  const pageSize = 100;

  // Count active filters
  const activeFilterCount = Object.entries(filters).filter(([key, value]) => {
    if (key === "search") return false; // Don't count search in filter badge
    if (Array.isArray(value)) return value.length > 0;
    if (typeof value === "string") return value !== "" && value !== "all";
    return false;
  }).length;

  // Load cities and zips for dropdowns
  useEffect(() => {
    const loadFilterOptions = async () => {
      const supabase = createClient();

      const { data: cityData } = await supabase
        .from("voters")
        .select("city")
        .not("city", "is", null)
        .not("city", "eq", "");

      const { data: zipData } = await supabase
        .from("voters")
        .select("zip")
        .not("zip", "is", null)
        .not("zip", "eq", "");

      if (cityData) {
        const uniqueCities = [...new Set(cityData.map(v => v.city).filter(Boolean))].sort();
        setCities(uniqueCities as string[]);
      }
      if (zipData) {
        const uniqueZips = [...new Set(zipData.map(v => v.zip).filter(Boolean))].sort();
        setZips(uniqueZips as string[]);
      }
    };
    loadFilterOptions();
  }, []);

  const fetchVoters = async (newPage: number, currentSorting?: SortingState, currentFilters?: Filters) => {
    setLoading(true);
    try {
      const supabase = createClient();
      const activeFilters = currentFilters || filters;

      // Determine sort column and direction
      const sortState = currentSorting || sorting;
      let sortColumn = "last_name";
      let sortAscending = true;

      if (sortState.length > 0) {
        sortColumn = sortState[0].id;
        sortAscending = !sortState[0].desc;
      }

      let query = supabase
        .from("voters")
        .select(
          "unique_id, first_name, last_name, owner_name, phone, cell_phone, street_num, street_name, city, zip, canvass_result, canvass_date, party, latitude, longitude, voter_age, is_mail_voter, contact_attempts",
          { count: "exact" }
        )
        .order(sortColumn, { ascending: sortAscending })
        .range(newPage * pageSize, (newPage + 1) * pageSize - 1);

      // Apply search filter
      if (activeFilters.search) {
        query = query.or(
          `first_name.ilike.%${activeFilters.search}%,last_name.ilike.%${activeFilters.search}%,owner_name.ilike.%${activeFilters.search}%,street_name.ilike.%${activeFilters.search}%,unique_id.ilike.%${activeFilters.search}%`
        );
      }

      // Apply result filter
      if (activeFilters.resultFilter === "positive") {
        query = query.in("canvass_result", POSITIVE_RESULTS);
      } else if (activeFilters.resultFilter === "negative") {
        query = query.in("canvass_result", NEGATIVE_RESULTS);
      } else if (activeFilters.resultFilter === "not_contacted") {
        query = query.or("canvass_result.is.null,canvass_result.eq.Not Contacted");
      }

      // Apply cut list filter
      if (activeFilters.cutListFilter && activeFilters.cutListFilter !== "all") {
        const { data: cutListVoters } = await supabase
          .from("cut_list_voters")
          .select("voter_unique_id")
          .eq("cut_list_id", activeFilters.cutListFilter);

        if (cutListVoters && cutListVoters.length > 0) {
          const voterIds = cutListVoters.map(v => v.voter_unique_id);
          query = query.in("unique_id", voterIds);
        } else {
          // No voters in this cut list
          setVoters([]);
          setPage(newPage);
          setTotalVoters(0);
          setLoading(false);
          return;
        }
      }

      // Party filter (multiple selection)
      if (activeFilters.partyFilter.length > 0) {
        query = query.in("party", activeFilters.partyFilter);
      }

      // City filter
      if (activeFilters.cityFilter) {
        query = query.eq("city", activeFilters.cityFilter);
      }

      // ZIP filter
      if (activeFilters.zipFilter) {
        query = query.eq("zip", activeFilters.zipFilter);
      }

      // Has phone filter
      if (activeFilters.hasPhoneFilter === "yes") {
        query = query.not("phone", "is", null).neq("phone", "");
      } else if (activeFilters.hasPhoneFilter === "no") {
        query = query.or("phone.is.null,phone.eq.");
      }

      // Has cell filter
      if (activeFilters.hasCellFilter === "yes") {
        query = query.not("cell_phone", "is", null).neq("cell_phone", "");
      } else if (activeFilters.hasCellFilter === "no") {
        query = query.or("cell_phone.is.null,cell_phone.eq.");
      }

      // Mail voter filter
      if (activeFilters.isMailVoterFilter === "yes") {
        query = query.eq("is_mail_voter", true);
      } else if (activeFilters.isMailVoterFilter === "no") {
        query = query.or("is_mail_voter.is.null,is_mail_voter.eq.false");
      }

      // Has location filter
      if (activeFilters.hasLocationFilter === "yes") {
        query = query.not("latitude", "is", null).not("longitude", "is", null);
      } else if (activeFilters.hasLocationFilter === "no") {
        query = query.or("latitude.is.null,longitude.is.null");
      }

      // Age range
      if (activeFilters.ageMin) {
        query = query.gte("voter_age", parseInt(activeFilters.ageMin));
      }
      if (activeFilters.ageMax) {
        query = query.lte("voter_age", parseInt(activeFilters.ageMax));
      }

      // Contact attempts range
      if (activeFilters.contactAttemptsMin) {
        query = query.gte("contact_attempts", parseInt(activeFilters.contactAttemptsMin));
      }
      if (activeFilters.contactAttemptsMax) {
        query = query.lte("contact_attempts", parseInt(activeFilters.contactAttemptsMax));
      }

      const { data, count } = await query;
      setVoters(data || []);
      setPage(newPage);
      if (count !== null) {
        setTotalVoters(count);
      }
    } finally {
      setLoading(false);
    }
  };

  // Handle sorting change - fetch from server with new sort
  const handleSortingChange = (updaterOrValue: SortingState | ((old: SortingState) => SortingState)) => {
    const newSorting = typeof updaterOrValue === "function" ? updaterOrValue(sorting) : updaterOrValue;
    setSorting(newSorting);
    fetchVoters(0, newSorting);
  };

  const handleApplyFilters = () => {
    fetchVoters(0, sorting, filters);
  };

  const handleResetFilters = () => {
    setFilters(defaultFilters);
    fetchVoters(0, sorting, defaultFilters);
  };

  const updateFilter = <K extends keyof Filters>(key: K, value: Filters[K]) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const togglePartyFilter = (party: string) => {
    setFilters(prev => ({
      ...prev,
      partyFilter: prev.partyFilter.includes(party)
        ? prev.partyFilter.filter(p => p !== party)
        : [...prev.partyFilter, party]
    }));
  };

  const getResultBadge = (result: string | null) => {
    if (!result || result === "Not Contacted") {
      return <Badge variant="outline">Not Contacted</Badge>;
    }
    if (POSITIVE_RESULTS.includes(result)) {
      return <Badge className="bg-green-500">{result}</Badge>;
    }
    if (NEGATIVE_RESULTS.includes(result)) {
      return <Badge variant="destructive">{result}</Badge>;
    }
    return <Badge variant="secondary">{result}</Badge>;
  };

  const columns: ColumnDef<Voter>[] = [
    {
      accessorKey: "last_name",
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
        const firstName = row.original.first_name || "";
        const lastName = row.original.last_name || "";
        return (
          <div className="font-medium">
            {lastName}, {firstName}
          </div>
        );
      },
    },
    {
      id: "address",
      header: "Address",
      cell: ({ row }) => {
        const streetNum = row.original.street_num || "";
        const streetName = row.original.street_name || "";
        const city = row.original.city || "";
        return (
          <div className="max-w-[200px] truncate">
            {streetNum} {streetName}
            {city && `, ${city}`}
          </div>
        );
      },
    },
    {
      id: "contact",
      header: "Contact",
      cell: ({ row }) => (
        <div className="text-sm">
          {row.original.phone && (
            <div>{row.original.phone}</div>
          )}
          {row.original.cell_phone && (
            <div className="text-muted-foreground">{row.original.cell_phone}</div>
          )}
        </div>
      ),
    },
    {
      accessorKey: "party",
      header: "Party",
      cell: ({ row }) => {
        const party = row.original.party;
        if (!party) return <span className="text-muted-foreground">-</span>;
        return <Badge variant="outline">{party}</Badge>;
      },
    },
    {
      accessorKey: "canvass_result",
      header: "Result",
      cell: ({ row }) => getResultBadge(row.original.canvass_result),
    },
    {
      accessorKey: "canvass_date",
      header: "Last Contact",
      cell: ({ row }) => {
        const date = row.original.canvass_date;
        if (!date) return <span className="text-muted-foreground">Never</span>;
        return new Date(date).toLocaleDateString();
      },
    },
  ];

  const table = useReactTable({
    data: voters,
    columns,
    onSortingChange: handleSortingChange,
    getCoreRowModel: getCoreRowModel(),
    manualSorting: true, // Server-side sorting
    state: {
      sorting,
    },
  });

  const totalPages = Math.ceil(totalVoters / pageSize);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Voter Database</CardTitle>
      </CardHeader>
      <CardContent>
        {/* Search and Quick Filters Row */}
        <div className="flex flex-wrap items-center gap-4 py-4">
          <div className="relative flex-1 min-w-[200px] max-w-sm">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search name, address, ID..."
              value={filters.search}
              onChange={(e) => updateFilter("search", e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleApplyFilters()}
              className="pl-8"
            />
          </div>

          <Select value={filters.resultFilter} onValueChange={(v) => updateFilter("resultFilter", v)}>
            <SelectTrigger className="w-[160px]">
              <SelectValue placeholder="Result" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Results</SelectItem>
              <SelectItem value="positive">Positive</SelectItem>
              <SelectItem value="negative">Negative</SelectItem>
              <SelectItem value="not_contacted">Not Contacted</SelectItem>
            </SelectContent>
          </Select>

          <Select value={filters.cutListFilter} onValueChange={(v) => updateFilter("cutListFilter", v)}>
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Cut List" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Cut Lists</SelectItem>
              {cutLists.map((list) => (
                <SelectItem key={list.id} value={list.id}>
                  {list.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Collapsible open={filtersOpen} onOpenChange={setFiltersOpen}>
            <CollapsibleTrigger asChild>
              <Button variant="outline" className="gap-2">
                <Filter className="h-4 w-4" />
                More Filters
                {activeFilterCount > 0 && (
                  <Badge variant="secondary" className="ml-1">
                    {activeFilterCount}
                  </Badge>
                )}
                <ChevronDown className={`h-4 w-4 transition-transform ${filtersOpen ? "rotate-180" : ""}`} />
              </Button>
            </CollapsibleTrigger>
          </Collapsible>

          <Button onClick={handleApplyFilters} disabled={loading}>
            {loading ? "Loading..." : "Apply"}
          </Button>

          {activeFilterCount > 0 && (
            <Button variant="ghost" size="sm" onClick={handleResetFilters}>
              <RotateCcw className="mr-2 h-4 w-4" />
              Reset
            </Button>
          )}
        </div>

        {/* Expanded Filters Panel */}
        <Collapsible open={filtersOpen} onOpenChange={setFiltersOpen}>
          <CollapsibleContent>
            <div className="rounded-lg border bg-muted/30 p-4 mb-4 space-y-6">
              {/* Party Selection */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Party</Label>
                <div className="flex flex-wrap gap-2">
                  {PARTY_OPTIONS.map((party) => (
                    <div key={party} className="flex items-center space-x-2">
                      <Checkbox
                        id={`party-${party}`}
                        checked={filters.partyFilter.includes(party)}
                        onCheckedChange={() => togglePartyFilter(party)}
                      />
                      <Label htmlFor={`party-${party}`} className="text-sm cursor-pointer">
                        {party}
                      </Label>
                    </div>
                  ))}
                </div>
              </div>

              {/* Location Filters Row */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="space-y-2">
                  <Label className="text-sm font-medium">City</Label>
                  <Select value={filters.cityFilter} onValueChange={(v) => updateFilter("cityFilter", v === "all" ? "" : v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All Cities" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Cities</SelectItem>
                      {cities.map((city) => (
                        <SelectItem key={city} value={city}>{city}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">ZIP Code</Label>
                  <Select value={filters.zipFilter} onValueChange={(v) => updateFilter("zipFilter", v === "all" ? "" : v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All ZIPs" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All ZIPs</SelectItem>
                      {zips.map((zip) => (
                        <SelectItem key={zip} value={zip}>{zip}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">Has Location</Label>
                  <Select value={filters.hasLocationFilter} onValueChange={(v) => updateFilter("hasLocationFilter", v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">Has GPS</SelectItem>
                      <SelectItem value="no">No GPS</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Contact Filters Row */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="space-y-2">
                  <Label className="text-sm font-medium">Has Phone</Label>
                  <Select value={filters.hasPhoneFilter} onValueChange={(v) => updateFilter("hasPhoneFilter", v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">Has Phone</SelectItem>
                      <SelectItem value="no">No Phone</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">Has Cell</Label>
                  <Select value={filters.hasCellFilter} onValueChange={(v) => updateFilter("hasCellFilter", v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">Has Cell</SelectItem>
                      <SelectItem value="no">No Cell</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">Mail/Early Voter</Label>
                  <Select value={filters.isMailVoterFilter} onValueChange={(v) => updateFilter("isMailVoterFilter", v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="All" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">Mail Voter</SelectItem>
                      <SelectItem value="no">Not Mail Voter</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Range Filters Row */}
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label className="text-sm font-medium">Voter Age</Label>
                  <div className="flex gap-2">
                    <Input
                      type="number"
                      placeholder="Min"
                      value={filters.ageMin}
                      onChange={(e) => updateFilter("ageMin", e.target.value)}
                      className="w-full"
                    />
                    <Input
                      type="number"
                      placeholder="Max"
                      value={filters.ageMax}
                      onChange={(e) => updateFilter("ageMax", e.target.value)}
                      className="w-full"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">Contact Attempts</Label>
                  <div className="flex gap-2">
                    <Input
                      type="number"
                      placeholder="Min"
                      value={filters.contactAttemptsMin}
                      onChange={(e) => updateFilter("contactAttemptsMin", e.target.value)}
                      className="w-full"
                    />
                    <Input
                      type="number"
                      placeholder="Max"
                      value={filters.contactAttemptsMax}
                      onChange={(e) => updateFilter("contactAttemptsMax", e.target.value)}
                      className="w-full"
                    />
                  </div>
                </div>
              </div>
            </div>
          </CollapsibleContent>
        </Collapsible>

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
                    className="cursor-pointer hover:bg-muted/50"
                    onClick={() => router.push(`/voters/${row.original.unique_id}`)}
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
                    {loading ? "Loading..." : "No voters found."}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>

        <div className="flex items-center justify-between py-4">
          <div className="text-sm text-muted-foreground">
            Page {page + 1} of {totalPages} ({totalVoters.toLocaleString()} total)
          </div>
          <div className="flex items-center space-x-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => fetchVoters(page - 1)}
              disabled={page === 0 || loading}
            >
              <ChevronLeft className="h-4 w-4" />
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => fetchVoters(page + 1)}
              disabled={page >= totalPages - 1 || loading}
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
