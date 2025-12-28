"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  ArrowLeft,
  Phone,
  Mail,
  MapPin,
  User,
  Calendar,
  Pencil,
  Save,
  X,
  Loader2,
  MessageSquare,
  History,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { POSITIVE_RESULTS, NEGATIVE_RESULTS } from "@/types/database";
import type { VoiceNote } from "@/types/database";
import { VoiceNotesPlayer } from "@/components/voters/voice-notes-player";

interface Voter {
  unique_id: string;
  first_name: string | null;
  last_name: string | null;
  owner_name: string | null;
  phone: string | null;
  cell_phone: string | null;
  party: string | null;
  voter_age: number | null;
  gender: string | null;
  street_num: string | null;
  street_dir: string | null;
  street_name: string | null;
  city: string | null;
  zip: string | null;
  canvass_result: string | null;
  canvass_notes: string | null;
  canvass_date: string | null;
  mail_address: string | null;
  mail_city: string | null;
  mail_state: string | null;
  mail_zip: string | null;
  lives_elsewhere: boolean | null;
  is_mail_voter: boolean | null;
  latitude: number | null;
  longitude: number | null;
}

interface ContactHistoryEntry {
  id: string;
  unique_id: string;
  result: string;
  notes: string | null;
  contact_method: string | null;
  created_at: string;
  created_by: string | null;
}

interface VoterDetailClientProps {
  data: {
    voter: Voter;
    contactHistory: ContactHistoryEntry[];
    voiceNotes: VoiceNote[];
  };
}

const CANVASS_RESULTS = [
  "Not Contacted",
  "Supportive",
  "Strong Support",
  "Leaning",
  "Undecided",
  "Needs Info",
  "Callback Requested",
  "Opposed",
  "Strongly Opposed",
  "Do Not Contact",
  "Refused",
  "Not Home",
  "Moved",
  "Deceased",
  "Wrong Number",
  "Voicemail Left",
  "Willing to Volunteer",
  "Requested Sign",
];

export function VoterDetailClient({ data }: VoterDetailClientProps) {
  const router = useRouter();
  const [voter, setVoter] = useState(data.voter);
  const [contactHistory] = useState(data.contactHistory);
  const [voiceNotes] = useState(data.voiceNotes);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editForm, setEditForm] = useState({
    first_name: voter.first_name || "",
    last_name: voter.last_name || "",
    phone: voter.phone || "",
    cell_phone: voter.cell_phone || "",
    canvass_result: voter.canvass_result || "Not Contacted",
    canvass_notes: voter.canvass_notes || "",
  });

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("voters")
        .update({
          first_name: editForm.first_name || null,
          last_name: editForm.last_name || null,
          phone: editForm.phone || null,
          cell_phone: editForm.cell_phone || null,
          canvass_result: editForm.canvass_result,
          canvass_notes: editForm.canvass_notes || null,
          canvass_date: new Date().toISOString(),
        })
        .eq("unique_id", voter.unique_id);

      if (error) throw error;

      setVoter({
        ...voter,
        first_name: editForm.first_name || null,
        last_name: editForm.last_name || null,
        phone: editForm.phone || null,
        cell_phone: editForm.cell_phone || null,
        canvass_result: editForm.canvass_result,
        canvass_notes: editForm.canvass_notes || null,
        canvass_date: new Date().toISOString(),
      });
      setIsEditing(false);
    } catch (error) {
      console.error("Error saving voter:", error);
      alert("Error saving voter. Please try again.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleCancel = () => {
    setEditForm({
      first_name: voter.first_name || "",
      last_name: voter.last_name || "",
      phone: voter.phone || "",
      cell_phone: voter.cell_phone || "",
      canvass_result: voter.canvass_result || "Not Contacted",
      canvass_notes: voter.canvass_notes || "",
    });
    setIsEditing(false);
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

  const fullAddress = [
    voter.street_num,
    voter.street_dir,
    voter.street_name,
  ]
    .filter(Boolean)
    .join(" ");

  const mailingAddress = [
    voter.mail_address,
    voter.mail_city,
    voter.mail_state,
    voter.mail_zip,
  ]
    .filter(Boolean)
    .join(", ");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => router.push("/voters")}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <div>
            <h1 className="text-2xl font-bold">
              {voter.first_name || voter.last_name
                ? `${voter.first_name || ""} ${voter.last_name || ""}`.trim()
                : voter.owner_name || "Unknown Voter"}
            </h1>
            <p className="text-muted-foreground text-sm">
              ID: {voter.unique_id}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {isEditing ? (
            <>
              <Button variant="outline" onClick={handleCancel} disabled={isSaving}>
                <X className="h-4 w-4 mr-2" />
                Cancel
              </Button>
              <Button onClick={handleSave} disabled={isSaving}>
                {isSaving ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                Save
              </Button>
            </>
          ) : (
            <Button onClick={() => setIsEditing(true)}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </Button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* Contact Info */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Contact Information
              </CardTitle>
            </CardHeader>
            <CardContent className="grid grid-cols-2 gap-4">
              {isEditing ? (
                <>
                  <div>
                    <Label>First Name</Label>
                    <Input
                      value={editForm.first_name}
                      onChange={(e) =>
                        setEditForm({ ...editForm, first_name: e.target.value })
                      }
                    />
                  </div>
                  <div>
                    <Label>Last Name</Label>
                    <Input
                      value={editForm.last_name}
                      onChange={(e) =>
                        setEditForm({ ...editForm, last_name: e.target.value })
                      }
                    />
                  </div>
                  <div>
                    <Label>Phone</Label>
                    <Input
                      value={editForm.phone}
                      onChange={(e) =>
                        setEditForm({ ...editForm, phone: e.target.value })
                      }
                    />
                  </div>
                  <div>
                    <Label>Cell Phone</Label>
                    <Input
                      value={editForm.cell_phone}
                      onChange={(e) =>
                        setEditForm({ ...editForm, cell_phone: e.target.value })
                      }
                    />
                  </div>
                </>
              ) : (
                <>
                  <div>
                    <Label className="text-muted-foreground">Name</Label>
                    <p className="font-medium">
                      {voter.first_name} {voter.last_name}
                    </p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Owner Name</Label>
                    <p className="font-medium">{voter.owner_name || "-"}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <Label className="text-muted-foreground">Phone</Label>
                      <p className="font-medium">{voter.phone || "-"}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <Label className="text-muted-foreground">Cell</Label>
                      <p className="font-medium">{voter.cell_phone || "-"}</p>
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Address */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5" />
                Address
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-muted-foreground">Property Address</Label>
                <p className="font-medium">
                  {fullAddress}
                  {voter.city && `, ${voter.city}`}
                  {voter.zip && ` ${voter.zip}`}
                </p>
              </div>
              {mailingAddress && voter.lives_elsewhere && (
                <div>
                  <Label className="text-muted-foreground">
                    Mailing Address (Lives Elsewhere)
                  </Label>
                  <p className="font-medium">{mailingAddress}</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Canvass Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MessageSquare className="h-5 w-5" />
                Canvass Status
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {isEditing ? (
                <>
                  <div>
                    <Label>Result</Label>
                    <Select
                      value={editForm.canvass_result}
                      onValueChange={(value) =>
                        setEditForm({ ...editForm, canvass_result: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {CANVASS_RESULTS.map((result) => (
                          <SelectItem key={result} value={result}>
                            {result}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label>Notes</Label>
                    <Textarea
                      value={editForm.canvass_notes}
                      onChange={(e) =>
                        setEditForm({ ...editForm, canvass_notes: e.target.value })
                      }
                      rows={4}
                    />
                  </div>
                </>
              ) : (
                <>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label className="text-muted-foreground">Result</Label>
                      <div className="mt-1">
                        {getResultBadge(voter.canvass_result)}
                      </div>
                    </div>
                    {voter.canvass_date && (
                      <div className="text-right">
                        <Label className="text-muted-foreground">Last Contact</Label>
                        <p className="text-sm">
                          {new Date(voter.canvass_date).toLocaleDateString()}
                        </p>
                      </div>
                    )}
                  </div>
                  {voter.canvass_notes && (
                    <div>
                      <Label className="text-muted-foreground">Notes</Label>
                      <p className="text-sm mt-1 whitespace-pre-wrap">
                        {voter.canvass_notes}
                      </p>
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Voter Info */}
          <Card>
            <CardHeader>
              <CardTitle>Voter Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Party</span>
                <Badge variant="outline">{voter.party || "Unknown"}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Age</span>
                <span>{voter.voter_age || "-"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Gender</span>
                <span>{voter.gender || "-"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Mail/Early Voter</span>
                <span>{voter.is_mail_voter ? "Yes" : "No"}</span>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {voter.cell_phone && (
                <Button
                  variant="outline"
                  className="w-full justify-start"
                  onClick={() => window.open(`tel:${voter.cell_phone}`)}
                >
                  <Phone className="h-4 w-4 mr-2" />
                  Call Cell
                </Button>
              )}
              {voter.phone && (
                <Button
                  variant="outline"
                  className="w-full justify-start"
                  onClick={() => window.open(`tel:${voter.phone}`)}
                >
                  <Phone className="h-4 w-4 mr-2" />
                  Call Home
                </Button>
              )}
              {voter.cell_phone && (
                <Button
                  variant="outline"
                  className="w-full justify-start"
                  onClick={() => window.open(`sms:${voter.cell_phone}`)}
                >
                  <MessageSquare className="h-4 w-4 mr-2" />
                  Send Text
                </Button>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Voice Notes */}
      <VoiceNotesPlayer voiceNotes={voiceNotes} />

      {/* Contact History */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Contact History ({contactHistory.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {contactHistory.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">
              No contact history yet
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Result</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead>Notes</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {contactHistory.map((entry) => (
                  <TableRow key={entry.id}>
                    <TableCell>
                      {new Date(entry.created_at).toLocaleString()}
                    </TableCell>
                    <TableCell>{getResultBadge(entry.result)}</TableCell>
                    <TableCell>
                      <Badge variant="outline">
                        {entry.contact_method || "Unknown"}
                      </Badge>
                    </TableCell>
                    <TableCell className="max-w-xs truncate">
                      {entry.notes || "-"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
