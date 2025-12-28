import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_note_service.dart';

/// Widget for recording voice notes
class VoiceRecorder extends StatefulWidget {
  /// Called when recording is complete with the local file path
  final void Function(String path) onRecordingComplete;

  /// Called when recording is cancelled
  final VoidCallback? onCancel;

  const VoiceRecorder({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  bool _isRecording = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _voiceNoteService.hasPermission();
    setState(() => _hasPermission = hasPermission);
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      final granted = await _voiceNoteService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice notes'),
            ),
          );
        }
        return;
      }
      setState(() => _hasPermission = true);
    }

    final started = await _voiceNoteService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();

    final path = await _voiceNoteService.stopRecording();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });

    if (path != null) {
      widget.onRecordingComplete(path);
    }
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    await _voiceNoteService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordedPath = null;
      _recordingDuration = Duration.zero;
    });
    widget.onCancel?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (_isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_recordingDuration),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Cancel button
                IconButton.outlined(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close),
                  iconSize: 32,
                  tooltip: 'Cancel',
                ),
                const SizedBox(width: 24),
                // Stop button
                IconButton.filled(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  iconSize: 48,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  tooltip: 'Stop Recording',
                ),
              ] else ...[
                // Record button
                IconButton.filled(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic),
                  iconSize: 48,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.all(16),
                  ),
                  tooltip: 'Start Recording',
                ),
              ],
            ],
          ),

          if (!_isRecording && !_hasPermission) ...[
            const SizedBox(height: 8),
            Text(
              'Tap to request microphone permission',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact voice recorder button for inline use
class VoiceRecorderButton extends StatefulWidget {
  final void Function(String path) onRecordingComplete;

  const VoiceRecorderButton({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _durationTimer?.cancel();
      final path = await _voiceNoteService.stopRecording();
      setState(() => _isRecording = false);
      if (path != null) {
        widget.onRecordingComplete(path);
      }
    } else {
      final hasPermission = await _voiceNoteService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      final started = await _voiceNoteService.startRecording();
      if (started) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isRecording) {
            setState(() => _recordingDuration = Duration(seconds: timer.tick));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: _isRecording ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
            if (_isRecording) ...[
              const SizedBox(width: 8),
              Text(
                '${_recordingDuration.inMinutes}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
