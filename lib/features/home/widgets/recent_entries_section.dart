import 'package:flutter/material.dart';

import 'recent_entry_card.dart';

class RecentEntriesSection extends StatelessWidget {
  final List<EntryData> entries = [
    EntryData(
      id: '1',
      title: 'Morning reflection: Starting the day with gratitude',
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      category: 'personal',
      onTap: () {},
    ),
    EntryData(
      id: '2',
      title: 'Project meeting notes: New feature planning',
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      category: 'work',
      onTap: () {},
    ),
    EntryData(
      id: '3',
      title: 'Workout log: 5k run and strength training',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      category: 'health',
      onTap: () {},
    ),
    EntryData(
      id: '4',
      title: 'App design ideas for the journal feature',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      category: 'ideas',
      onTap: () {},
    ),
    EntryData(
      id: '5',
      title: 'Monthly goals: Focus areas for May',
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      category: 'goals',
      onTap: () {},
    ),
    // Additional entries (will show "more entries" indicator)
    EntryData(
      id: '6',
      title: 'Book notes: "Atomic Habits" chapter 4',
      dateTime: DateTime.now().subtract(const Duration(days: 4)),
      category: 'personal',
      onTap: () {},
    ),
    EntryData(
      id: '7',
      title: 'Weekly review: What went well and lessons learned',
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      category: 'personal',
      onTap: () {},
    ),
  ];
  final String title;
  final Color accentColor;

  RecentEntriesSection({
    super.key,
    this.title = "Recent Entries",
    this.accentColor = const Color(0xFF6E61FD),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Title and View All button
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

        // Empty state if no entries
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 48,
                    color:
                        isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent entries yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your recent journal entries will appear here',
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
          ),

        // List of Entry Cards (limited to 5)
        if (entries.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length > 5 ? 5 : entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];

              return RecentEntryCard(
                title: entry.title,
                date: entry.formattedDate,
                time: entry.formattedTime,
                accentColor: const Color(0xFFF48F5B),
                onTap: entry.onTap,
              );
            },
          ),
      ],
    );
  }
}

// Model class for entry data
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

// Example usage:
/*
// Sample data for demonstration
final List<EntryData> sampleEntries = [
  EntryData(
    id: '1',
    title: 'Morning reflection: Starting the day with gratitude',
    dateTime: DateTime.now().subtract(const Duration(hours: 3)),
    category: 'personal',
    onTap: () {
      // Handle entry tap
      print('Tapped on entry 1');
    },
  ),
  EntryData(
    id: '2',
    title: 'Project meeting notes: New feature planning',
    dateTime: DateTime.now().subtract(const Duration(hours: 6)),
    category: 'work',
    onTap: () {
      // Handle entry tap
      print('Tapped on entry 2');
    },
  ),
  EntryData(
    id: '3',
    title: 'Workout log: 5k run and strength training',
    dateTime: DateTime.now().subtract(const Duration(days: 1)),
    category: 'health',
    onTap: () {
      // Handle entry tap
      print('Tapped on entry 3');
    },
  ),
  EntryData(
    id: '4',
    title: 'App design ideas for the journal feature',
    dateTime: DateTime.now().subtract(const Duration(days: 2)),
    category: 'ideas',
    onTap: () {
      // Handle entry tap
      print('Tapped on entry 4');
    },
  ),
  EntryData(
    id: '5',
    title: 'Monthly goals: Focus areas for May',
    dateTime: DateTime.now().subtract(const Duration(days: 3)),
    category: 'goals',
    onTap: () {
      // Handle entry tap
      print('Tapped on entry 5');
    },
  ),
  // Additional entries (will show "more entries" indicator)
  EntryData(
    id: '6',
    title: 'Book notes: "Atomic Habits" chapter 4',
    dateTime: DateTime.now().subtract(const Duration(days: 4)),
    category: 'personal',
    onTap: () {},
  ),
  EntryData(
    id: '7',
    title: 'Weekly review: What went well and lessons learned',
    dateTime: DateTime.now().subtract(const Duration(days: 5)),
    category: 'personal',
    onTap: () {},
  ),
];

// Using the RecentEntriesSection in a widget
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My Journal')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RecentEntriesSection(
          title: 'Recent Journal Entries',
          entries: sampleEntries,
          accentColor: const Color(0xFF6E61FD),
          onViewAllPressed: () {
            // Navigate to all entries screen
            print('View all entries pressed');
          },
        ),
      ),
    ),
  );
}
*/
