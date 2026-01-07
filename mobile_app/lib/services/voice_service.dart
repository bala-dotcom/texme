import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling voice message recording and playback
class VoiceService {
  static final VoiceService _instance = VoiceService._();
  static VoiceService get instance => _instance;

  VoiceService._() {
    // Listen to position updates
    _player.onPositionChanged.listen((position) {
      _playbackPositionController.add(position);
    });

    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _playbackStateController.add(_isPlaying);
    });

    // Listen to completion
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentPlayingUrl = null;
      _playbackStateController.add(false);
      debugPrint('🔊 Playback completed');
    });
  }

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingUrl;
  DateTime? _recordingStartTime;

  // Streams for UI updates
  final StreamController<Duration> _playbackPositionController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playbackStateController =
      StreamController<bool>.broadcast();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingUrl => _currentPlayingUrl;

  Stream<Duration> get playbackPositionStream =>
      _playbackPositionController.stream;
  Stream<bool> get playbackStateStream => _playbackStateController.stream;

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Start recording voice message
  Future<bool> startRecording() async {
    try {
      // Check permission first
      if (!await hasMicrophonePermission()) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          debugPrint('🎤 Microphone permission denied');
          return false;
        }
      }

      // Check if recorder is available
      if (!await _recorder.hasPermission()) {
        debugPrint('🎤 Recorder permission not available');
        return false;
      }

      // Get temp directory for recording
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording with high quality settings
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      debugPrint('🎤 Recording started: $path');
      return true;
    } catch (e) {
      debugPrint('🎤 Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return file path with duration
  Future<({File? file, int duration})?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        debugPrint('🎤 Recording stopped but no path returned');
        return null;
      }

      // Calculate duration
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inSeconds
          : 0;

      _recordingStartTime = null;

      final file = File(path);
      if (await file.exists()) {
        debugPrint('🎤 Recording saved: $path (${duration}s)');
        return (file: file, duration: duration);
      }

      debugPrint('🎤 Recording file not found');
      return null;
    } catch (e) {
      debugPrint('🎤 Error stopping recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _recordingStartTime = null;

      // Delete the recorded file
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      debugPrint('🎤 Recording cancelled');
    } catch (e) {
      debugPrint('🎤 Error cancelling recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
    }
  }

  /// Get current recording duration in seconds
  int getRecordingDuration() {
    if (!_isRecording || _recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Play voice message from URL
  Future<void> playVoice(String url) async {
    try {
      debugPrint('🔊 Attempting to play voice: $url');
      
      // Stop if already playing something else
      if (_isPlaying || _currentPlayingUrl != null) {
        debugPrint('🔊 Stopping current playback before starting new one');
        await stopPlayback();
      }

      _currentPlayingUrl = url;
      _isPlaying = true;
      _playbackStateController.add(true);

      await _player.play(UrlSource(url));
      debugPrint('🔊 Play command sent for: $url');
    } catch (e) {
      debugPrint('🔊 Error playing voice: $e');
      _isPlaying = false;
      _currentPlayingUrl = null;
      _playbackStateController.add(false);
    }
  }

  /// Pause playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      debugPrint('🔊 Playback pause command sent');
    } catch (e) {
      debugPrint('🔊 Error pausing playback: $e');
    }
  }

  /// Resume playback
  Future<void> resumePlayback() async {
    try {
      await _player.resume();
      debugPrint('🔊 Playback resume command sent');
    } catch (e) {
      debugPrint('🔊 Error resuming playback: $e');
    }
  }

  /// Stop playback completely
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingUrl = null;
      _playbackStateController.add(false);
      debugPrint('🔊 Playback stop command sent');
    } catch (e) {
      debugPrint('🔊 Error stopping playback: $e');
    }
  }

  /// Toggle play/pause for a voice message
  Future<void> togglePlayback(String url) async {
    debugPrint('🔊 Toggling playback for: $url');
    debugPrint('🔊 Current state: isPlaying=$_isPlaying, currentUrl=$_currentPlayingUrl');
    
    if (_currentPlayingUrl == url) {
      if (_isPlaying) {
        await pausePlayback();
      } else {
        await resumePlayback();
      }
    } else {
      await playVoice(url);
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _playbackPositionController.close();
    _playbackStateController.close();
  }
}
