import 'package:echo/app/router.dart';
import 'package:echo/features/audio_detail/provider/audio_entry_provider.dart';
import 'package:echo/features/audio_detail/widgets/audio_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioDetailScreen extends ConsumerWidget {
  final String entryId;
  final String previousRoute;

  const AudioDetailScreen({
    super.key,
    required this.entryId,
    required this.previousRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(audioEntryProvider(entryId));

    return entryAsync.when(
      data: (entry) {
        if (entry == null) {
          // Entry not found
          return Scaffold(
            appBar: AppBar(
              title: const Text('Entry Not Found'),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Audio entry not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The entry you\'re looking for doesn\'t exist or has been deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.read(routerProvider).go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E61FD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go Back Home'),
                  ),
                ],
              ),
            ),
          );
        }

        // Entry found, display detail page
        return AudioDetailWidget(entry: entry, previousRoute: previousRoute);
      },
      loading:
          () => Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF6E61FD),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading audio entry...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      error:
          (error, stackTrace) => Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading audio entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An error occurred while loading the audio entry. Please try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        () => ref
                            .read(routerProvider)
                            .go('/'), // Navigate to home
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E61FD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go Back Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
