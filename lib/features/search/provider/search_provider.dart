import 'package:cloud_firestore/cloud_firestore.dart';
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

      // Convert query results to LogEntry objects and filter by title
      final searchTermLower = _searchQuery.toLowerCase();
      final logEntries =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id; // Add document ID to the data
                return LogEntry.fromJson(data);
              })
              .where(
                (entry) => entry.title.toLowerCase().contains(searchTermLower),
              )
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
