import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:echo/features/date_detail/widgets/edit_title_dialog.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class ImageLogItem extends ConsumerWidget {
  final ImageLogEntry entry;

  const ImageLogItem({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 12),
            _buildImageContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _editTitle(context, ref),
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFF6E61FD), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('h:mm a').format(entry.timestamp),
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
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _editTitle(context, ref);
                break;
              case 'download':
                await _downloadImage(context);
                break;
              case 'delete':
                _confirmDelete(context, ref);
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
        ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _viewFullImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 250,
          child: Image.network(
            entry.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6E61FD),
                  ),
                ),
              );
            },
            errorBuilder:
                (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                _FullImageView(imageUrl: entry.imageUrl, title: entry.title),
      ),
    );
  }

  void _editTitle(BuildContext context, WidgetRef ref) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder:
          (context) =>
              EditTitleDialog(initialTitle: entry.title, type: 'Image'),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      ref
          .read(logEntriesProvider.notifier)
          .updateLogEntryTitle(entry.id, newTitle.trim());
    }
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${entry.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${tempDir.path}/$fileName';

      await dio.download(entry.imageUrl, path);

      final snackBar = SnackBar(
        content: const Text('Image downloaded successfully'),
        backgroundColor: const Color(0xFF6E61FD),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      final snackBar = SnackBar(
        content: const Text('Failed to download image'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Delete Image?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this image?',
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
                      .deleteLogEntry(entry.id, entry.imageUrl);
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

class _FullImageView extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _FullImageView({required this.imageUrl, required this.title});

  @override
  State<_FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<_FullImageView> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // If already zoomed in, zoom out
      _transformationController.value = Matrix4.identity();
    } else {
      // If zoomed out, zoom in on the tapped point
      final position = _doubleTapDetails!.localPosition;
      final double scale = 3.0;

      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final zoomed =
          Matrix4.identity()
            ..translate(x, y)
            ..scale(scale);

      _transformationController.value = zoomed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
