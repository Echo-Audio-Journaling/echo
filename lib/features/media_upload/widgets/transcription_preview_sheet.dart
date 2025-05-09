import 'dart:io';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:echo/features/media_upload/services/speech_service.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:echo/features/media_upload/services/vertex_ai_service.dart';
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
  String _originalTranscription = "";
  String _transcription = "";
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isProcessingAI = false;
  bool _isError = false;
  String _loadingText = "Processing audio...";
  final List<String> _tags = [];
  late Duration _audioDuration;

  // Added: Flag to track if the widget is still mounted
  bool _isMounted = true;

  // Added: Tracking for active request tags
  final List<String> _activeRequestTags = [];

  @override
  void initState() {
    super.initState();
    _processAudio();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();

    // Set flag that we're no longer mounted
    _isMounted = false;

    // Cancel any ongoing requests
    // final vertexAIService = ref.read(vertexAiServiceProvider);
    // for (final tag in _activeRequestTags) {
    //   vertexAIService.cancelRequests(tag);
    // }

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

  // Helper method to safely update state
  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  Future<void> _processAudio() async {
    // Initialize processing state
    _safeSetState(() {
      _isLoading = true;
      _isError = false;
      _isProcessingAI = false;
      _loadingText = 'Processing audio...';
    });

    // Generate unique tags for this processing session
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final transcriptionTag = 'transcription-$uniqueId';
    final titleTagsTag = 'title-tags-$uniqueId';

    // Store the active request tags so we can cancel them if needed
    _activeRequestTags.add(transcriptionTag);
    _activeRequestTags.add(titleTagsTag);

    try {
      // STEP 1: Get audio duration
      _safeSetState(() {
        _loadingText = 'Analyzing audio...';
      });

      try {
        final player = AudioPlayer();
        await player.setFilePath(widget.audioPath);
        _audioDuration = player.duration ?? const Duration(seconds: 30);
        await player.dispose();
        debugPrint('✓ Audio duration: ${_audioDuration.inSeconds} seconds');
      } catch (e) {
        debugPrint('⚠️ Error getting audio duration: $e');
        // Fallback to estimation
        final file = File(widget.audioPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          _audioDuration = Duration(seconds: fileSize ~/ 16000);
        } else {
          _audioDuration = const Duration(seconds: 30);
        }
      }

      // Early exit if widget is disposed
      if (!_isMounted) return;

      // STEP 2: Verify file exists
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: ${widget.audioPath}');
      }

      // STEP 3: Log file info for debugging
      final fileSize = await file.length();
      final extension = widget.audioPath.split('.').last.toLowerCase();
      debugPrint('Audio file: ${widget.audioPath}');
      debugPrint('- Size: ${fileSize ~/ 1024} KB');
      debugPrint('- Format: $extension');

      // STEP 4: Transcribe audio
      _safeSetState(() {
        _loadingText = 'Transcribing audio...';
      });

      // Early exit if widget is disposed
      if (!_isMounted) return;

      final speechService = ref.read(speechServiceProvider);
      _originalTranscription = await speechService.transcribeAudio(
        widget.audioPath,
      );

      // Check if transcription succeeded
      if (_originalTranscription.isEmpty ||
          _originalTranscription.startsWith('Transcription failed')) {
        // Early exit if widget is disposed
        if (!_isMounted) return;

        _safeSetState(() {
          _isError = true;
          _transcription = _originalTranscription;
        });
        throw Exception('Transcription failed: $_originalTranscription');
      }

      // Early exit if widget is disposed
      if (!_isMounted) return;

      // STEP 5: Apply AI correction to transcription
      _safeSetState(() {
        _loadingText = 'Enhancing transcription...';
        _isProcessingAI = true;
      });

      // Get VertexAI service reference before any async operations
      final vertexAIService = ref.read(vertexAiServiceProvider);

      try {
        final correctedTranscription = await vertexAIService
            .correctTranscription(
              _originalTranscription,
              tag: transcriptionTag,
            );

        // Early exit if widget is disposed
        if (!_isMounted) return;

        _transcription = correctedTranscription;
        debugPrint('✓ Transcription enhanced successfully');
      } catch (e) {
        debugPrint('⚠️ Error enhancing transcription: $e');
        // Fallback to original transcription
        _transcription = _originalTranscription;
      }

      // Early exit if widget is disposed
      if (!_isMounted) return;

      // STEP 6: Generate title and tags
      _safeSetState(() {
        _loadingText = 'Generating title and tags...';
      });

      try {
        final aiResult = await vertexAIService.generateTitleAndTags(
          _transcription,
          tag: titleTagsTag,
        );

        // Early exit if widget is disposed
        if (!_isMounted) return;

        // Update title from AI result
        final aiTitle = aiResult['title'];
        if (aiTitle != null && aiTitle.isNotEmpty) {
          _titleController.text = aiTitle;
        } else {
          // Fallback title generation
          final words = _transcription.split(' ');
          final titleWords = words.length > 5 ? words.sublist(0, 5) : words;
          _titleController.text = '${titleWords.join(' ')}...';
        }

        // Update tags from AI result
        final aiTags = aiResult['tags'];
        _safeSetState(() {
          _tags.clear();
          if (aiTags != null && aiTags is List && aiTags.isNotEmpty) {
            _tags.addAll(List<String>.from(aiTags));
          } else {
            // Add some default tags based on keywords
            _addDefaultTags();
          }
        });

        debugPrint('✓ Title and tags generated successfully');
      } catch (e) {
        // Early exit if widget is disposed
        if (!_isMounted) return;

        debugPrint('⚠️ Error generating title and tags: $e');

        // Fallback title
        final words = _transcription.split(' ');
        final titleWords = words.length > 5 ? words.sublist(0, 5) : words;
        _titleController.text = '${titleWords.join(' ')}...';

        // Add default tags
        _safeSetState(() {
          _tags.clear();
          _addDefaultTags();
        });
      }
    } catch (e) {
      // Early exit if widget is disposed
      if (!_isMounted) return;

      debugPrint('❌ Error in _processAudio: $e');

      // Handle the error case
      _transcription =
          _originalTranscription.isEmpty
              ? "Transcription failed. Please try again."
              : _originalTranscription;

      _titleController.text =
          "Audio Recording ${DateTime.now().toString().substring(0, 16)}";

      _safeSetState(() {
        _isError = true;
        _tags.clear();
      });
    } finally {
      // Cancel any ongoing requests to be safe
      if (_isMounted) {
        final vertexAIService = ref.read(vertexAiServiceProvider);
        for (final tag in _activeRequestTags) {
          vertexAIService.cancelRequests(tag);
        }
        _activeRequestTags.clear();

        // Update state
        _safeSetState(() {
          _isLoading = false;
          _isProcessingAI = false;
        });
      }
    }
  }

  // Helper method to generate default tags based on content
  void _addDefaultTags() {
    // Extract potential tags from transcription
    final words = _transcription.toLowerCase().split(' ');
    final stopWords = {
      'the',
      'and',
      'a',
      'to',
      'of',
      'in',
      'is',
      'it',
      'that',
      'for',
      'you',
      'was',
      'with',
      'on',
      'are',
      'this',
      'have',
      'from',
      'be',
      'i',
      'me',
      'my',
      'we',
      'our',
      'they',
      'their',
      'he',
      'she',
      'his',
      'her',
    };

    // Count word frequency excluding stop words
    final wordFrequency = <String, int>{};
    for (final word in words) {
      final cleaned = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      if (cleaned.length > 3 && !stopWords.contains(cleaned)) {
        wordFrequency[cleaned] = (wordFrequency[cleaned] ?? 0) + 1;
      }
    }

    // Sort by frequency and take top 5
    final topWords =
        wordFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final potentialTags = topWords.take(5).map((e) => e.key).toList();

    // Ensure we have at least 5 tags
    if (potentialTags.length < 5) {
      // Add some generic tags based on audio duration
      final durationInMinutes = _audioDuration.inMinutes;

      if (durationInMinutes < 1) {
        potentialTags.add('short');
      } else if (durationInMinutes > 5) {
        potentialTags.add('long');
      }

      // Add current date-based tag
      final now = DateTime.now();
      potentialTags.add('${now.year}-${now.month}');

      // Add audio-related tag
      potentialTags.add('recording');

      // Add a generic note tag
      potentialTags.add('note');
    }

    // Take only first 5 tags
    _tags.addAll(potentialTags.take(5));
  }

  Future<void> _saveAudioEntry() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    _safeSetState(() {
      _isSaving = true;
    });

    try {
      // Early exit if widget is disposed
      if (!_isMounted) return;

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

      // Early exit if widget is disposed
      if (!_isMounted) return;

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

      // Early exit if widget is disposed
      if (!_isMounted) return;

      // Close the sheet
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio saved successfully')),
        );
      }
    } catch (e) {
      // Early exit if widget is disposed
      if (!_isMounted) return;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving audio: $e')));
      }
    } finally {
      if (mounted) {
        _safeSetState(() {
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
                    if (_isProcessingAI) ...[
                      SizedBox(height: 20),
                      // Premium Skip AI Processing Button with Animation
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF6E61FD).withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6E61FD).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Cancel ongoing requests
                              final vertexAIService = ref.read(
                                vertexAiServiceProvider,
                              );
                              for (final tag in _activeRequestTags) {
                                vertexAIService.cancelRequests(tag);
                              }
                              _activeRequestTags.clear();

                              // Use original transcription and default title/tags
                              _safeSetState(() {
                                _transcription = _originalTranscription;
                                _titleController.text =
                                    "Audio Recording ${DateTime.now().toString().substring(0, 16)}";
                                _isProcessingAI = false;
                                _isLoading = false;
                                _tags.clear();
                                _addDefaultTags();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.skip_next,
                                    color: const Color(0xFF6E61FD),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Skip AI Processing',
                                    style: TextStyle(
                                      color: const Color(0xFF6E61FD),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
              : _isError
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

                    // Transcription section with toggle if both original and enhanced exist
                    _buildTranscriptionSection(),

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

  // State for transcription toggle
  bool _showingOriginal = false;

  // Widget to build transcription section with toggle if available
  Widget _buildTranscriptionSection() {
    final hasEnhancedTranscription =
        _originalTranscription != _transcription &&
        _originalTranscription.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transcription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (hasEnhancedTranscription)
              TextButton.icon(
                onPressed: () {
                  _safeSetState(() {
                    _showingOriginal = !_showingOriginal;
                  });
                },
                icon: Icon(
                  _showingOriginal ? Icons.auto_fix_high : Icons.history,
                  size: 16,
                  color: const Color(0xFF6E61FD),
                ),
                label: Text(
                  _showingOriginal ? 'Show Enhanced' : 'Show Original',
                  style: const TextStyle(
                    color: Color(0xFF6E61FD),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SingleChildScrollView(
            child: Text(
              hasEnhancedTranscription && _showingOriginal
                  ? _originalTranscription
                  : _transcription,
            ),
          ),
        ),
        if (hasEnhancedTranscription) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _showingOriginal
                  ? 'Original transcription'
                  : 'AI-enhanced transcription',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
