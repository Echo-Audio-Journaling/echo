import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:echo/shared/models/log_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

// Define the provider for log entries
final logEntriesProvider =
    StateNotifierProvider<LogEntriesNotifier, AsyncValue<List<LogEntry>>>((
      ref,
    ) {
      final authState = ref.watch(authStateProvider);
      final storageService = ref.read(storageServiceProvider);
      return LogEntriesNotifier(storageService, authState.valueOrNull?.id);
    });

class LogEntriesNotifier extends StateNotifier<AsyncValue<List<LogEntry>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService;
  final String? _userId;

  // Cache the currently loaded date range to avoid redundant fetches
  DateTime? _currentRangeStart;
  DateTime? _currentRangeEnd;

  LogEntriesNotifier(this._storageService, this._userId)
    : super(const AsyncValue.loading()) {
    // Initial fetch can be done here if needed
  }

  // Fetch log entries for a specific date
  Future<void> fetchLogEntriesForDate(DateTime date) async {
    if (_userId == null) {
      state = const AsyncValue.error(
        'User not authenticated',
        StackTrace.empty,
      );
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Create date range for the entire day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      // Query Firestore for log entries
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('logs')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .orderBy('timestamp', descending: false)
              .get();

      // Convert query results to LogEntry objects
      final logEntries =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to the data
            return LogEntry.fromJson(data);
          }).toList();

      state = AsyncValue.data(logEntries);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Error fetching log entries: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // New method: Fetch log entries for a specific month/date range
  Future<void> fetchEntriesForMonth(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userId == null) {
      state = const AsyncValue.error(
        'User not authenticated',
        StackTrace.empty,
      );
      return;
    }

    // Check if the requested range is already loaded
    if (_currentRangeStart != null &&
        _currentRangeEnd != null &&
        _isSameDay(startDate, _currentRangeStart!) &&
        _isSameDay(endDate, _currentRangeEnd!)) {
      // Range already loaded, no need to fetch again
      return;
    }

    try {
      // Set loading state only if we don't have data yet
      if (!state.hasValue) {
        state = const AsyncValue.loading();
      }

      // Query Firestore for log entries in the date range
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('logs')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('timestamp', descending: false)
              .get();

      // Convert query results to LogEntry objects
      final logEntries =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to the data
            return LogEntry.fromJson(data);
          }).toList();

      // Update the cache
      _currentRangeStart = startDate;
      _currentRangeEnd = endDate;

      state = AsyncValue.data(logEntries);

      if (kDebugMode) {
        developer.log(
          'Fetched ${logEntries.length} entries for month: ${startDate.month}/${startDate.year}',
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Error fetching log entries for month: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Helper to check if two dates are the same day (ignoring time)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Add a new audio log entry
  Future<String?> addAudioLogEntry({
    required String audioUrl,
    required String transcription,
    required Duration duration,
    String? title,
    DateTime? timestamp,
    List<String> tags = const [],
  }) async {
    if (_userId == null) return null;

    try {
      // Generate a default title if none is provided
      final entryTitle =
          title ?? _generateTitleFromTranscription(transcription);
      final entryTimestamp = timestamp ?? DateTime.now();
      final entryId = const Uuid().v4(); // Generate a unique ID

      // Create the audio log entry
      final audioEntry = AudioLogEntry(
        id: entryId,
        timestamp: entryTimestamp,
        title: entryTitle,
        audioUrl: audioUrl,
        transcription: transcription,
        duration: duration,
        isPlaying: false,
        tags: tags, // Pass tags to the constructor
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(entryId)
          .set(audioEntry.toJson());

      // Update local state
      state = state.whenData((entries) {
        return [...entries, audioEntry]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      return entryId;
    } catch (error) {
      if (kDebugMode) {
        print('Error adding audio log entry: $error');
      }
      return null;
    }
  }

  // Add a new image log entry
  Future<String?> addImageLogEntry({
    required String imageUrl,
    String? title,
    String? description,
    DateTime? timestamp,
  }) async {
    if (_userId == null) return null;

    try {
      // Generate a default title if none is provided
      final entryTitle = title ?? 'Image ${DateTime.now().toIso8601String()}';
      final entryTimestamp = timestamp ?? DateTime.now();
      final entryId = const Uuid().v4(); // Generate a unique ID

      // Create the image log entry
      final imageEntry = ImageLogEntry(
        id: entryId,
        timestamp: entryTimestamp,
        title: entryTitle,
        imageUrl: imageUrl,
        description: description,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(entryId)
          .set(imageEntry.toJson());

      // Update local state
      state = state.whenData((entries) {
        return [...entries, imageEntry]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      return entryId;
    } catch (error) {
      if (kDebugMode) {
        print('Error adding image log entry: $error');
      }
      return null;
    }
  }

  // Add a new video log entry
  Future<String?> addVideoLogEntry({
    required String videoUrl,
    required Duration duration,
    String? title,
    String? description,
    String? thumbnailUrl,
    DateTime? timestamp,
  }) async {
    if (_userId == null) return null;

    try {
      // Generate a default title if none is provided
      final entryTitle = title ?? 'Video ${DateTime.now().toIso8601String()}';
      final entryTimestamp = timestamp ?? DateTime.now();
      final entryId = const Uuid().v4(); // Generate a unique ID

      // Create the video log entry
      final videoEntry = VideoLogEntry(
        id: entryId,
        timestamp: entryTimestamp,
        title: entryTitle,
        videoUrl: videoUrl,
        duration: duration,
        description: description,
        thumbnailUrl: thumbnailUrl,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(entryId)
          .set(videoEntry.toJson());

      // Update local state
      state = state.whenData((entries) {
        return [...entries, videoEntry]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      return entryId;
    } catch (error) {
      if (kDebugMode) {
        print('Error adding video log entry: $error');
      }
      return null;
    }
  }

  // Update log entry title
  Future<void> updateLogEntryTitle(String entryId, String newTitle) async {
    if (_userId == null) return;

    try {
      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(entryId)
          .update({'title': newTitle});

      // Update locally in state
      state = state.whenData((entries) {
        return entries.map((entry) {
          if (entry.id == entryId) {
            entry.title = newTitle;
          }
          return entry;
        }).toList();
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error updating entry title: $error');
      }
    }
  }

  // Delete log entry
  Future<void> deleteLogEntry(String entryId, String fileUrl) async {
    if (_userId == null) return;

    try {
      // Delete the file from storage
      final filePathToDelete = await _storageService.getReferencePathFromUrl(
        fileUrl,
      );
      if (filePathToDelete != null) {
        await _storageService.deleteFile(filePathToDelete);
      }

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(entryId)
          .delete();

      // Remove from local state
      state = state.whenData((entries) {
        return entries.where((entry) => entry.id != entryId).toList();
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error deleting entry: $error');
      }
    }
  }

  // Toggle audio playing state
  void toggleAudioPlaying(String audioEntryId, bool isPlaying) {
    state = state.whenData((entries) {
      return entries.map((entry) {
        if (entry is AudioLogEntry && entry.id == audioEntryId) {
          return AudioLogEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            title: entry.title,
            audioUrl: entry.audioUrl,
            transcription: entry.transcription,
            duration: entry.duration,
            isPlaying: isPlaying,
            tags: entry.tags, // Preserve existing tags
          );
        }
        return entry;
      }).toList();
    });
  }

  // Update audio log entry
  Future<void> updateAudioEntry(AudioLogEntry updatedEntry) async {
    if (_userId == null) return;

    try {
      // Get the current state
      final entries = state.value ?? [];

      // Find the entry to update
      final index = entries.indexWhere((entry) => entry.id == updatedEntry.id);
      if (index == -1) return;

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(updatedEntry.id)
          .update(updatedEntry.toJson());

      // Update local state
      final updatedEntries = [...entries];
      updatedEntries[index] = updatedEntry;
      state = AsyncData(updatedEntries);
    } catch (error) {
      if (kDebugMode) {
        print('Error updating audio entry: $error');
      }
    }
  }

  // Helper method to generate a title from transcription
  String _generateTitleFromTranscription(String transcription) {
    // Get the first 5-7 words from the transcription
    final words = transcription.split(' ');
    final titleWords = words
        .take(words.length < 7 ? words.length : 7)
        .join(' ');

    // If title is too short, use a generic title with timestamp
    if (titleWords.length < 10) {
      return 'Audio Journal ${DateTime.now().toString().substring(0, 16)}';
    }

    // Add ellipsis if we truncated the transcription
    return words.length > 7 ? '$titleWords...' : titleWords;
  }

  // Debug method to log the current state
  void debugLogState() {
    if (kDebugMode) {
      if (state.hasValue) {
        developer.log('Current log entries: ${state.value?.length ?? 0}');
        for (final entry in state.value ?? []) {
          developer.log(
            'Entry: ${entry.id} - ${entry.title} - ${entry.timestamp}',
          );
        }
      } else if (state.isLoading) {
        developer.log('Log entries state: LOADING');
      } else if (state.hasError) {
        developer.log('Log entries state: ERROR - ${state.error}');
      }
    }
  }

  // Get all log entries for a specific month
  // This is useful for efficient calendar data loading
  Future<void> fetchAllEntries() async {
    if (_userId == null) {
      state = const AsyncValue.error(
        'User not authenticated',
        StackTrace.empty,
      );
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Query all entries, limited to avoid excessive data transfer
      // You may want to adjust this limit or add pagination for production
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('logs')
              .orderBy('timestamp', descending: true)
              .limit(500) // Safety limit
              .get();

      final logEntries =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return LogEntry.fromJson(data);
          }).toList();

      state = AsyncValue.data(logEntries);

      if (kDebugMode) {
        developer.log('Fetched ${logEntries.length} total entries');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log('Error fetching all entries: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
