import 'dart:io';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:echo/features/media_upload/services/speech_service.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:just_audio/just_audio.dart';

// Transcription UI after recording audio
class TranscriptionSheet extends ConsumerStatefulWidget {
  final String audioPath;
  final DateTime date;

  const TranscriptionSheet({
    super.key,
    required this.audioPath,
    required this.date,
  });

  @override
  ConsumerState<TranscriptionSheet> createState() => _TranscriptionSheetState();
}

class _TranscriptionSheetState extends ConsumerState<TranscriptionSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  String _transcription = "";
  bool _isLoading = true;
  bool _isSaving = false;
  String _loadingText = "";
  final List<String> _tags = [];
  late Duration _audioDuration;

  @override
  void initState() {
    super.initState();
    _processAudio();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Add a tag to the list
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Remove a tag from the list
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _processAudio() async {
    setState(() => _isLoading = true);

    try {
      // Try to get audio duration using just_audio
      try {
        final player = AudioPlayer();
        await player.setFilePath(widget.audioPath);
        _audioDuration = player.duration ?? const Duration(seconds: 30);
        await player.dispose();
        debugPrint('Audio duration: ${_audioDuration.inSeconds} seconds');
      } catch (e) {
        debugPrint('Error getting audio duration with just_audio: $e');
        // Fallback for duration estimation
        final file = File(widget.audioPath);
        final fileSize = await file.length();
        // FLAC estimation: ~16KB per second for 16kHz mono
        _audioDuration = Duration(seconds: fileSize ~/ 16000);
        debugPrint(
          'Estimated duration from file size: ${_audioDuration.inSeconds} seconds',
        );
      }

      // Transcribe the audio
      setState(() {
        _loadingText = 'Transcribing audio...';
      });

      final speechService = ref.read(speechServiceProvider);
      _transcription = await speechService.transcribeAudio(widget.audioPath);

      // Set title based on transcription if successful
      if (_transcription.isNotEmpty &&
          !_transcription.startsWith('Transcription failed')) {
        final words = _transcription.split(' ');
        final titleWords = words.length > 5 ? words.sublist(0, 5) : words;
        _titleController.text = '${titleWords.join(' ')}...';
      } else {
        _titleController.text =
            "Audio Recording ${DateTime.now().toString().substring(0, 16)}";
      }
    } catch (e) {
      debugPrint('Error processing audio: $e');
      _transcription = "Transcription failed. Please try again.";
      _titleController.text =
          "Audio Recording ${DateTime.now().toString().substring(0, 16)}";
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAudioEntry() async {
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

      // Upload to Firebase Storage using our simplified service
      final storageService = ref.read(storageServiceProvider);
      final audioUrl = await storageService.uploadMedia(
        mediaFile: File(widget.audioPath),
        userId: userId,
        username: username,
        mediaType: 'audios',
      );

      if (audioUrl == null) {
        throw Exception('Failed to upload audio');
      }

      // Create a new audio log entry with tags
      await ref
          .read(logEntriesProvider.notifier)
          .addAudioLogEntry(
            audioUrl: audioUrl,
            transcription: _transcription,
            duration: _audioDuration,
            title: title,
            timestamp: DateTime(
              widget.date.year,
              widget.date.month,
              widget.date.day,
              DateTime.now().hour,
              DateTime.now().minute,
              DateTime.now().second,
            ),
            tags: _tags,
          );

      // Close the sheet
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving audio: $e')));
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
        uploadState.isLoading && uploadState.mediaType == 'audios';
    final primaryColor = const Color(0xFF6E61FD);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child:
          _isLoading
              ? Center(
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
                      _loadingText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take a moment for longer recordings',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : _transcription.startsWith("Transcription failed")
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _transcription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _processAudio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E61FD),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
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

                    // Tags section
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tag input and add button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: 'Add a tag',
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTag,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF6E61FD),
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Display tags as a wrapped list of chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: const Color(
                                    0xFF6E61FD,
                                  ).withOpacity(0.2),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Transcription
                    const Text(
                      'Transcription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Fixed height container for transcription
                    Container(
                      height: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(child: Text(_transcription)),
                    ),

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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Uploading audio...',
                            style: TextStyle(fontSize: 14, color: primaryColor),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_isSaving || isUploading) ? null : _saveAudioEntry,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                    const SizedBox(height: 10), // Add some bottom padding
                  ],
                ),
              ),
    );
  }
}
