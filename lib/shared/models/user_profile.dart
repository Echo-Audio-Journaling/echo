import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final int level;
  final String? about;
  final bool isNewUser;
  final DateTime? lastUpdatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.level = 1,
    this.about,
    this.isNewUser = false,
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'level': level,
      'about': about,
      'isNewUser': isNewUser,
      'lastUpdated': DateTime.now(),
    };
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String,
      username: data['username'] as String,
      photoUrl: data['photoUrl'] as String?,
      level: data['level'] as int? ?? 1,
      about: data['about'] as String?,
      isNewUser: data['isNewUser'] as bool? ?? false,
      lastUpdatedAt: data['lastUpdated']?.toDate(),
    );
  }

  // Create from Google Account
  factory UserProfile.fromGoogle(GoogleSignInAccount account) {
    return UserProfile(
      uid: account.id,
      email: account.email,
      username: account.displayName ?? 'User${account.id.substring(0, 6)}',
      photoUrl: account.photoUrl,
      level: 1,
      about: 'About yourself...',
      isNewUser: true,
      lastUpdatedAt: DateTime.now(),
    );
  }
}
