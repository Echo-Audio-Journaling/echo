// auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GoogleSignInAccount?>>((
      ref,
    ) {
      return AuthNotifier();
    });

class AuthNotifier extends StateNotifier<AsyncValue<GoogleSignInAccount?>> {
  AuthNotifier() : super(const AsyncValue.data(null)) {
    _initialize();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _initialize() async {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      state = AsyncValue.data(account);
    });

    await _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      state = const AsyncValue.loading();
      await _googleSignIn.signIn();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _googleSignIn.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
