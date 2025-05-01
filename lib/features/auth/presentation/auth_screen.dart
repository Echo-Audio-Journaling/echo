import 'package:animated_text_kit/animated_text_kit.dart';
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
      backgroundColor: const Color(0xFF6E61FD),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // Top Section (Logo + Slogan)
                  Expanded(
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
                            ),
                            const SizedBox(height: 50),
                            const HypnoticSlogan(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Section (Auth) - will stick to bottom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class HypnoticSlogan extends StatelessWidget {
  const HypnoticSlogan({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SloganLine(
          text: 'A place where',
          weight: FontWeight.w600,
          size: 24,
        ),

        const SizedBox(height: 8),

        // Animated Typer effect
        SizedBox(
          width: double.maxFinite,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            child: AnimatedTextKit(
              isRepeatingAnimation: true,
              animatedTexts: [
                TyperAnimatedText(
                  'your stories',
                  speed: const Duration(milliseconds: 150),
                  textAlign: TextAlign.center,
                ),
                TyperAnimatedText(
                  'your thoughts',
                  speed: const Duration(milliseconds: 150),
                  textAlign: TextAlign.center,
                ),
                TyperAnimatedText(
                  'your emotions',
                  speed: const Duration(milliseconds: 150),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        const _SloganLine(text: 'manifest', weight: FontWeight.w600, size: 24),
      ],
    );
  }
}

class _SloganLine extends StatelessWidget {
  final String text;
  final FontWeight weight;
  final double size;

  const _SloganLine({
    required this.text,
    required this.weight,
    required this.size,
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
          color: Colors.white,
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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
