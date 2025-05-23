import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
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
                            Image.asset(
                              'assets/icons/echo_logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
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
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6E61FD),
                          ),
                        ),
                        const SizedBox(height: 30),
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
          text: 'A place where your',
          weight: FontWeight.w600,
          size: 24,
        ),

        const SizedBox(height: 8),

        // Animated Typer effect
        SizedBox(
          width: double.maxFinite,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            child: AnimatedTextKit(
              isRepeatingAnimation: true,
              repeatForever: true,
              animatedTexts: [
                TyperAnimatedText(
                  'stories',
                  speed: const Duration(milliseconds: 150),
                  textAlign: TextAlign.center,
                ),
                TyperAnimatedText(
                  'thoughts',
                  speed: const Duration(milliseconds: 150),
                  textAlign: TextAlign.center,
                ),
                TyperAnimatedText(
                  'emotions',
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
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
