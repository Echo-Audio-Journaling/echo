import 'package:echo/features/detail/provider/log_entries_provider.dart';
import 'package:echo/features/detail/widgets/edit_title_dialog.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoLogItem extends ConsumerStatefulWidget {
  final VideoLogEntry entry;

  const VideoLogItem({super.key, required this.entry});

  @override
  ConsumerState<VideoLogItem> createState() => _VideoLogItemState();
}

class _VideoLogItemState extends ConsumerState<VideoLogItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.entry.videoUrl),
    );

    try {
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: false,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF6E61FD),
          handleColor: const Color(0xFF6E61FD),
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.grey[100]!,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E61FD)),
            ),
          ),
        ),
        autoInitialize: true,
      );

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
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
            const SizedBox(height: 12),
            _buildVideoContent(),
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
                const Icon(Icons.videocam, color: Color(0xFF6E61FD), size: 20),
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
        _buildActionMenu(),
      ],
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _editTitle();
            break;
          case 'download':
            await _downloadVideo();
            break;
          case 'delete':
            _confirmDelete();
            break;
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
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Download'),
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
    );
  }

  Widget _buildVideoContent() {
    return GestureDetector(
      onTap: _viewFullVideo,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 220,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6E61FD),
                    ),
                  ),
                )
              else if (!_isInitialized)
                _buildErrorVideoDisplay()
              else
                _buildVideoPlayer(),

              // Video duration overlay
              if (_isInitialized)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(widget.entry.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Play button overlay
              if (_isInitialized && !_videoPlayerController.value.isPlaying)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return _chewieController != null
        ? Chewie(controller: _chewieController!)
        : const Center(child: Text('Error loading video'));
  }

  Widget _buildErrorVideoDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.white54, size: 40),
        const SizedBox(height: 8),
        Text(
          'Error loading video',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  void _viewFullVideo() {
    if (!_isInitialized) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullVideoView(entry: widget.entry),
      ),
    );
  }

  void _editTitle() async {
    final newTitle = await showDialog<String>(
      context: context,
      builder:
          (context) =>
              EditTitleDialog(initialTitle: widget.entry.title, type: 'Video'),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      ref
          .read(logEntriesProvider.notifier)
          .updateLogEntryTitle(widget.entry.id, newTitle.trim());
    }
  }

  Future<void> _downloadVideo() async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.entry.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = '${tempDir.path}/$fileName';

      final snackBar = SnackBar(
        content: const Text('Downloading video...'),
        backgroundColor: const Color(0xFF6E61FD),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      await dio.download(widget.entry.videoUrl, path);

      if (context.mounted) {
        final successSnackBar = SnackBar(
          content: const Text('Video downloaded successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (context.mounted) {
        final errorSnackBar = SnackBar(
          content: const Text('Failed to download video'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Delete Video?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this video?',
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _FullVideoView extends StatefulWidget {
  final VideoLogEntry entry;

  const _FullVideoView({required this.entry});

  @override
  State<_FullVideoView> createState() => _FullVideoViewState();
}

class _FullVideoViewState extends State<_FullVideoView> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.entry.videoUrl),
    );

    try {
      await _videoPlayerController.initialize();

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF6E61FD),
            handleColor: const Color(0xFF6E61FD),
            backgroundColor: Colors.grey[300]!,
            bufferedColor: Colors.grey[100]!,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E61FD)),
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing full video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.entry.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child:
              _isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6E61FD),
                    ),
                  ),
        ),
      ),
    );
  }
}
