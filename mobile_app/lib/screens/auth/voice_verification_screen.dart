import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../home/home_screen.dart';
import 'pending_verification_screen.dart';

/// Voice Verification Screen for Female Registration
class VoiceVerificationScreen extends StatefulWidget {
  final String userType;
  final String? bio;
  final String? avatarUrl;

  const VoiceVerificationScreen({
    super.key,
    required this.userType,
    this.bio,
    this.avatarUrl,
  });

  @override
  State<VoiceVerificationScreen> createState() => _VoiceVerificationScreenState();
}

class _VoiceVerificationScreenState extends State<VoiceVerificationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });
    
    _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _playbackDuration = duration;
        });
      }
    });
    
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Check microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice verification'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_verification_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = Duration.zero;
      });

      // Update recording duration every second
      _updateRecordingDuration();
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _updateRecordingDuration() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        
        // Auto-stop after 60 seconds
        if (_recordingDuration.inSeconds >= 60) {
          _stopRecording();
        }
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    
    try {
      await _player.play(DeviceFileSource(_recordingPath!));
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  Future<void> _stopPlaying() async {
    await _player.stop();
    setState(() {
      _isPlaying = false;
      _playbackPosition = Duration.zero;
    });
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
      _playbackPosition = Duration.zero;
    });
  }

  Future<void> _completeRegistration() async {
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record a voice sample for verification'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      userType: widget.userType,
      name: null,
      age: null,
      bio: widget.bio,
      avatarUrl: widget.avatarUrl,
      voiceVerification: File(_recordingPath!),
    );

    if (success && mounted) {
      if (widget.userType == 'female') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voice Verification',
          style: AppTextStyles.h4,
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return LoadingOverlay(
            isLoading: auth.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  Text(
                    'Record Your Voice',
                    style: AppTextStyles.h4,
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Please record a short voice sample (10-60 seconds) saying:\n\n"Hello, I am registering on Texme. I confirm this is my real voice."',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Recording Section
                  if (_isRecording) ...[
                    // Recording in progress
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          // Animated recording indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording...',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Tap stop when finished',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Stop button
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ] else if (_hasRecording) ...[
                    // Recording complete - playback controls
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording Complete',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Progress bar
                          if (_playbackDuration.inMilliseconds > 0)
                            LinearProgressIndicator(
                              value: _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds,
                              backgroundColor: AppColors.backgroundSecondary,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Delete button
                        IconButton(
                          onPressed: _deleteRecording,
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                          iconSize: 30,
                        ),
                        const SizedBox(width: 20),
                        // Play/Stop button
                        GestureDetector(
                          onTap: _isPlaying ? _stopPlaying : _playRecording,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Re-record button
                        IconButton(
                          onPressed: () {
                            _deleteRecording();
                            _startRecording();
                          },
                          icon: const Icon(Icons.refresh),
                          color: AppColors.textSecondary,
                          iconSize: 30,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Start recording button
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tap to start recording',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your voice sample will be verified by our team within 24 hours.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Complete Registration Button
                  PrimaryButton(
                    text: 'Complete Registration',
                    onPressed: _hasRecording ? _completeRegistration : null,
                    isLoading: auth.isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
