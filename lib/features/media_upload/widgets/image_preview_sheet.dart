// Simplified image_preview_sheet.dart
import 'dart:io';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';

// Image preview after selecting an image
class ImagePreviewSheet extends ConsumerStatefulWidget {
  final XFile imageFile;
  final DateTime date;

  const ImagePreviewSheet({
    super.key,
    required this.imageFile,
    required this.date,
  });

  @override
  ConsumerState<ImagePreviewSheet> createState() => _ImagePreviewSheetState();
}

class _ImagePreviewSheetState extends ConsumerState<ImagePreviewSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

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

      // Convert XFile to File
      final file = File(widget.imageFile.path);

      // Upload to Firebase Storage using our simplified service
      final storageService = ref.read(storageServiceProvider);
      final imageUrl = await storageService.uploadMedia(
        mediaFile: file,
        userId: userId,
        username: username,
        mediaType: 'images',
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Create a new image log entry
      await ref
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
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
        uploadState.isLoading && uploadState.mediaType == 'images';
    final primaryColor = const Color(0xFF6E61FD);

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
          const SizedBox(height: 16),

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
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploading image...',
                  style: TextStyle(fontSize: 14, color: primaryColor),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isSaving || isUploading) ? null : _saveImageEntry,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
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
        ],
      ),
    );
  }
}
