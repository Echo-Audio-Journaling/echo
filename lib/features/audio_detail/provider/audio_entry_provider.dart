import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioEntryProvider = FutureProvider.family<AudioLogEntry?, String>((
  ref,
  entryId,
) async {
  final userProvider = ref.watch(authStateProvider);
  final userId = userProvider.asData?.value?.id;

  if (userId == null || entryId.isEmpty) {
    return null;
  }

  try {
    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('logs')
            .doc(entryId)
            .get();

    if (!docSnapshot.exists) {
      return null;
    }

    final data = docSnapshot.data();
    if (data == null) {
      return null;
    }

    // Check if this is an audio entry
    final type = LogEntryType.values.firstWhere(
      (e) => e.toString() == 'LogEntryType.${data['type']}',
      orElse: () => LogEntryType.audio,
    );

    if (type != LogEntryType.audio) {
      return null;
    }

    return AudioLogEntry.fromJson({...data, 'id': entryId});
  } catch (e) {
    debugPrint('Error fetching audio entry: $e');
    return null;
  }
});
