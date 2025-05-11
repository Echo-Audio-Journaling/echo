import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recent_entry_card.dart';

class RecentEntriesSection extends ConsumerWidget {
  final String title;
  final Color accentColor;

  const RecentEntriesSection({
    super.key,
    this.title = "Recent Entries",
    this.accentColor = const Color(0xFF6E61FD),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get the current user from your auth provider
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // If user is not logged in, show login message
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Please sign in to view your entries',
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }

        // Use the user's ID from Google Sign-In
        final userId = user.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Section Title
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Use StreamBuilder for real-time updates
            StreamBuilder<QuerySnapshot>(
              // Just use a simple query without complex filters
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('logs')
                  // We can sort by timestamp safely
                  .orderBy('timestamp', descending: true)
                  .limit(20)  // Fetch more than needed for filtering
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading entries: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filter for audio files client-side
                final audioDocs = allDocs.where((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final fileType = data['fileType'] ?? data['type'] ?? '';
                    final fileName = (data['fileName'] ?? '').toString().toLowerCase();
                    final mimeType = (data['mimeType'] ?? '').toString().toLowerCase();
                    
                    return fileType == 'audio' ||
                           fileName.contains('.mp3') ||
                           fileName.contains('.wav') ||
                           fileName.contains('.m4a') ||
                           mimeType.contains('audio');
                  } catch (e) {
                    return false;
                  }
                }).toList();
                
                // Limit to 5 audio entries
                final docs = audioDocs.length > 5 ? audioDocs.sublist(0, 5) : audioDocs;

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.audio_file,
                            size: 48,
                            color:
                                isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent audio entries yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your recent audio recordings will appear here',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];

                    try {
                      // Extract data from document
                      final data = doc.data() as Map<String, dynamic>;

                      // Extract title with fallbacks
                      final title =
                          data['title'] ??
                          data['fileName'] ??
                          data['content'] ??
                          'Audio Recording';

                      // Extract timestamp with fallbacks
                      DateTime dateTime;
                      try {
                        if (data['timestamp'] is Timestamp) {
                          dateTime = (data['timestamp'] as Timestamp).toDate();
                        } else if (data['date'] is Timestamp) {
                          dateTime = (data['date'] as Timestamp).toDate();
                        } else if (data['created_at'] is Timestamp) {
                          dateTime = (data['created_at'] as Timestamp).toDate();
                        } else {
                          // Default to now if no valid timestamp
                          dateTime = DateTime.now();
                        }
                      } catch (_) {
                        dateTime = DateTime.now();
                      }

                      // Create EntryData object for formatting
                      final entryData = EntryData(
                        id: doc.id,
                        title: title.toString(),
                        dateTime: dateTime,
                        category: 'audio',
                      );

                      // Pass ID directly to the card instead of using onTap callback
                      return RecentEntryCard(
                        title: entryData.title,
                        date: entryData.formattedDate,
                        time: entryData.formattedTime,
                        entryId: doc.id, // Pass document ID to the card
                        accentColor: const Color(0xFFF48F5B),
                      );
                    } catch (e) {
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text(
              'Error loading user: $error',
              style: TextStyle(color: Colors.red),
            ),
          ),
    );
  }
}

// Keep the EntryData model class the same
class EntryData {
  final String id;
  final String title;
  final DateTime dateTime;
  final String category;
  final VoidCallback? onTap;

  const EntryData({
    required this.id,
    required this.title,
    required this.dateTime,
    this.category = '',
    this.onTap,
  });

  // Format date based on how recent it is
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return _getWeekday(dateTime.weekday);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Format time
  String get formattedTime {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final hourIn12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hourIn12:${minute.toString().padLeft(2, '0')} $period';
  }

  // Helper function to get weekday name
  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}