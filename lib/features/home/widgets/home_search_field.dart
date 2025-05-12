import 'package:echo/features/search/provider/search_provider.dart';
import 'package:echo/features/search/widgets/search_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable search field widget for the home screen that properly handles
/// the dropdown overlay without affecting the layout of other widgets
class HomeSearchField extends ConsumerStatefulWidget {
  const HomeSearchField({super.key});

  @override
  ConsumerState<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends ConsumerState<HomeSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    // Listen for focus changes to show/hide dropdown
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Force a rebuild when focus changes
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Search field with CompositedTransformTarget
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search memories...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                // Update search query on each keystroke
                ref.read(searchQueryProvider.notifier).state = value;
              },
              onSubmitted: (value) {
                // Navigate to search results page when Enter is pressed
                if (value.trim().isNotEmpty) {
                  ref.read(searchNavigationProvider)(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
