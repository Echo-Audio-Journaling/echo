import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/auth/presentation/auth_screen.dart';
import 'package:echo/features/detail/presentation/date_detail_screen.dart';
import 'package:echo/features/home/presentation/home_screen.dart';
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
        path: "/detail",
        name: "detail",
        builder: (context, state) => DateDetailScreen(date: DateTime.now()),
      ),
    ],
  );

  return router;
});
