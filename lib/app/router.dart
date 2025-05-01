import 'dart:developer';

import 'package:client/features/auth/data/auth_providers.dart';
import 'package:client/features/auth/presentation/auth_screen.dart';
import 'package:client/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final router = GoRouter(
    initialLocation: "/",
    redirect: (context, state) {
      log('$authState');
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
    ],
  );

  return router;
});
