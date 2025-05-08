import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple state class for media upload process
class MediaUploadState {
  final bool isLoading;
  final String? errorMessage;
  final String? mediaType; // 'image', 'video', or 'audio'

  const MediaUploadState({
    this.isLoading = false,
    this.errorMessage,
    this.mediaType,
  });

  /// Create a copy of this state with new values
  MediaUploadState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? mediaType,
  }) {
    return MediaUploadState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  /// Initial state with no loading
  static const initial = MediaUploadState();

  /// Check if there was an error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

/// Media Upload Notifier
class MediaUploadNotifier extends StateNotifier<MediaUploadState> {
  MediaUploadNotifier() : super(MediaUploadState.initial);

  /// Start the upload process
  void startUpload(String mediaType) {
    state = state.copyWith(
      isLoading: true,
      mediaType: mediaType,
      errorMessage: null,
    );
  }

  /// Set error state
  void setError(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
  }

  /// Complete the upload process
  void completeUpload() {
    state = MediaUploadState.initial;
  }
}

/// Single provider for all media uploads
final mediaUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, MediaUploadState>((ref) {
      return MediaUploadNotifier();
    });
