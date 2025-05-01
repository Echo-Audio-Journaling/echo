import 'dart:async';

import 'package:client/features/auth/data/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SignInWidget();
  }
}

class SignInWidget extends ConsumerWidget {
  const SignInWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Color(0xFF6E61FD),
      body: Column(
        children: [
          // Top Section (Logo + Slogan)
          Expanded(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 60,
                      color: Colors.white,
                    ), // Primary purple
                    const SizedBox(height: 50),
                    HypnoticSlogan(), // Minimal animation
                  ],
                ),
              ),
            ),
          ),

          // Bottom Section (Auth)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 50),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Echo: Audio Journal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,

                    color: Color(0xFF6E61FD),
                  ),
                ),
                const SizedBox(height: 50),
                _GoogleSignInButton(ref: ref),
                const SizedBox(height: 30),
                const Text(
                  'By continuing, you agree to our Terms & Conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HypnoticSlogan extends StatefulWidget {
  const HypnoticSlogan({super.key});

  @override
  State<HypnoticSlogan> createState() => _HypnoticSloganState();
}

class _HypnoticSloganState extends State<HypnoticSlogan> {
  final List<String> _coreWords = ['stories', 'thoughts', 'emotions'];
  int _currentIndex = 0;
  late Timer _cycleTimer;

  @override
  void initState() {
    super.initState();
    _startWordCycle();
  }

  void _startWordCycle() {
    _cycleTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() => _currentIndex = (_currentIndex + 1) % _coreWords.length);
    });
  }

  @override
  void dispose() {
    _cycleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1 - Invitation (Fixed)
        const _SloganLine(
          text: 'A place where',
          weight: FontWeight.w600,
          size: 24,
        ),

        // Line 2 - Core Words (Cycling)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOutSine,
          child: _SloganLine(
            key: ValueKey(_currentIndex),
            text: 'your ${_coreWords[_currentIndex]}',
            weight: FontWeight.w600,
            size: 40,
            color: Colors.white,
          ),
        ),

        // Line 3 - Action (Fixed)
        const _SloganLine(text: 'manifest', weight: FontWeight.w600, size: 24),
      ],
    );
  }
}

class _SloganLine extends StatelessWidget {
  final String text;
  final FontWeight weight;
  final double size;
  final Color? color;

  const _SloganLine({
    super.key,
    required this.text,
    required this.weight,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: weight,
          fontSize: size,
          color: color ?? Colors.white,
          height: 1.3,
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final WidgetRef ref;

  const _GoogleSignInButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => ref.read(authStateProvider.notifier).signIn(),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.black26),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/google_icon.png',
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          const Text(
            'Continue with Google',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
