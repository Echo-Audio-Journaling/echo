import 'package:echo/app/router.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SearchPreviewCard extends ConsumerWidget {
  final LogEntry entry;
  final bool isCompact;
  final VoidCallback? onTap; // Added callback for custom navigation handling

  const SearchPreviewCard({
    super.key,
    required this.entry,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use more compact layout based on isCompact flag
    return isCompact
        ? _buildCompactLayout(context, ref)
        : _buildStandardLayout(context, ref);
  }

  // More compact layout for the dropdown
  Widget _buildCompactLayout(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Icon based on entry type
    IconData typeIcon;
    Color iconColor = const Color(0xFF6E61FD);

    switch (entry.type) {
      case LogEntryType.audio:
        typeIcon = Icons.mic;
        break;
      case LogEntryType.image:
        typeIcon = Icons.image;
        break;
      case LogEntryType.video:
        typeIcon = Icons.videocam;
        break;
    }

    return InkWell(
      onTap: onTap ?? () => _navigateToAudio(ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Entry type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(typeIcon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),

            // Entry details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFormattedDate(entry.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // Original layout for full search results page
  Widget _buildStandardLayout(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Format the date
    final formattedDate = DateFormat('MMM d, yyyy').format(entry.timestamp);

    // Icon based on entry type
    IconData typeIcon;
    Color iconColor = const Color(0xFF6E61FD);

    switch (entry.type) {
      case LogEntryType.audio:
        typeIcon = Icons.mic;
        break;
      case LogEntryType.image:
        typeIcon = Icons.image;
        break;
      case LogEntryType.video:
        typeIcon = Icons.videocam;
        break;
    }

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap ?? () => _navigateToAudio(ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Entry type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Entry details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for more compact date display
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Navigate to audio detail page
  void _navigateToAudio(WidgetRef ref) {
    ref.read(routerProvider).go('/audio/${entry.id}');
  }
}
