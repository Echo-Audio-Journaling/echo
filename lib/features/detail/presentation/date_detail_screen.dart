import 'package:flutter/material.dart';

class DateDetailScreen extends StatelessWidget {
  final DateTime date;

  const DateDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${date.day}/${date.month}/${date.year}"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          
            _TextNoteCard(
              title: "Ideas on quantum",
              dateText: "Friday 25, Jan, 2025 7:00 AM",
              content:
                  "if quantum particles are tiny and can’t be perceived to us with our naked eye, what’s the word for big …….",
            ),

            const SizedBox(height: 16),

            _ImageNoteCard(
              imageUrl:
                  "https://images.unsplash.com/photo-1507525428034-b723cf961d3e", 
              dateText: "Friday 25, Jan, 2025 9:00 AM",
              description:
                  "Did a hike with Thomas and shot this sunset picture :)",
            ),
          ],
        ),
      ),
    );
  }
}

class _TextNoteCard extends StatelessWidget {
  final String title;
  final String dateText;
  final String content;

  const _TextNoteCard({
    required this.title,
    required this.dateText,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(dateText,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Text(content,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ImageNoteCard extends StatelessWidget {
  final String imageUrl;
  final String dateText;
  final String description;

  const _ImageNoteCard({
    required this.imageUrl,
    required this.dateText,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}