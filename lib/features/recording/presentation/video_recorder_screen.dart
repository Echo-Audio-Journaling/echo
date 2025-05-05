// // import 'dart:async';
// import 'dart:async';
// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:gal/gal.dart';
// import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';

// class VideoRecorderScreen extends StatefulWidget {
//   const VideoRecorderScreen({super.key});

//   @override
//   State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
// }

// class _VideoRecorderScreenState extends State<VideoRecorderScreen>
//     with SingleTickerProviderStateMixin {
//   late List<CameraDescription> cameras;
//   CameraController? controller;

//   File? recordedVideoFile;
//   VideoPlayerController? videoController;

//   bool isRecording = false;
//   Timer? _recordingTimer;
//   Duration _recordingDuration = Duration.zero;

//   late AnimationController _progressController;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 10),
//     )..addListener(() => setState(() {}));
//   }

//   Future<void> _initializeCamera() async {
//     try {
//       cameras = await availableCameras();
//       if (cameras.isNotEmpty) {
//         controller = CameraController(
//           cameras[0],
//           ResolutionPreset.medium,
//           enableAudio: true,
//         );
//         await controller!.initialize();
//         if (mounted) setState(() {});
//       }
//     } catch (e) {
//       print("Camera init error: $e");
//     }
//   }

//   Future<void> _switchCamera() async {
//     final int newIndex =
//         (cameras.indexOf(controller!.description) == 0) ? 1 : 0;
//     await controller?.dispose();
//     controller = CameraController(cameras[newIndex], ResolutionPreset.medium);
//     await controller!.initialize();
//     setState(() {});
//   }

//   Future<void> _startRecording() async {
//     if (controller == null || !controller!.value.isInitialized || isRecording)
//       return;

//     final String filePath = path.join(
//       (await getTemporaryDirectory()).path,
//       '${DateTime.now().millisecondsSinceEpoch}.mp4',
//     );

//     await controller!.startVideoRecording();
//     setState(() {
//       isRecording = true;
//       _recordingDuration = Duration.zero;
//       _progressController.value = 0;
//     });

//     _progressController.forward();

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() => _recordingDuration += const Duration(seconds: 1));
//       if (_recordingDuration.inSeconds >= 10) _stopRecording(filePath);
//     });
//   }

//   Future<void> _stopRecording([String? filePath]) async {
//     if (!isRecording ||
//         controller == null ||
//         !controller!.value.isRecordingVideo)
//       return;

//     _recordingTimer?.cancel();
//     _progressController.reset();
//     final XFile xfile = await controller!.stopVideoRecording();

//     final String finalPath =
//         filePath ??
//         path.join(
//           (await getTemporaryDirectory()).path,
//           '${DateTime.now().millisecondsSinceEpoch}.mp4',
//         );
//     final File savedFile = await File(xfile.path).copy(finalPath);

//     setState(() {
//       isRecording = false;
//       recordedVideoFile = savedFile;
//     });

//     await _initializeVideoPlayer(savedFile);
//   }

//   Future<void> _initializeVideoPlayer(File file) async {
//     videoController?.dispose();
//     videoController = VideoPlayerController.file(file);
//     await videoController!.initialize();
//     videoController!
//       ..setLooping(true)
//       ..play();
//     setState(() {});
//   }

//   Future<void> _pickFromGallery() async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
//     if (file != null) {
//       final File localFile = File(file.path);
//       await _initializeVideoPlayer(localFile);
//       setState(() => recordedVideoFile = localFile);
//       context.pop(localFile);
//     }
//   }

//   Future<void> _saveToGallery() async {
//     if (recordedVideoFile != null) {
//       await Gal.putVideo(recordedVideoFile!.path);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Video saved to gallery!')));
//     }
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     videoController?.dispose();
//     _progressController.dispose();
//     _recordingTimer?.cancel();
//     super.dispose();
//   }

//   Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap) {
//     final isRecord = label.toLowerCase().contains('record');
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (isRecord && isRecording)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Text(
//               _formatDuration(_recordingDuration),
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//             ),
//           ),
//         GestureDetector(
//           onLongPressStart: (_) async => await _startRecording(),
//           onLongPressEnd: (_) async => await _stopRecording(),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               if (isRecord && isRecording)
//                 SizedBox(
//                   width: 72,
//                   height: 72,
//                   child: CircularProgressIndicator(
//                     value: _progressController.value,
//                     valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
//                     strokeWidth: 6,
//                   ),
//                 ),
//               FloatingActionButton(
//                 heroTag: label,
//                 backgroundColor:
//                     isRecord
//                         ? (isRecording ? Colors.red : Colors.blue)
//                         : Colors.grey[800],
//                 onPressed: isRecord ? null : onTap,
//                 child: Icon(icon),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(color: Colors.white)),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body:
//           controller == null || !controller!.value.isInitialized
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   Positioned.fill(child: CameraPreview(controller!)),

//                   // Close Button
//                   Positioned(
//                     top: 40,
//                     left: 20,
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.close,
//                         color: Colors.red,
//                         size: 30,
//                       ),
//                       onPressed: () {
//                         videoController?.pause();
//                         context.pop();
//                       },
//                     ),
//                   ),

//                   // Video Preview
//                   if (recordedVideoFile != null &&
//                       videoController != null &&
//                       videoController!.value.isInitialized)
//                     Positioned.fill(
//                       child: Container(
//                         color: Colors.black,
//                         child: Center(
//                           child: AspectRatio(
//                             aspectRatio: videoController!.value.aspectRatio,
//                             child: VideoPlayer(videoController!),
//                           ),
//                         ),
//                       ),
//                     ),

//                   // Control Buttons
//                   Positioned(
//                     bottom: 30,
//                     left: 0,
//                     right: 0,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children:
//                           recordedVideoFile == null
//                               ? [
//                                 _buildActionButton(
//                                   Icons.video_library,
//                                   "Gallery",
//                                   _pickFromGallery,
//                                 ),
//                                 _buildActionButton(
//                                   isRecording
//                                       ? Icons.stop
//                                       : Icons.fiber_manual_record,
//                                   isRecording ? "Stop" : "Record",
//                                   isRecording
//                                       ? () => _stopRecording()
//                                       : () => _startRecording(),
//                                 ),
//                                 _buildActionButton(
//                                   Icons.flip_camera_ios,
//                                   "Switch",
//                                   _switchCamera,
//                                 ),
//                               ]
//                               : [
//                                 TextButton(
//                                   onPressed:
//                                       () => context.pop(recordedVideoFile),
//                                   child: const Text(
//                                     "Upload",
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     videoController?.pause();
//                                     setState(() => recordedVideoFile = null);
//                                   },
//                                   child: const Text(
//                                     "Delete",
//                                     style: TextStyle(color: Colors.red),
//                                   ),
//                                 ),
//                               ],
//                     ),
//                   ),

//                   // Save to Gallery Button
//                   if (recordedVideoFile != null)
//                     Positioned(
//                       bottom: 90,
//                       left: 0,
//                       right: 0,
//                       child: Center(
//                         child: ElevatedButton.icon(
//                           icon: const Icon(Icons.download),
//                           label: const Text("Save to Gallery"),
//                           onPressed: _saveToGallery,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
//   }
// }
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen>
    with SingleTickerProviderStateMixin {
  late List<CameraDescription> cameras;
  CameraController? controller;
  File? recordedVideoFile;
  VideoPlayerController? videoController;
  bool isRecording = false;
  late AnimationController _progressController;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
      setState(() {});
    });
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  void switchCamera() async {
    final newIndex =
        (cameras.indexOf(controller!.description) + 1) % cameras.length;
    await controller?.dispose();
    controller = CameraController(cameras[newIndex], ResolutionPreset.medium);
    await controller!.initialize();
    setState(() {});
  }

  Future<void> startRecording() async {
    if (controller == null || !controller!.value.isInitialized || isRecording)
      return;

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    await controller!.startVideoRecording();
    setState(() {
      isRecording = true;
      _recordingDuration = Duration.zero;
      _progressController.reset();
      _progressController.forward();
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
      if (_recordingDuration.inSeconds >= 10) stopRecording(filePath);
    });
  }

  Future<void> stopRecording([String? filePath]) async {
    if (!isRecording ||
        controller == null ||
        !controller!.value.isRecordingVideo)
      return;

    _recordingTimer?.cancel();
    _recordingTimer = null;
    _progressController.reset();

    final XFile recorded = await controller!.stopVideoRecording();
    final finalPath =
        filePath ??
        path.join(
          (await getTemporaryDirectory()).path,
          '${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
    final savedFile = await File(recorded.path).copy(finalPath);

    setState(() {
      isRecording = false;
      recordedVideoFile = savedFile;
    });

    await _initializeVideoPlayer(savedFile);
  }

  Future<void> _initializeVideoPlayer(File file) async {
    videoController?.dispose();
    videoController = VideoPlayerController.file(file);
    await videoController!.initialize();
    setState(() {});
    videoController!
      ..setLooping(true)
      ..play();
  }

  Future<void> pickFromGallery() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null) {
      final localFile = File(file.path);
      await _initializeVideoPlayer(localFile);
      setState(() => recordedVideoFile = localFile);
      context.pop(localFile);
    }
  }

  Future<void> saveToGallery() async {
    if (recordedVideoFile != null) {
      await Gal.putVideo(recordedVideoFile!.path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video saved to gallery!')));
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    videoController?.dispose();
    _progressController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          controller == null || !controller!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Positioned.fill(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller!.value.previewSize!.height,
                          height: controller!.value.previewSize!.width,
                          child: CameraPreview(controller!),
                        ),
                      ),
                    ),
                  ),

                  if (recordedVideoFile != null &&
                      videoController != null &&
                      videoController!.value.isInitialized)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: videoController!.value.aspectRatio,
                            child: VideoPlayer(videoController!),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 30,
                      ),
                      onPressed: () {
                        videoController?.pause();
                        context.pop();
                      },
                    ),
                  ),
                  if (recordedVideoFile == null)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildButton(
                            Icons.video_library,
                            "Gallery",
                            pickFromGallery,
                          ),
                          _buildRecordButton(),
                          _buildButton(
                            Icons.flip_camera_ios,
                            "Switch",
                            switchCamera,
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(recordedVideoFile),
                            child: const Text(
                              "Upload",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              videoController?.pause();
                              setState(() => recordedVideoFile = null);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (recordedVideoFile != null)
                    Positioned(
                      bottom: 90,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text("Save to Gallery"),
                          onPressed: saveToGallery,
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback? onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: Colors.grey[800],
          onPressed: onTap,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildRecordButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        GestureDetector(
          onLongPressStart: (_) => startRecording(),
          onLongPressEnd: (_) => stopRecording(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _progressController.value,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    strokeWidth: 6,
                  ),
                ),
              FloatingActionButton(
                backgroundColor: isRecording ? Colors.red : Colors.blue,
                onPressed: null,
                child: Icon(
                  isRecording ? Icons.stop : Icons.fiber_manual_record,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text("Record", style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
}
