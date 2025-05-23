import 'package:echo/app/router.dart';
import 'package:echo/features/auth/provider/profile_provider.dart';
import 'package:echo/features/home/widgets/journal_calendar.dart';
import 'package:echo/features/home/widgets/random_prompts.dart';
import 'package:echo/features/home/widgets/recent_entries_section.dart';
import 'package:echo/features/media_upload/widgets/create_content_action_bar.dart';
import 'package:echo/features/search/provider/search_provider.dart';
import 'package:echo/features/search/widgets/search_dropdown.dart';
import 'package:echo/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Search related controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();

    // Listen for focus changes to show/hide dropdown
    _searchFocusNode.addListener(_onSearchFocusChange);

    // Clear search query when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Handle focus changes
  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      // If focus is lost and search query is empty, make sure state is also empty
      if (_searchController.text.isEmpty) {
        ref.read(searchQueryProvider.notifier).state = '';
      }
    }
    setState(() {}); // Refresh UI to show/hide dropdown
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDate = DateFormat('EEEE, d MMM').format(DateTime.now());

    // Watch the user profile provider to get real user data
    final userProfileState = ref.watch(userProfileProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF6E61FD),
        // Use a Stack to position the content and the action bar
        body: GestureDetector(
          // Close search dropdown when tapping elsewhere
          onTap: () {
            if (_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // First Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        // App Logo and Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/echo_logo.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Echo',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Bar (Using CompositedTransformTarget to anchor the dropdown)
                        CompositedTransformTarget(
                          link: _layerLink,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search memories...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                ),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref
                                                .read(
                                                  searchQueryProvider.notifier,
                                                )
                                                .state = '';
                                          },
                                        )
                                        : null,
                              ),
                              onChanged: (value) {
                                // Update search query on each keystroke
                                ref.read(searchQueryProvider.notifier).state =
                                    value;
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
                        const SizedBox(height: 16),

                        // Greeting and Profile
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentDate,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Good Day!',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 4),

                                  // User name with loading state
                                  userProfileState.when(
                                    data:
                                        (user) => Text(
                                          user?.username ?? 'Guest',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                    loading: () => _buildLoadingText(context),
                                    error:
                                        (_, __) => Text(
                                          'User',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // User profile image with loading state
                                  userProfileState.when(
                                    data:
                                        (user) => _buildProfileImage(
                                          context,
                                          user,
                                          ref,
                                        ),
                                    loading: () => _buildLoadingProfileImage(),
                                    error:
                                        (_, __) =>
                                            _buildDefaultProfileImage(ref),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Second Section
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          // Add bottom padding to accommodate the action bar
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom:
                                130, // Added extra padding at the bottom for the action bar
                          ),
                          child: Column(
                            children: [
                              RandomPrompts(),
                              SizedBox(height: 24),
                              JournalCalendar(),
                              SizedBox(height: 24),
                              RecentEntriesSection(
                                title: 'Recent Entries',
                                accentColor: const Color(0xFF6E61FD),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Create Content Action Bar positioned at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CreateContentActionBar(
                  selectedDate: DateTime.now(), // Use today's date
                ),
              ),

              // Search dropdown (using Overlay via CompositedTransformFollower)
              if (_searchFocusNode.hasFocus ||
                  _searchController.text.isNotEmpty)
                Positioned(
                  // This positioned widget ensures the dropdown doesn't affect layout
                  top: 0, // Position from top
                  left: 0,
                  right: 0,
                  child: SearchDropdown(
                    layerLink: _layerLink,
                    searchFocusNode: _searchFocusNode,
                    searchController: _searchController,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading animation for username text
  Widget _buildLoadingText(BuildContext context) {
    return Container(
      width: 120,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
      ),
    );
  }

  // Profile image when data is available
  Widget _buildProfileImage(
    BuildContext context,
    UserProfile? user,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () => ref.read(routerProvider).go('/profile'),
          child: ClipOval(
            child:
                user?.photoUrl != null
                    ? Image.network(
                      user!.photoUrl!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildDefaultProfileImageContent(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6E61FD),
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    )
                    : _buildDefaultProfileImageContent(),
          ),
        ),
      ),
    );
  }

  // Loading state for profile image
  Widget _buildLoadingProfileImage() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        color: Colors.white.withOpacity(0.2),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // Default profile image in case of error or no image
  Widget _buildDefaultProfileImage(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: GestureDetector(
        onTap: () => ref.read(routerProvider).go('/profile'),
        child: ClipOval(child: _buildDefaultProfileImageContent()),
      ),
    );
  }

  // Default profile image content
  Widget _buildDefaultProfileImageContent() {
    return Image.asset(
      'assets/profile/default_profile.png',
      height: 80,
      width: 80,
      fit: BoxFit.cover,
    );
  }
}
