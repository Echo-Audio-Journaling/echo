import 'package:echo/app/router.dart';
import 'package:echo/features/search/provider/search_provider.dart';
import 'package:echo/features/search/widgets/search_preview_card.dart';
// import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchDropdown extends ConsumerWidget {
  final LayerLink layerLink;
  final FocusNode searchFocusNode;
  final TextEditingController searchController;

  const SearchDropdown({
    super.key,
    required this.layerLink,
    required this.searchFocusNode,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickResults = ref.watch(quickSearchResultsProvider);
    final hasMoreResults = ref.watch(hasMoreResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Only show dropdown when:
    // 1. There's a non-empty search query
    // 2. The search field has focus
    // 3. The controller's text matches the query (prevents stale results)
    if (searchQuery.isEmpty ||
        !searchFocusNode.hasFocus ||
        searchController.text != searchQuery) {
      return const SizedBox.shrink();
    }

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      offset: const Offset(-25, 60), // Position below search bar
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 24,
          ), // Match horizontal padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: 250, // Max height for scrollable area
            maxWidth:
                MediaQuery.of(
                  context,
                ).size.width, // Max width accounting for padding
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: quickResults.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildNoResultsMessage();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small header with result count
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Results',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${entries.length} found${hasMoreResults ? '+' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF6E61FD),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Divider(height: 1, color: Colors.grey[200]),

                    // Results list (scrollable)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: entries.length + (hasMoreResults ? 1 : 0),
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                              indent: 16,
                              endIndent: 16,
                            ),
                        itemBuilder: (context, index) {
                          // If we're at the last position and have more results, show the "View all" button
                          if (hasMoreResults && index == entries.length) {
                            return _buildViewAllButton(ref);
                          }
                          final id = entries[index].id;

                          // Use the SearchPreviewCard with compact mode enabled
                          return SearchPreviewCard(
                            entry: entries[index],
                            isCompact: true, // Use compact mode for dropdown
                            onTap: () {
                              // Clear search query when navigating
                              ref.read(searchQueryProvider.notifier).state = '';
                              searchController.clear();

                              // Navigate to audio detail and clear search focus
                              ref.read(routerProvider).go('/audio/$id');
                              searchFocusNode.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => _buildLoadingIndicator(),
              error: (error, _) => _buildErrorMessage(error.toString()),
            ),
          ),
        ),
      ),
    );
  }

  // "View all results" button at the bottom
  Widget _buildViewAllButton(WidgetRef ref) {
    return InkWell(
      onTap: () {
        // Navigate to full search results page using the current search query
        ref.read(searchNavigationProvider)(searchController.text);

        // Unfocus the search field after navigation
        searchFocusNode.unfocus();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.grey[50],
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View all results',
                style: const TextStyle(
                  color: Color(0xFF6E61FD),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                size: 12,
                color: Color(0xFF6E61FD),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 32, // Smaller icon
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8), // Less space
          Text(
            'No matching entries found',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 14, // Smaller text
            ),
          ),
          const SizedBox(height: 4), // Less space
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 12, // Smaller text
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      height: 100, // Smaller loading container
      child: const Center(
        child: SizedBox(
          width: 24, // Smaller loading indicator
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E61FD)),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      height: 120, // Smaller error container
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 32, // Smaller icon
            color: Colors.red[300],
          ),
          const SizedBox(height: 8), // Less space
          Text(
            'Something went wrong',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14, // Smaller text
            ),
          ),
          const SizedBox(height: 4), // Less space
          Text(
            error,
            style: TextStyle(
              fontSize: 12, // Smaller text
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Limit lines
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
