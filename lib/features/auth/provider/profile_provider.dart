import 'package:client/features/auth/provider/auth_provider.dart';
import 'package:client/shared/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
      return UserProfileNotifier(ref);
    });

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    ref.listen<AsyncValue<GoogleSignInAccount?>>(authStateProvider, (_, next) {
      next.when(
        data:
            (account) =>
                account != null
                    ? _handleUserLogin(account)
                    : state = const AsyncValue.data(null),
        error: (e, _) => state = AsyncValue.error(e, StackTrace.current),
        loading: () => state = const AsyncValue.loading(),
      );
    });
  }

  Future<void> _handleUserLogin(GoogleSignInAccount account) async {
    try {
      state = const AsyncValue.loading();
      final userProfileDoc =
          await _firestore.collection('profiles').doc(account.id).get();
      if (userProfileDoc.exists) {
        final userProfile = UserProfile.fromFirestore(userProfileDoc);
        state = AsyncValue.data(userProfile);
      } else {
        final newUserProfile = UserProfile.fromGoogle(account);
        await _firestore
            .collection('profiles')
            .doc(account.id)
            .set(newUserProfile.toFirestore());
        state = AsyncValue.data(newUserProfile);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      state = const AsyncValue.loading();
      await _firestore
          .collection('profiles')
          .doc(updatedProfile.uid)
          .update(updatedProfile.toFirestore());
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
