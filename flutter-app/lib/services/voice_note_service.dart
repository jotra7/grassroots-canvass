import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for recording, playing, and managing voice notes
class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  DateTime? _recordingStartTime;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Start recording a voice note
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    try {
      final dir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      return true;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path ?? _currentRecordingPath;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }

    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _currentRecordingPath = null;
    }
  }

  /// Get current recording duration
  Duration get recordingDuration {
    if (_recordingStartTime == null || !_isRecording) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Play a voice note from local path or URL
  Future<void> play(String path) async {
    if (_isPlaying) {
      await stop();
    }

    try {
      if (path.startsWith('http')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }
      _isPlaying = true;
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.resume();
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Get playback position stream
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// Get playback state stream
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// Get duration of audio file
  Future<Duration?> getDuration(String path) async {
    try {
      if (path.startsWith('http')) {
        await _player.setSourceUrl(path);
      } else {
        await _player.setSourceDeviceFile(path);
      }
      return await _player.getDuration();
    } catch (_) {
      return null;
    }
  }

  /// Upload a voice note to Supabase storage
  Future<String?> uploadVoiceNote({
    required String localPath,
    required String voterId,
    String? contactHistoryId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final remotePath = '$userId/$voterId/$timestamp.m4a';

      await supabase.storage.from('voice-notes').upload(
            remotePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
          );

      // Store the path, not the URL - we'll generate signed URLs when playing
      final audioPath = remotePath;

      // Get file duration
      final duration = await getDuration(localPath);

      // Save metadata to database (store path, not URL)
      await supabase.from('voice_notes').insert({
        'voter_unique_id': voterId,
        'contact_history_id': contactHistoryId,
        'audio_url': audioPath, // This is actually a path, not URL
        'duration_seconds': duration?.inSeconds,
        'recorded_by': userId,
      });

      // Clean up local file
      await file.delete();

      return audioPath;
    } catch (e) {
      return null;
    }
  }

  /// Get a signed URL for playing a voice note (valid for 1 hour)
  Future<String?> getSignedUrl(String audioPath) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.storage
          .from('voice-notes')
          .createSignedUrl(audioPath, 3600); // 1 hour expiry
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Fetch voice notes for a voter
  Future<List<VoiceNote>> fetchVoiceNotes(String voterId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('voice_notes')
          .select()
          .eq('voter_unique_id', voterId)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((json) => VoiceNote.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete a voice note
  Future<bool> deleteVoiceNote(String voiceNoteId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('voice_notes').delete().eq('id', voiceNoteId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

/// Model for a voice note
class VoiceNote {
  final String id;
  final String voterId;
  final String? contactHistoryId;
  final String audioUrl;
  final int? durationSeconds;
  final String? transcription;
  final String recordedBy;
  final DateTime recordedAt;

  VoiceNote({
    required this.id,
    required this.voterId,
    this.contactHistoryId,
    required this.audioUrl,
    this.durationSeconds,
    this.transcription,
    required this.recordedBy,
    required this.recordedAt,
  });

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'],
      voterId: json['voter_unique_id'],
      contactHistoryId: json['contact_history_id'],
      audioUrl: json['audio_url'],
      durationSeconds: json['duration_seconds'],
      transcription: json['transcription'],
      recordedBy: json['recorded_by'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
