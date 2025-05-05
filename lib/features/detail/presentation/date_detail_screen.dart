import 'dart:io';

import 'package:echo/shared/widgets/video_recording.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime date;

  const DateDetailScreen({super.key, required this.date});

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  File? recordedVideoFile;
  VideoPlayerController? videoController;
  bool isRecording = false;

  Future<void> _initializeVideoPlayer(File file) async {
    videoController?.dispose();
    videoController = VideoPlayerController.file(file);
    await videoController!.initialize();
    setState(() {});
    videoController!.setLooping(true);
    videoController!.play();
  }

  Future<void> _navigateToRecorder() async {
    final result = await context.push<File?>('/recording');

    if (result != null && mounted) {
      setState(() {
        recordedVideoFile = result;
      });
      await _initializeVideoPlayer(result);
    }
  }

  Future<void> saveToGallery() async {
    if (recordedVideoFile != null) {
      await Gal.putVideo(recordedVideoFile!.path);

      if (!mounted) return; // Ensure the widget is still in the tree

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video saved to gallery!')));
    }
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.date.day}/${widget.date.month}/${widget.date.year}",
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TextNoteCard(
              title: "Ideas on quantum",
              dateText: "Friday 25, Jan, 2025 7:00 AM",
              content:
                  "if quantum particles are tiny and can’t be perceived to us with our naked eye, what’s the word for big …….",
            ),

            const SizedBox(height: 16),

            _ImageNoteCard(
              imageUrl:
                  "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
              dateText: "Friday 25, Jan, 2025 9:00 AM",
              description:
                  "Did a hike with Thomas and shot this sunset picture :)",
            ),
            const SizedBox(height: 24),

            // Display recorded video preview if available
            // if (recordedVideoFile != null &&
            //     videoController?.value.isInitialized == true)
            //   Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         "Recorded Video:",
            //         //style: Theme.of(context).textTheme.subtitle1,
            //       ),
            //       const SizedBox(height: 8),
            //       Container(
            //         height: 240,
            //         width: double.infinity,
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(12),
            //           border: Border.all(color: Colors.grey),
            //         ),
            //         child: ClipRRect(
            //           borderRadius: BorderRadius.circular(12),
            //           child: AspectRatio(
            //             aspectRatio: videoController!.value.aspectRatio,
            //             child: VideoPlayer(videoController!),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 20),
            //     ],
            //   ),
            if (recordedVideoFile != null)
              VideoNoteCard(
                videoPath: recordedVideoFile!.path,
                dateText: 'May 5, 2025',
                description: 'My 10-second memory from the park',
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VideoRecordingButton(
                  isRecording: isRecording,
                  onPressed: () {
                    setState(() {
                      isRecording = !isRecording;
                    });
                    _navigateToRecorder();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextNoteCard extends StatelessWidget {
  final String title;
  final String dateText;
  final String content;

  const _TextNoteCard({
    required this.title,
    required this.dateText,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              dateText,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageNoteCard extends StatelessWidget {
  final String imageUrl;
  final String dateText;
  final String description;

  const _ImageNoteCard({
    required this.imageUrl,
    required this.dateText,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoNoteCard extends StatefulWidget {
  final String videoPath; // Can be a local file path or a network URL
  final String dateText;
  final String description;
  final bool isNetwork;

  const VideoNoteCard({
    required this.videoPath,
    required this.dateText,
    required this.description,
    this.isNetwork = false, // true if videoPath is a URL
    Key? key,
  }) : super(key: key);

  @override
  State<VideoNoteCard> createState() => _VideoNoteCardState();
}

class _VideoNoteCardState extends State<VideoNoteCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.isNetwork
            ? VideoPlayerController.network(widget.videoPath)
            : VideoPlayerController.file(File(widget.videoPath));

    _controller.initialize().then((_) {
      setState(() {}); // Rebuild to show the first frame
    });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio:
                _controller.value.isInitialized
                    ? _controller.value.aspectRatio
                    : 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : Container(color: Colors.black12),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dateText,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
