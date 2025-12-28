import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/voice_note_service.dart';

/// Widget for playing voice notes
class VoicePlayer extends StatefulWidget {
  final VoiceNote voiceNote;
  final VoidCallback? onDelete;

  const VoicePlayer({
    super.key,
    required this.voiceNote,
    this.onDelete,
  });

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _initDuration();
    _setupListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDuration() async {
    if (widget.voiceNote.durationSeconds != null) {
      setState(() {
        _duration = Duration(seconds: widget.voiceNote.durationSeconds!);
      });
    } else {
      final duration = await _voiceNoteService.getDuration(widget.voiceNote.audioUrl);
      if (duration != null && mounted) {
        setState(() => _duration = duration);
      }
    }
  }

  void _setupListeners() {
    _positionSubscription = _voiceNoteService.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _stateSubscription = _voiceNoteService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _voiceNoteService.pause();
    } else {
      // Get signed URL for private bucket
      final signedUrl = await _voiceNoteService.getSignedUrl(widget.voiceNote.audioUrl);
      if (signedUrl != null) {
        await _voiceNoteService.play(signedUrl);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton.filled(
            onPressed: _togglePlayback,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            iconSize: 24,
          ),
          const SizedBox(width: 12),
          // Progress and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delete button
          if (widget.onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              iconSize: 20,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact inline voice player
class VoicePlayerCompact extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;

  const VoicePlayerCompact({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
  });

  @override
  State<VoicePlayerCompact> createState() => _VoicePlayerCompactState();
}

class _VoicePlayerCompactState extends State<VoicePlayerCompact> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  bool _isPlaying = false;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _voiceNoteService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _voiceNoteService.stop();
    } else {
      // Get signed URL for private bucket
      final signedUrl = await _voiceNoteService.getSignedUrl(widget.audioUrl);
      if (signedUrl != null) {
        await _voiceNoteService.play(signedUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _togglePlayback,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.mic,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            if (widget.durationSeconds != null) ...[
              const SizedBox(width: 4),
              Text(
                '${widget.durationSeconds}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
