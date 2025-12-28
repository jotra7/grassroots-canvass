"use client";

import { useState, useRef } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Mic, Play, Pause, Volume2, User, Calendar } from "lucide-react";
import type { VoiceNote } from "@/types/database";

interface VoiceNotesPlayerProps {
  voiceNotes: VoiceNote[];
}

export function VoiceNotesPlayer({ voiceNotes }: VoiceNotesPlayerProps) {
  const [playingId, setPlayingId] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
  };

  const getCanvasserName = (note: VoiceNote) => {
    return note.user_profiles?.full_name ?? note.user_profiles?.email ?? "Unknown";
  };

  const handlePlay = (note: VoiceNote) => {
    if (playingId === note.id) {
      // Pause current
      audioRef.current?.pause();
      setPlayingId(null);
    } else {
      // Stop previous if any
      audioRef.current?.pause();

      // Create new audio and play
      const audio = new Audio(note.audio_url);
      audioRef.current = audio;

      audio.onended = () => setPlayingId(null);
      audio.onerror = () => {
        console.error("Error playing audio");
        setPlayingId(null);
      };

      audio.play().then(() => {
        setPlayingId(note.id);
      }).catch((err) => {
        console.error("Error playing audio:", err);
      });
    }
  };

  if (voiceNotes.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Mic className="h-5 w-5" />
            Voice Notes
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground text-center py-4">
            No voice notes recorded for this voter
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Mic className="h-5 w-5" />
          Voice Notes ({voiceNotes.length})
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {voiceNotes.map((note) => (
          <div
            key={note.id}
            className="flex items-start gap-4 p-4 rounded-lg border bg-muted/30"
          >
            <Button
              variant="outline"
              size="icon"
              className="shrink-0"
              onClick={() => handlePlay(note)}
            >
              {playingId === note.id ? (
                <Pause className="h-4 w-4" />
              ) : (
                <Play className="h-4 w-4" />
              )}
            </Button>

            <div className="flex-1 space-y-2">
              <div className="flex items-center gap-2 text-sm">
                <User className="h-3 w-3 text-muted-foreground" />
                <span className="font-medium">{getCanvasserName(note)}</span>
                <span className="text-muted-foreground">|</span>
                <Calendar className="h-3 w-3 text-muted-foreground" />
                <span className="text-muted-foreground">{formatDate(note.created_at)}</span>
              </div>

              <div className="flex items-center gap-2">
                <Volume2 className="h-3 w-3 text-muted-foreground" />
                <Badge variant="secondary">
                  {formatDuration(note.duration_seconds)}
                </Badge>
              </div>

              {note.transcription && (
                <div className="mt-2 p-2 bg-background rounded text-sm">
                  <p className="text-muted-foreground italic">
                    &ldquo;{note.transcription}&rdquo;
                  </p>
                </div>
              )}
            </div>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
