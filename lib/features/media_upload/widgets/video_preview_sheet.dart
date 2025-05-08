import 'dart:io';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:video_player/video_player.dart';

// Video preview after selecting a video
class VideoPreviewSheet extends ConsumerStatefulWidget {
  final XFile videoFile;
  final DateTime date;

  const VideoPreviewSheet({
    super.key,
    required this.videoFile,
    required this.date,
  });

  @override
  ConsumerState<VideoPreviewSheet> createState() => _VideoPreviewSheetState();
}

class _VideoPreviewSheetState extends ConsumerState<VideoPreviewSheet> {
  final TextEditingController _titleController = TextEditingController();
  bool _isSaving = false;
  late VideoPlayerController _videoPlayerController;
  bool _isVideoInitialized = false;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _titleController.text =
        "Video ${DateTime.now().toString().substring(0, 16)}";
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(
      File(widget.videoFile.path),
    );

    // Add listener to update playback state
    _videoPlayerController.addListener(() {
      if (mounted) {
        final isPlaying = _videoPlayerController.value.isPlaying;
        if (_isPlaying != isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      }
    });

    // Initialize the controller
    await _videoPlayerController.initialize();

    // Get video duration after initialization
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
        _duration = _videoPlayerController.value.duration;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> _saveVideoEntry() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get the current user ID and username
      final authState = ref.read(authStateProvider);
      final userId = authState.valueOrNull?.id;
      final username = authState.valueOrNull?.displayName ?? 'user';

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert XFile to File
      final file = File(widget.videoFile.path);

      // Upload to Firebase Storage using our simplified service
      final storageService = ref.read(storageServiceProvider);
      final videoUrl = await storageService.uploadMedia(
        mediaFile: file,
        userId: userId,
        username: username,
        mediaType: 'videos',
      );

      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }

      // Create a new video log entry
      await ref
          .read(logEntriesProvider.notifier)
          .addVideoLogEntry(
            videoUrl: videoUrl,
            title: title,
            description: null,
            duration: _duration, // The actual video duration
            timestamp: DateTime(
              widget.date.year,
              widget.date.month,
              widget.date.day,
              DateTime.now().hour,
              DateTime.now().minute,
              DateTime.now().second,
            ),
          );

      // Close the sheet
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving video: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the upload state to show when uploading
    final uploadState = ref.watch(mediaUploadProvider);
    final isUploading =
        uploadState.isLoading && uploadState.mediaType == 'videos';
    final primaryColor = const Color(0xFF6E61FD);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Video preview with playback controls
          if (_isVideoInitialized) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                // Video player
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController),
                  ),
                ),

                // Play/Pause button overlay
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoPlayerController.value.isPlaying) {
                        _videoPlayerController.pause();
                      } else {
                        _videoPlayerController.play();
                      }
                    });
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      _videoPlayerController.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),

            // Video progress and duration
            const SizedBox(height: 8),
            Row(
              children: [
                // Current position
                ValueListenableBuilder(
                  valueListenable: _videoPlayerController,
                  builder: (context, VideoPlayerValue value, child) {
                    return Text(
                      _formatDuration(value.position),
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),

                // Progress bar
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _videoPlayerController,
                    builder: (context, VideoPlayerValue value, child) {
                      return Slider(
                        value: value.position.inMilliseconds.toDouble(),
                        min: 0,
                        max: value.duration.inMilliseconds.toDouble(),
                        activeColor: primaryColor,
                        inactiveColor: Colors.grey[300],
                        onChanged: (newPosition) {
                          _videoPlayerController.seekTo(
                            Duration(milliseconds: newPosition.toInt()),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Total duration
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            // Loading indicator while video initializes
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
          ],

          const SizedBox(height: 20),

          // Title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6E61FD),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simple upload status indicator
          if (isUploading) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploading video...',
                  style: TextStyle(fontSize: 14, color: primaryColor),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isSaving || isUploading) ? null : _saveVideoEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E61FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child:
                  _isSaving
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : const Text(
                        'Save Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
