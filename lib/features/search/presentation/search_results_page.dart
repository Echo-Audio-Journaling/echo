import 'package:echo/app/router.dart';
import 'package:echo/features/search/provider/search_provider.dart';
import 'package:echo/features/search/widgets/search_preview_card.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({super.key});

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(searchQueryProvider);
    _searchController.text = currentQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsState = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E61FD),
        elevation: 0,
        title: Text(
          'Search Results',
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
            // Search input field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: searchQuery.isEmpty, // Auto focus if no query
                decoration: InputDecoration(
                  hintText: 'Search memories...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF6E61FD),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: const Color(0xFF6E61FD)),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: (value) {
                  // Use the searchNavigationProvider to set query and stay on results page
                  if (value.trim().isNotEmpty) {
                    ref.read(searchQueryProvider.notifier).state = value.trim();
                  }
                },
                onChanged: (value) {
                  // Update search query on each keystroke for real-time results
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),

            // Search info
            if (searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'Showing results for: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Expanded(
                      child: Text(
                        '"$searchQuery"',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6E61FD),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Results list
            Expanded(
              child: searchResultsState.when(
                data: (results) {
                  if (searchQuery.isEmpty) {
                    return _buildEmptyQuery();
                  }

                  if (results.isEmpty) {
                    return _buildNoResults();
                  }

                  return _buildSearchResults(results);
                },
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuery() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start typing to search your memories',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
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
                final currentQuery = ref.read(searchQueryProvider);
                // Re-trigger search
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(searchQueryProvider.notifier).state = currentQuery;
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

  Widget _buildSearchResults(List<LogEntry> results) {
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.only(top: 0, bottom: 24, left: 16, right: 16),
      itemBuilder: (context, index) {
        final entry = results[index];
        final id = entry.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SearchPreviewCard(
            entry: entry,
            isCompact: false, // Use full-size cards in the results page
            onTap: () {
              // Navigate to audio detail page
              ref.read(routerProvider).go('/audio/$id', extra: 'search');
            },
          ),
        );
      },
    );
  }
}
