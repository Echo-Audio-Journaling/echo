import 'package:echo/features/home/data/generate_prompts.dart';
import 'package:flutter/material.dart';

class RandomPrompts extends StatelessWidget {
  final Map<String, String> prompts = getPromptsFromRandomCategories();

  RandomPrompts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Prompts',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  prompts.entries.map((entry) {
                    return _buildPromptCard(
                      context,
                      category: entry.key,
                      prompt: entry.value,
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(
    BuildContext context, {
    required String category,
    required String prompt,
  }) {
    final theme = Theme.of(context);
    final categoryColors = _getCategoryColor(category);

    return Container(
      width: 230,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColors.background.withOpacity(0.8),
            categoryColors.background.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: categoryColors.primary, width: 1.5),
            ),
            child: Text(
              category.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: categoryColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Prompt Text
          Text(
            prompt,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Mic Icon for Voice Recording
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                Icons.mic_none_rounded,
                color: categoryColors.primary,
                size: 28,
              ),
              onPressed: () {
                // Handle voice recording start
              },
            ),
          ),
        ],
      ),
    );
  }

  CategoryColors _getCategoryColor(String category) {
    final colors = {
      'Self-Reflection': CategoryColors(
        primary: Colors.purple,
        background: Colors.purple.shade100,
      ),
      'Gratitude': CategoryColors(
        primary: Colors.orange,
        background: Colors.orange.shade100,
      ),
      'Challenges': CategoryColors(
        primary: Colors.red,
        background: Colors.red.shade100,
      ),
      'Creativity': CategoryColors(
        primary: Colors.blue,
        background: Colors.blue.shade100,
      ),
      'Relationships': CategoryColors(
        primary: Colors.pink,
        background: Colors.pink.shade100,
      ),
      'Future': CategoryColors(
        primary: Colors.green,
        background: Colors.green.shade100,
      ),
      'Mindfulness': CategoryColors(
        primary: Colors.teal,
        background: Colors.teal.shade100,
      ),
    };

    return colors[category] ??
        CategoryColors(
          primary: Colors.indigo,
          background: Colors.indigo.shade100,
        );
  }
}

class CategoryColors {
  final Color primary;
  final Color background;

  CategoryColors({required this.primary, required this.background});
}
