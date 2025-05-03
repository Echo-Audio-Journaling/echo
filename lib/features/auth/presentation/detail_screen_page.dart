import 'package:flutter/material.dart';

class DetailScreenPage extends StatefulWidget {
  const DetailScreenPage({super.key});

  @override
  State<DetailScreenPage> createState() => _DetailScreenPageState();
}

class _DetailScreenPageState extends State<DetailScreenPage> {
  double _currentPosition = 0.27;
  final double _totalDuration = 2.45;
  bool _isPlaying = false;
  bool _isEditing = false;

  // Controller for the editable text field
  late TextEditingController _transcriptionController;

  // Initial transcription text
  final String _initialTranscription =
      'Lorem ipsum is simply dummy text of the printing and typesetting industry. '
      'Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, '
      'when an unknown printer took a galley of type and scrambled it to make a type specimen book. '
      'It has survived not only five centuries, but also the leap into electronic typesetting, '
      'remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset '
      'sheets containing Lorem Ipsum passages, and more recently with desktop publishing software '
      'like Aldus PageMaker including versions of Lorem Ipsum. Lorem Ipsum is simply dummy text of '
      'the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy '
      'text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to '
      'make a type specimen book. It has survived not only five centuries, but also the leap into '
      'electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with '
      'the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop '
      'publishing software like Aldus PageMaker including versions of Lorem Ipsum.';

  @override
  void initState() {
    super.initState();
    // Instead of static text, set the controller text to the actual transcription
    // from your database or passed through constructor
    _transcriptionController = TextEditingController(
      text: _initialTranscription,
    );
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildContent()),
          _buildAudioPlaybackControls(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Save button (replacing edit icon)
        IconButton(
          icon: Icon(
            _isEditing ? Icons.save : Icons.edit,
            color: Colors.black54,
          ),
          onPressed: () {
            setState(() {
              if (_isEditing) {
                // Save the changes
                _saveTranscription();
                _isEditing = false;

                // Show a snackbar to confirm
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Transcription saved successfully',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.green[700],
                    elevation: 6,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 100,
                      left: 20,
                      right: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                );
              } else {
                // Enter edit mode
                _isEditing = true;
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.black54),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                elevation: 0,
                margin: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).size.height -
                      200, // Positions at top
                  left: 20,
                  right: 20,
                ),
                content: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.red.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete Journal?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This action cannot be undone. All content will be permanently removed.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                () =>
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              // Your delete logic here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).size.height -
                                        200,
                                    left: 20,
                                    right: 20,
                                  ),
                                  content: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.green[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green[700],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Journal Deleted',
                                                style: TextStyle(
                                                  color: Colors.green[800],
                                                  fontWeight: FontWeight.w600, 
                                                ),
                                              ),
                                              Text(
                                                'The entry has been permanently removed',
                                                style: TextStyle(
                                                  color: Colors.green[700]!
                                                      .withOpacity(0.8),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Add this method
      ],
    );
  }

  // Save the transcription (here you would add Firebase update logic)
  void _saveTranscription() {
    // Here you would add the code to update the transcription in Firebase
    // For example:
    // FirebaseFirestore.instance
    //     .collection('journals')
    //     .doc(journalId)
    //     .update({'transcription': _transcriptionController.text});

    print('Saving transcription: ${_transcriptionController.text}');
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildTitleSection(),
          _buildDateTimeSection(),
          _buildTagChips(),
          _buildTranscriptionText(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return const Text(
      'Ideas on quantum',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateTimeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          'Friday, 25 April 2025',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text('10:36 PM', style: TextStyle(fontSize: 14, color: Colors.grey)),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTagChips() {
    return Row(
      children: [
        _buildChip('academics'),
        const SizedBox(width: 8),
        _buildChip('physics'),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF7B61FF),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildTranscriptionText() {
    // If in edit mode, show a text field, otherwise show a non-editable text
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: TextField(
          controller: _transcriptionController,
          maxLines: null, // Allows unlimited lines
          style: const TextStyle(fontSize: 16, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Edit transcription...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: Text(
          _transcriptionController.text,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      );
    }
  }

  Widget _buildAudioPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF7B61FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.grey.shade500,
              inactiveTrackColor: Colors.white,
              thumbColor: Colors.grey.shade500,
              overlayColor: const Color(0xFF7B61FF),
            ),
            child: Slider(
              value: _currentPosition,
              min: 0.0,
              max: _totalDuration,
              onChanged: (value) {
                setState(() {
                  _currentPosition = value;
                });
              },
            ),
          ),

          // Time and controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current time
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              // Play controls
              Row(
                children: [
                  // Rewind button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF7B61FF),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.replay_10, size: 20),
                      color: const Color(0xFF7B61FF),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Play/pause button
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B61FF),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 36,
                      ),
                      color: const Color(0xFF7B61FF),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Forward button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF7B61FF),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.forward_10, size: 20),
                      color: const Color(0xFF7B61FF),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              // Total time
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(double minutes) {
    int totalSeconds = (minutes * 60).round();
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
