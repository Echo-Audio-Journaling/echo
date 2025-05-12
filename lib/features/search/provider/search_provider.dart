import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo/app/router.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for full search results
final searchResultsProvider =
    StateNotifierProvider<SearchResultsNotifier, AsyncValue<List<LogEntry>>>((
      ref,
    ) {
      final authState = ref.watch(authStateProvider);
      final searchQuery = ref.watch(searchQueryProvider);

      // Initialize the notifier with user ID and search query
      return SearchResultsNotifier(authState.valueOrNull?.id, searchQuery);
    });

// Provider for quick search preview results (limited to 5)
final quickSearchResultsProvider = Provider<AsyncValue<List<LogEntry>>>((ref) {
  final fullResults = ref.watch(searchResultsProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  // Only provide results if there's a query
  if (searchQuery.isEmpty) {
    return const AsyncValue.data([]);
  }

  return fullResults.whenData(
    (results) =>
        results.take(5).toList(), // Only take first 5 results for quick preview
  );
});

// Provider to check if there are more results than shown in the preview
final hasMoreResultsProvider = Provider<bool>((ref) {
  final fullResults = ref.watch(searchResultsProvider);
  return fullResults.valueOrNull != null &&
      (fullResults.valueOrNull?.length ?? 0) > 5;
});

// Helper provider to navigate to search results page
final searchNavigationProvider = Provider<void Function(String)>((ref) {
  return (String query) {
    if (query.trim().isNotEmpty) {
      // Update the search query first
      ref.read(searchQueryProvider.notifier).state = query.trim();

      // Then navigate to the search results page
      ref.read(routerProvider).go('/search');
    }
  };
});

class SearchResultsNotifier extends StateNotifier<AsyncValue<List<LogEntry>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId;
  final String _searchQuery;

  SearchResultsNotifier(this._userId, this._searchQuery)
    : super(const AsyncValue.loading()) {
    // Only perform search if there's a valid query
    if (_searchQuery.isNotEmpty && _searchQuery.length >= 2) {
      searchLogs();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> searchLogs() async {
    if (_userId == null) {
      state = const AsyncValue.error(
        'User not authenticated',
        StackTrace.empty,
      );
      return;
    }

    if (_searchQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Get all user logs
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('logs')
              .orderBy('timestamp', descending: true) // Get newest first
              .get();

      // Convert query results to LogEntry objects and filter by search term
      final searchTermLower = _searchQuery.toLowerCase();
      final logEntries =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id; // Add document ID to the data
                return LogEntry.fromJson(data);
              })
              .where((entry) {
                // Search in title
                if (entry.title.toLowerCase().contains(searchTermLower)) {
                  return true;
                }

                // Also search in audio transcription if it's an audio entry
                if (entry is AudioLogEntry) {
                  if (entry.transcription.toLowerCase().contains(
                    searchTermLower,
                  )) {
                    return true;
                  }

                  // Also search in tags for audio entries
                  return entry.tags.any(
                    (tag) => tag.toLowerCase().contains(searchTermLower),
                  );
                }

                // For image and video entries, search in description if available
                if (entry is ImageLogEntry && entry.description != null) {
                  return entry.description!.toLowerCase().contains(
                    searchTermLower,
                  );
                }

                if (entry is VideoLogEntry && entry.description != null) {
                  return entry.description!.toLowerCase().contains(
                    searchTermLower,
                  );
                }

                return false;
              })
              .toList();

      state = AsyncValue.data(logEntries);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Error searching logs: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
