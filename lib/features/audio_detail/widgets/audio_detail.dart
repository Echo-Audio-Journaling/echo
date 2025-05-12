import 'package:echo/app/router.dart';
import 'package:echo/features/audio_detail/provider/audio_entry_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';

class AudioDetailWidget extends ConsumerStatefulWidget {
  final AudioLogEntry entry;
  final String previousRoute;

  const AudioDetailWidget({
    super.key,
    required this.entry,
    required this.previousRoute,
  });

  @override
  ConsumerState<AudioDetailWidget> createState() => _AudioDetailWidgetState();
}

class _AudioDetailWidgetState extends ConsumerState<AudioDetailWidget> {
  late AudioPlayer _audioPlayer;
  late TextEditingController _titleController;
  late TextEditingController _transcriptionController;
  late TextEditingController _tagController;
  double _playbackPosition = 0;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isFavorite = false;
  bool _isEditing = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _transcriptionController = TextEditingController(
      text: widget.entry.transcription,
    );
    _tagController = TextEditingController();
    _isFavorite = widget.entry.isFavorite;
    _tags = List.from(widget.entry.tags);
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _transcriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setUrl(widget.entry.audioUrl);
      setState(() => _isInitialized = true);

      // Listen to playback position changes
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _playbackPosition =
                position.inMilliseconds / widget.entry.duration.inMilliseconds;
          });
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((playerState) {
        if (mounted) {
          setState(() {
            _isPlaying = playerState.playing;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  void _togglePlayback() async {
    if (!_isInitialized) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _seekTo(double position) async {
    if (!_isInitialized) return;

    final seekPositionMs =
        (position * widget.entry.duration.inMilliseconds).toInt();
    await _audioPlayer.seek(Duration(milliseconds: seekPositionMs));
  }

  void _skipBackward() async {
    if (!_isInitialized) return;

    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await _audioPlayer.seek(
      newPosition.isNegative ? Duration.zero : newPosition,
    );
  }

  void _skipForward() async {
    if (!_isInitialized) return;

    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition <= widget.entry.duration) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(widget.entry.duration);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // If exiting edit mode without saving, revert to original values
        _titleController.text = widget.entry.title;
        _transcriptionController.text = widget.entry.transcription;
        _tags = List.from(widget.entry.tags);
      }
    });
  }

  void _saveChanges() {
    // Get updated values
    final updatedTitle = _titleController.text.trim();
    final updatedTranscription = _transcriptionController.text.trim();

    // Create updated entry
    final updatedEntry = AudioLogEntry(
      id: widget.entry.id,
      timestamp: widget.entry.timestamp,
      title: updatedTitle,
      audioUrl: widget.entry.audioUrl,
      transcription: updatedTranscription,
      duration: widget.entry.duration,
      isPlaying: _isPlaying,
      tags: _tags,
      isFavorite: _isFavorite,
    );

    // Update in provider
    ref.read(logEntriesProvider.notifier).updateAudioEntry(updatedEntry);

    // Refresh the entry in the provider
    final _ = ref.refresh(audioEntryProvider(widget.entry.id));

    // Exit edit mode
    setState(() {
      _isEditing = false;
    });

    // Show success message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Changes saved successfully')));
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Audio Entry?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this audio entry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _deleteEntry();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _deleteEntry() {
    // Delete entry using provider
    ref
        .read(logEntriesProvider.notifier)
        .deleteLogEntry(widget.entry.id, widget.entry.audioUrl);

    // Navigate back after deletion
    Navigator.pop(context);

    // Show confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E61FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            DateTime dateTime = widget.entry.timestamp;
            final year = dateTime.year;
            final month = dateTime.month;
            final day = dateTime.day;

            if (widget.previousRoute == "home") {
              ref.read(routerProvider).go('/');
            } else if (widget.previousRoute == "date_detail") {
              ref.read(routerProvider).go('/date/$year/$month/$day');
            } else if (widget.previousRoute == "search") {
              ref.read(routerProvider).go('/search');
            } else {
              ref.read(routerProvider).go('/');
            }
          },
        ),
        title: const Text(
          'Audio Detail',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Favorite button
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              // Toggle favorite status
              setState(() {
                _isFavorite = !_isFavorite;
              });
              _saveChanges();
            },
          ),
          // Edit/Save button - toggles between edit and save
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _isEditing ? _saveChanges : _toggleEditMode,
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content - scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  _isEditing
                      ? TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )
                      : Text(
                        _titleController.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                  // Date and time
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy • h:mm a',
                      ).format(widget.entry.timestamp),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),

                  // Tags section
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child:
                              _tags.isEmpty
                                  ? _isEditing
                                      ? const Text(
                                        'Add tags to categorize this entry',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      )
                                      : const SizedBox.shrink()
                                  : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _tags.length,
                                    separatorBuilder:
                                        (context, index) =>
                                            const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child:
                                            _isEditing
                                                ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _tags[index],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: primaryColor,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 0.5,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    InkWell(
                                                      onTap:
                                                          () => _removeTag(
                                                            _tags[index],
                                                          ),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Center(
                                                  child: Text(
                                                    _tags[index],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: primaryColor,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.5,
                                                        ),
                                                  ),
                                                ),
                                      );
                                    },
                                  ),
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: Icon(Icons.add_circle, color: primaryColor),
                          onPressed: () {
                            // Show add tag dialog
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Add Tag'),
                                    content: TextField(
                                      controller: _tagController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter tag name',
                                      ),
                                      onSubmitted: (_) {
                                        _addTag();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _addTag();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  const Divider(height: 1, thickness: 1),

                  // Transcription section - blog-style
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    child:
                        _isEditing
                            ? TextField(
                              controller: _transcriptionController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter transcription',
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                            : Text(
                              _transcriptionController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),

          // Audio player controls
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    // Calculate current position text
    final positionDuration = Duration(
      milliseconds:
          (_playbackPosition * widget.entry.duration.inMilliseconds).toInt(),
    );
    final positionText = _formatDuration(positionDuration);
    final durationText = _formatDuration(widget.entry.duration);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF6E61FD),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider for position
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: _playbackPosition.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: _seekTo,
            ),
          ),

          // Time and controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current time
              Text(
                positionText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              // Playback controls
              Row(
                children: [
                  // Rewind button
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _isInitialized ? _skipBackward : null,
                  ),

                  // Play/pause button
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFF6E61FD),
                        size: 36,
                      ),
                      onPressed: _isInitialized ? _togglePlayback : null,
                    ),
                  ),

                  // Forward button
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _isInitialized ? _skipForward : null,
                  ),
                ],
              ),

              // Total duration
              Text(
                durationText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
