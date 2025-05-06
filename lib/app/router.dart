import 'package:echo/features/audio_detail/presentation/audio_detail_screen.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/auth/presentation/auth_screen.dart';
import 'package:echo/features/detail/presentation/date_detail_screen.dart';
import 'package:echo/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:echo/features/auth/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final router = GoRouter(
    initialLocation: "/",
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/signin';

      if (!isLoggedIn && !isLoggingIn) {
        return '/signin';
      } else if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        name: "home",
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: "/signin",
        name: "signin",
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: "/profile",
        name: "profile",
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/date/:year/:month/:day',
        name: 'date_detail',
        builder: (context, state) {
          final year = int.parse(state.pathParameters['year'] ?? '2025');
          final month = int.parse(state.pathParameters['month'] ?? '1');
          final day = int.parse(state.pathParameters['day'] ?? '1');

          final date = DateTime(year, month, day);

          return DateDetailPage(date: date);
        },
      ),
      GoRoute(
        path: '/audio/:id',
        builder: (context, state) {
          final entryId = state.pathParameters['id'] ?? '';
          return AudioDetailScreen(entryId: entryId);
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFF6E61FD),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Page Not Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Route: ${state.uri.toString()}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
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
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );

  return router;
});
