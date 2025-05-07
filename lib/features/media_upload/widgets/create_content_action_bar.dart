// Simplified create_content_action_bar.dart
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:echo/features/media_upload/widgets/image_preview_sheet.dart';
import 'package:echo/features/media_upload/widgets/media_upload_progress.dart';
import 'package:echo/features/media_upload/widgets/transcription_preview_sheet.dart';
import 'package:echo/features/media_upload/widgets/video_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

// Provider to store temporary recorded audio path
final tempAudioPathProvider = StateProvider<String?>((ref) => null);

// Provider to store recording state
final isRecordingProvider = StateProvider<bool>((ref) => false);

class CreateContentActionBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const CreateContentActionBar({super.key, required this.selectedDate});

  @override
  ConsumerState<CreateContentActionBar> createState() =>
      _CreateContentActionBarState();
}

class _CreateContentActionBarState extends ConsumerState<CreateContentActionBar>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  late final AudioRecorder _audioRecorder;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Check and request permissions for microphone and storage
    Map<Permission, PermissionStatus> statuses =
        await [Permission.microphone, Permission.storage].request();

    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    await _checkPermissions();

    final isGranted = await _audioRecorder.hasPermission();
    if (!isGranted) {
      return;
    }

    // Get temporary directory to save the recording
    final directory = await getTemporaryDirectory();
    final uuid = const Uuid().v4();
    final path = '${directory.path}/$uuid.m4a';

    // Configure recording options
    await _audioRecorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    ref.read(tempAudioPathProvider.notifier).state = path;
    ref.read(isRecordingProvider.notifier).state = true;

    // Start animation
    _animationController.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving the recording')),
      );
      return;
    }

    ref.read(isRecordingProvider.notifier).state = false;
    _animationController.stop();

    // Show transcription UI
    if (mounted) {
      _showTranscriptionUI(path);
    }
  }

  void _showTranscriptionUI(String audioPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => TranscriptionSheet(
            audioPath: audioPath,
            date: widget.selectedDate,
          ),
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      if (isVideo) {
        final XFile? videoFile = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );

        if (videoFile != null && mounted) {
          Navigator.pop(context); // Close the bottom sheet
          _showVideoPreview(videoFile);
        }
      } else {
        final XFile? imageFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (imageFile != null && mounted) {
          Navigator.pop(context); // Close the bottom sheet
          _showImagePreview(imageFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking ${isVideo ? 'video' : 'image'}: $e'),
          ),
        );
      }
    }
  }

  void _showMediaSourceOptions(bool isVideo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6E61FD)),
                title: Text('Take ${isVideo ? 'Video' : 'Photo'}'),
                onTap: () => _pickMedia(ImageSource.camera, isVideo),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF6E61FD),
                ),
                title: Text('Choose from ${isVideo ? 'Videos' : 'Gallery'}'),
                onTap: () => _pickMedia(ImageSource.gallery, isVideo),
              ),
            ],
          ),
    );
  }

  void _showImagePreview(XFile imageFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ImagePreviewSheet(
            imageFile: imageFile,
            date: widget.selectedDate,
          ),
    );
  }

  void _showVideoPreview(XFile videoFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => VideoPreviewSheet(
            videoFile: videoFile,
            date: widget.selectedDate,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final primaryColor = const Color(0xFF6E61FD);

    // Watch for upload state
    final uploadState = ref.watch(mediaUploadProvider);
    final isUploading = uploadState.isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show simplified upload status widget if any media is uploading
        const MediaUploadStatusWidget(),

        // Main action bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main content row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left action - Image upload
                  _buildSideButton(
                    icon: Icons.photo,
                    onTap:
                        (isRecording || isUploading)
                            ? null
                            : () => _showMediaSourceOptions(false),
                    color: primaryColor,
                  ),

                  const SizedBox(width: 24),

                  // Center action - Audio recording
                  _buildCenterButton(
                    isRecording: isRecording,
                    primaryColor: primaryColor,
                    animationController: _animationController,
                    onTap:
                        isUploading
                            ? null
                            : (isRecording ? _stopRecording : _startRecording),
                  ),

                  const SizedBox(width: 24),

                  // Right action - Video upload
                  _buildSideButton(
                    icon: Icons.videocam,
                    onTap:
                        (isRecording || isUploading)
                            ? null
                            : () => _showMediaSourceOptions(true),
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhanced side button with label
Widget _buildSideButton({
  required IconData icon,
  required VoidCallback? onTap,
  required Color color,
}) {
  final isDisabled = onTap == null;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDisabled ? Colors.grey[200] : color.withOpacity(0.12),
              border: Border.all(
                color: isDisabled ? Colors.grey[400]! : color,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? Colors.grey[400] : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
  );
}

// Enhanced center recording button with subtle animation
Widget _buildCenterButton({
  required bool isRecording,
  required Color primaryColor,
  required AnimationController animationController,
  required VoidCallback? onTap,
}) {
  final isDisabled = onTap == null;

  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle recording indicator
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer indicator for recording state - more subtle animation
            if (isRecording)
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return Container(
                    height: 76 + (animationController.value * 2),
                    width: 76 + (animationController.value * 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.red.withOpacity(
                          0.2 + (0.1 * animationController.value),
                        ),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),

            // Main button
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDisabled
                        ? Colors.grey[400]
                        : (isRecording ? Colors.red : primaryColor),
                boxShadow: [
                  if (!isDisabled)
                    BoxShadow(
                      color:
                          isRecording
                              ? Colors.red.withOpacity(0.3)
                              : primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic,
                  key: ValueKey(isRecording),
                  color: isDisabled ? Colors.grey[300] : Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Small recording indicator dot
            if (isRecording)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  height: 6,
                  width: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}
