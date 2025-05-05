import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:echo/features/detail/provider/log_entries_provider.dart';

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
  late final AudioRecorder
  _audioRecorder; // Changed from Record to AudioRecorder
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder(); // Initialize with the new class name
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
        encoder: AudioEncoder.aacLc, // Updated to use the proper enum
        bitRate: 128000,
        sampleRate: 44100, // Changed from samplingRate to sampleRate
      ),
      path: path, // Path is now a named parameter
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

    // Show transcription UI (placeholder for now)
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
          (context) => _TranscriptionSheet(
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
          (context) => _ImagePreviewSheet(
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
          (context) => _VideoPreviewSheet(
            videoFile: videoFile,
            date: widget.selectedDate,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final primaryColor = const Color(0xFF6E61FD);

    return Container(
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
                    isRecording ? null : () => _showMediaSourceOptions(false),
                color: primaryColor,
              ),

              const SizedBox(width: 24),

              // Center action - Audio recording
              _buildCenterButton(
                isRecording: isRecording,
                primaryColor: primaryColor,
                animationController: _animationController,
                onTap: isRecording ? _stopRecording : _startRecording,
              ),

              const SizedBox(width: 24),

              // Right action - Video upload
              _buildSideButton(
                icon: Icons.videocam,
                onTap: isRecording ? null : () => _showMediaSourceOptions(true),
                color: primaryColor,
              ),
            ],
          ),
        ],
      ),
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

// Enhanced center recording button with animation
Widget _buildCenterButton({
  required bool isRecording,
  required Color primaryColor,
  required AnimationController animationController,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ripple effect for recording state
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing circle (only when recording)
            if (isRecording)
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return Container(
                    height: 84 + (animationController.value * 12),
                    width: 84 + (animationController.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(
                        0.1 * (1 - animationController.value),
                      ),
                      border: Border.all(
                        color: Colors.red.withOpacity(
                          0.3 * (1 - animationController.value),
                        ),
                        width: 2,
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
                color: isRecording ? Colors.red : primaryColor,
                boxShadow: [
                  BoxShadow(
                    color:
                        isRecording
                            ? Colors.red.withOpacity(0.4)
                            : primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
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
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Additional decorator dot for recording
            if (isRecording)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  height: 8,
                  width: 8,
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

// Transcription UI after recording audio
class _TranscriptionSheet extends ConsumerStatefulWidget {
  final String audioPath;
  final DateTime date;

  const _TranscriptionSheet({required this.audioPath, required this.date});

  @override
  ConsumerState<_TranscriptionSheet> createState() =>
      _TranscriptionSheetState();
}

class _TranscriptionSheetState extends ConsumerState<_TranscriptionSheet> {
  final TextEditingController _titleController = TextEditingController();
  String _transcription =
      ""; // In a real app, this would come from a transcription service
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _processAudio();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _processAudio() async {
    // Simulate transcription process
    setState(() => _isLoading = true);

    // This is a placeholder for actual transcription service
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock transcription and title
    _transcription =
        "This is a sample transcription of the audio recording. In a real app, this would be generated by a speech-to-text service.";
    _titleController.text =
        "Audio Recording ${DateTime.now().toString().substring(0, 16)}";

    setState(() => _isLoading = false);
  }

  Future<void> _saveAudioEntry() async {
    // For now, just save locally
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    // In a real app, you would upload to cloud storage first
    // For now, just use the local path
    final audioUrl = widget.audioPath;

    // Create a new audio log entry
    ref
        .read(logEntriesProvider.notifier)
        .addAudioLogEntry(
          audioUrl: audioUrl,
          transcription: _transcription,
          duration: const Duration(
            seconds: 30,
          ), // This would be calculated from the actual audio file
          title: title,
          timestamp: widget.date,
        );

    // Close the sheet
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Audio saved successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6E61FD),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Transcribing audio...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
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
                  const SizedBox(height: 20),

                  // Transcription
                  const Text(
                    'Transcription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(child: Text(_transcription)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAudioEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E61FD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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

// Image preview after selecting an image
class _ImagePreviewSheet extends ConsumerStatefulWidget {
  final XFile imageFile;
  final DateTime date;

  const _ImagePreviewSheet({required this.imageFile, required this.date});

  @override
  ConsumerState<_ImagePreviewSheet> createState() => _ImagePreviewSheetState();
}

class _ImagePreviewSheetState extends ConsumerState<_ImagePreviewSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text =
        "Image ${DateTime.now().toString().substring(0, 16)}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveImageEntry() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    // In a real app, you would upload to cloud storage first
    // For now, just use the local path
    final imageUrl = widget.imageFile.path;

    // Create a new image log entry
    ref
        .read(logEntriesProvider.notifier)
        .addImageLogEntry(
          imageUrl: imageUrl,
          title: title,
          description: _descriptionController.text.trim(),
          timestamp: widget.date,
        );

    // Close the sheet
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image saved successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imageFile.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
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
          const SizedBox(height: 12),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
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
            maxLines: 3,
          ),
          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveImageEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E61FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Video preview after selecting a video
class _VideoPreviewSheet extends ConsumerStatefulWidget {
  final XFile videoFile;
  final DateTime date;

  const _VideoPreviewSheet({required this.videoFile, required this.date});

  @override
  ConsumerState<_VideoPreviewSheet> createState() => _VideoPreviewSheetState();
}

class _VideoPreviewSheetState extends ConsumerState<_VideoPreviewSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text =
        "Video ${DateTime.now().toString().substring(0, 16)}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

    // In a real app, you would upload to cloud storage first
    // For now, just use the local path
    final videoUrl = widget.videoFile.path;

    // Create a new video log entry
    ref
        .read(logEntriesProvider.notifier)
        .addVideoLogEntry(
          videoUrl: videoUrl,
          title: title,
          description: _descriptionController.text.trim(),
          duration: const Duration(
            seconds: 30,
          ), // This would be calculated from the actual video
          timestamp: widget.date,
        );

    // Close the sheet
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video saved successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Video thumbnail (in a real app, you'd generate a thumbnail)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black87,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
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
          const SizedBox(height: 12),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
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
            maxLines: 3,
          ),
          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveVideoEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E61FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
