import 'package:echo/app/router.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:echo/features/date_detail/widgets/edit_title_dialog.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';

class AudioLogItem extends ConsumerStatefulWidget {
  final AudioLogEntry entry;

  const AudioLogItem({super.key, required this.entry});

  @override
  ConsumerState<AudioLogItem> createState() => _AudioLogItemState();
}

class _AudioLogItemState extends ConsumerState<AudioLogItem> {
  late AudioPlayer _audioPlayer;
  double _playbackPosition = 0;
  bool _isInitialized = false;

  // Constants for skipping
  static const int _skipDurationSeconds = 10;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
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
        final isPlaying = playerState.playing;
        if (isPlaying != widget.entry.isPlaying) {
          ref
              .read(logEntriesProvider.notifier)
              .toggleAudioPlaying(widget.entry.id, isPlaying);
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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

  // New method to skip backward
  void _skipBackward() async {
    if (!_isInitialized) return;

    final currentPosition = _audioPlayer.position;
    final newPosition =
        currentPosition - Duration(seconds: _skipDurationSeconds);

    // Ensure we don't seek before the beginning
    await _audioPlayer.seek(
      newPosition.isNegative ? Duration.zero : newPosition,
    );
  }

  // New method to skip forward
  void _skipForward() async {
    if (!_isInitialized) return;

    final currentPosition = _audioPlayer.position;
    final newPosition =
        currentPosition + Duration(seconds: _skipDurationSeconds);

    // Ensure we don't seek past the end
    if (newPosition <= widget.entry.duration) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(widget.entry.duration);
    }
  }

  void _editTitle() async {
    final newTitle = await showDialog<String>(
      context: context,
      builder:
          (context) =>
              EditTitleDialog(initialTitle: widget.entry.title, type: 'Audio'),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      ref
          .read(logEntriesProvider.notifier)
          .updateLogEntryTitle(widget.entry.id, newTitle.trim());
    }
  }

  void _viewFullTranscription() {
    ref.read(routerProvider).go('/audio/${widget.entry.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.entry.tags.isNotEmpty) _buildTags(),
            const SizedBox(height: 12),
            _buildTranscriptionPreview(),
            const SizedBox(height: 16),
            _buildAudioPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _editTitle,
            child: Row(
              children: [
                const Icon(Icons.mic, color: Color(0xFF6E61FD), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('h:mm a').format(widget.entry.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: Colors.white,
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') {
              _editTitle();
            } else if (value == 'delete') {
              _confirmDelete();
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Title'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // Add this new method to build the tags section
  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.entry.tags.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.entry.tags[index],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTranscriptionPreview() {
    return GestureDetector(
      onTap: _viewFullTranscription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry.previewText,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.entry.transcription.length >
              widget.entry.previewText.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Read more',
                style: TextStyle(
                  color: const Color(0xFF6E61FD),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final isPlaying = widget.entry.isPlaying;
    final durationText = _formatDuration(widget.entry.duration);

    // Calculate current position text
    final positionDuration = Duration(
      milliseconds:
          (_playbackPosition * widget.entry.duration.inMilliseconds).toInt(),
    );
    final positionText = _formatDuration(positionDuration);

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF6E61FD),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: const Color(0xFF6E61FD),
            overlayColor: const Color(0xFF6E61FD).withOpacity(0.2),
          ),
          child: Slider(
            value: _playbackPosition.clamp(0.0, 1.0),
            onChanged: _seekTo,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                positionText,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              _buildPlaybackControls(isPlaying),
              Text(
                durationText,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method to build the playback controls with skip buttons
  Widget _buildPlaybackControls(bool isPlaying) {
    const Color primaryColor = Color(0xFF6E61FD);
    const double mainButtonSize = 42;
    const double skipButtonSize = 28;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Backward skip button
        IconButton(
          icon: const Icon(
            Icons.replay_10,
            color: primaryColor,
            size: skipButtonSize,
          ),
          onPressed: _isInitialized ? _skipBackward : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(), // Remove default padding
          visualDensity: VisualDensity.compact,
        ),

        // Play/Pause button
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: primaryColor,
            size: mainButtonSize,
          ),
          onPressed: _isInitialized ? _togglePlayback : null,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),

        // Forward skip button
        IconButton(
          icon: const Icon(
            Icons.forward_10,
            color: primaryColor,
            size: skipButtonSize,
          ),
          onPressed: _isInitialized ? _skipForward : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(), // Remove default padding
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Delete Audio Entry?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this audio entry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(logEntriesProvider.notifier)
                      .deleteLogEntry(widget.entry.id);
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
}
