import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple widget to display media upload status
class MediaUploadStatusWidget extends ConsumerWidget {
  const MediaUploadStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get state from provider
    final uploadState = ref.watch(mediaUploadProvider);
    final primaryColor = const Color(0xFF6E61FD);

    // Don't show if nothing is uploading
    if (!uploadState.isLoading) {
      return const SizedBox.shrink();
    }

    // Map media type to icon
    IconData getIcon() {
      switch (uploadState.mediaType) {
        case 'images':
          return Icons.image;
        case 'videos':
          return Icons.videocam;
        case 'audios':
          return Icons.mic;
        default:
          return Icons.upload_file;
      }
    }

    // Map media type to display text
    String getUploadText() {
      switch (uploadState.mediaType) {
        case 'images':
          return 'Uploading image...';
        case 'videos':
          return 'Uploading video...';
        case 'audios':
          return 'Uploading audio...';
        default:
          return 'Uploading media...';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Loading indicator
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(width: 12),

          // Icon and text
          Icon(getIcon(), color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            getUploadText(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),

          // Error message if any
          if (uploadState.hasError) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uploadState.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
