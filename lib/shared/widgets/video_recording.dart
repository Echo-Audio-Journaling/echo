// video_recording_widget.dart

import 'package:flutter/material.dart';

class VideoRecordingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isRecording;

  const VideoRecordingButton({
    super.key,
    required this.onPressed,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'record_button',
          backgroundColor: isRecording ? Colors.red : Colors.blue,
          onPressed: onPressed,
          child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
        ),
        SizedBox(height: 8),
        Text(
          isRecording ? "Recording..." : "Record",
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
