import 'package:client/app/router.dart';
import 'package:client/features/auth/data/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: authState.when(
        data:
            (user) =>
                user != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Logged in as:'),
                          Text(user.displayName ?? 'No name'),
                          Text(user.email),
                          Text(user.id),
                          // New Profile Button
                          _ProfileButton(),
                        ],
                      ),
                    )
                    : const Center(child: Text('Not logged in')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// Add this new widget class
class _ProfileButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(routerProvider).go('/profile'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6E61FD), // Your brand color
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'View Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
