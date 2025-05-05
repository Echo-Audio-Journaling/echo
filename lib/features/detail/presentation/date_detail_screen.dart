import 'package:echo/app/router.dart';
import 'package:echo/features/detail/provider/log_entries_provider.dart';
import 'package:echo/features/detail/widgets/audio_log_item.dart';
import 'package:echo/features/detail/widgets/image_log_item.dart';
import 'package:echo/features/detail/widgets/video_log_item.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:echo/shared/widgets/create_content_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DateDetailPage extends ConsumerStatefulWidget {
  final DateTime date;

  const DateDetailPage({super.key, required this.date});

  @override
  ConsumerState<DateDetailPage> createState() => _DateDetailPageState();
}

class _DateDetailPageState extends ConsumerState<DateDetailPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Fetch log entries for the selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logEntriesProvider.notifier).fetchLogEntriesForDate(widget.date);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logEntriesState = ref.watch(logEntriesProvider);
    final isRecording = ref.watch(isRecordingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E61FD),
        elevation: 0,
        title: Text(
          DateFormat('MMMM d, yyyy').format(widget.date),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => ref.read(routerProvider).go('/'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: logEntriesState.when(
                data: (logEntries) {
                  if (logEntries.isEmpty && !isRecording) {
                    return _buildEmptyState();
                  }
                  return _buildLogEntryList(logEntries);
                },
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),

            // Action bar for creating content
            CreateContentActionBar(selectedDate: widget.date),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No entries for this day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the buttons below to add audio, images, or videos',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Icon(Icons.arrow_downward, size: 32, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E61FD)),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(logEntriesProvider);
                ref
                    .read(logEntriesProvider.notifier)
                    .fetchLogEntriesForDate(widget.date);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E61FD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntryList(List<LogEntry> logEntries) {
    // Sort entries by timestamp, newest first
    logEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: logEntries.length,
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        itemBuilder: (context, index) {
          final entry = logEntries[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLogEntryItem(entry),
          );
        },
      ),
    );
  }

  Widget _buildLogEntryItem(LogEntry entry) {
    switch (entry.type) {
      case LogEntryType.audio:
        return AudioLogItem(entry: entry as AudioLogEntry);
      case LogEntryType.image:
        return ImageLogItem(entry: entry as ImageLogEntry);
      case LogEntryType.video:
        return VideoLogItem(entry: entry as VideoLogEntry);
    }
  }
}
