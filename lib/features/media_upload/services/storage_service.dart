// Simplified storage_service.dart
import 'dart:io';
import 'package:echo/features/media_upload/provider/media_upload_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Ref? ref;

  // Constructor that can optionally take a Riverpod ref
  StorageService({this.ref});

  // Method to upload XFile to Firebase Storage for profile
  Future<String?> uploadProfile(XFile xFile, String uid) async {
    try {
      // Create a reference to the profile storage location
      final ref = _storage.ref().child('profile/$uid');

      // Convert XFile to File or Uint8List based on platform
      UploadTask uploadTask;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, convert to File
        final file = File(xFile.path);
        uploadTask = ref.putFile(file);
      } else {
        // For web platform, use Uint8List
        final bytes = await xFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/${xFile.name.split('.').last}'),
        );
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get and return the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile: $e');
      return null;
    }
  }

  // Method to delete a file from Firebase Storage using its reference path
  Future<bool> deleteFile(String referencePath) async {
    try {
      // Get a reference to the file
      final ref = _storage.ref().child(referencePath);

      // Delete the file
      await ref.delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Helper method to get the reference path from a download URL
  Future<String?> getReferencePathFromUrl(String downloadUrl) async {
    try {
      // Create a reference from the download URL
      final ref = _storage.refFromURL(downloadUrl);

      // Return the full path
      return ref.fullPath;
    } catch (e) {
      debugPrint('Error getting reference path: $e');
      return null;
    }
  }

  /// Upload a media file with simple loading state
  Future<String?> uploadMedia({
    required File mediaFile,
    required String userId,
    required String username,
    required String mediaType, // 'images', 'videos', or 'audios'
  }) async {
    try {
      // If Riverpod ref is available, update the media upload state
      if (ref != null) {
        final mediaNotifier = ref!.read(mediaUploadProvider.notifier);
        mediaNotifier.startUpload(mediaType);
      }

      // Create timestamp for unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(mediaFile.path);
      final filename = '${username}_$timestamp$extension';

      // Create reference to the storage location
      final storageRef = _storage.ref().child('$userId/$mediaType/$filename');

      // Upload the file
      UploadTask uploadTask;

      if (Platform.isAndroid || Platform.isIOS) {
        uploadTask = storageRef.putFile(mediaFile);
      } else {
        // For web platform
        final bytes = await mediaFile.readAsBytes();
        String contentType;

        switch (mediaType) {
          case 'images':
            contentType = 'image/${extension.replaceAll('.', '')}';
            break;
          case 'videos':
            contentType = 'video/${extension.replaceAll('.', '')}';
            break;
          case 'audios':
            contentType = 'audio/${extension.replaceAll('.', '')}';
            break;
          default:
            contentType = 'application/octet-stream';
        }

        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // If Riverpod ref is available, complete the upload status
      if (ref != null) {
        ref!.read(mediaUploadProvider.notifier).completeUpload();
      }

      // Get and return the download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // If Riverpod ref is available, update error status
      if (ref != null) {
        ref!
            .read(mediaUploadProvider.notifier)
            .setError('Error uploading media: ${e.toString()}');
      }
      debugPrint('Error uploading media: $e');
      return null;
    }
  }

  /// Convert XFile to File
  Future<File?> xFileToFile(XFile xFile) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return File(xFile.path);
      } else {
        // For web, this is more complex and may require additional handling
        final bytes = await xFile.readAsBytes();
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${path.basename(xFile.path)}');
        await tempFile.writeAsBytes(bytes);
        return tempFile;
      }
    } catch (e) {
      debugPrint('Error converting XFile to File: $e');
      return null;
    }
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref: ref);
});
